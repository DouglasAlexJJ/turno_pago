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

  // Variáveis para o cálculo de distância
  double totalDistance = 0.0;
  Position? lastPosition;
  StreamSubscription<Position>? positionStream;

  // Escuta por eventos da UI
  service.on('stopService').listen((event) {
    positionStream?.cancel(); // Para o stream de GPS
    service.stopSelf();
  });

  // Salva a hora de início
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('turno_start_time', DateTime.now().millisecondsSinceEpoch);

  // Configurações do Stream de Localização
  const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Atualiza a cada 10 metros
  );

  // Inicia o Stream de GPS
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

  // Timer principal que atualiza a notificação e a UI
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final startTimeMillis = prefs.getInt('turno_start_time');
    if (startTimeMillis == null) return;

    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    final duration = DateTime.now().difference(startTime);

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final tempoFormatado = "$hours:$minutes:$seconds";

    final distanciaKm = totalDistance / 1000; // Converte para KM

    // Mostra a notificação com tempo e distância
    flutterLocalNotificationsPlugin.show(
      notificationId,
      'Tempo: $tempoFormatado', // Título agora mostra o tempo
      'Distância: ${distanciaKm.toStringAsFixed(2)} km', // Corpo mostra a distância
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationTitle,
          importance: Importance.low,
          icon: 'ic_turno_ativo',
          ongoing: true,
          showProgress: false,
          priority: Priority.low,
        ),
      ),
    );

    // Envia os dados de volta para a UI
    service.invoke('update', {
      'tempo': tempoFormatado,
      'distancia': distanciaKm,
    });
  });
}

// ... (O resto do arquivo 'initializeService' continua igual)
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