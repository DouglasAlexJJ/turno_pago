// lib/services/background_service.dart

import 'dart:async';
import 'dart:ui';
// import 'package:flutter/material.dart'; // LINHA REMOVIDA
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ... (o resto do arquivo continua igual)
const notificationChannelId = 'turno_pago_channel';
const notificationId = 888;
const notificationTitle = 'Turno Pago';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('turno_start_time', DateTime.now().millisecondsSinceEpoch);

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final startTimeMillis = prefs.getInt('turno_start_time');
    if (startTimeMillis == null) return;

    final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    final duration = DateTime.now().difference(startTime);

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final tempoFormatado = "$hours:$minutes:$seconds";

    flutterLocalNotificationsPlugin.show(
      notificationId,
      notificationTitle,
      'Tempo de trabalho: $tempoFormatado',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          notificationTitle,
          importance: Importance.low,
          icon: 'ic_turno_ativo',
          ongoing: true,
        ),
      ),
    );

    service.invoke('update', {'tempo': tempoFormatado});
  });
}

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