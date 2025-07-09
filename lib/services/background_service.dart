// lib/services/background_service.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const notificationChannelId = 'turno_pago_channel';
const notificationId = 888;
const notificationTitle = 'Turno Pago';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  double totalDistance = 0.0;
  Position? lastPosition;
  StreamSubscription<Position>? positionStream;

  service.on('stopService').listen((event) {
    positionStream?.cancel();
    service.stopSelf();
  });

  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('turno_start_time', DateTime.now().millisecondsSinceEpoch);

  // CONFIGURAÇÕES DE PRECISÃO AJUSTADAS
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation, // Máxima precisão
    distanceFilter: 5, // Atualiza a cada 5 metros
  );

  positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) {
    if (position != null) {
      if (lastPosition != null) {
        totalDistance += Geolocator.distanceBetween(
          lastPosition!.latitude,
          lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }
      lastPosition = position;
    }
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final startTimeMillis = prefs.getInt('turno_start_time');
    if (startTimeMillis == null) return;

    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    final duration = DateTime.now().difference(startTime);

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final tempoFormatado = "$hours:$minutes:$seconds";

    final distanciaKm = totalDistance / 1000;

    // ATUALIZAÇÃO DA NOTIFICAÇÃO CORRIGIDA
    flutterLocalNotificationsPlugin.show(
      notificationId,
      'Turno Ativo: $tempoFormatado', // Título dinâmico para forçar atualização
      'Distância Percorrida: ${distanciaKm.toStringAsFixed(2)} km',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationTitle,
          importance: Importance.low,
          icon: 'ic_turno_ativo',
          ongoing: true,
          showProgress: false,
          priority: Priority.low,
          onlyAlertOnce: true, // Evita que a notificação vibre a cada segundo
        ),
      ),
    );

    service.invoke('update', {
      'tempo': tempoFormatado,
      'distancia': distanciaKm,
    });
  });
}

// O resto do arquivo (initializeService) continua igual
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    notificationTitle,
    description: 'Notificação para o turno em andamento.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: notificationTitle,
      initialNotificationContent: 'Inicializando...',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}