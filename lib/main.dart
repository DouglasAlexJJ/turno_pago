// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:turno_pago/firebase_options.dart';
import 'package:turno_pago/screens/auth/auth_gate.dart';
import 'package:turno_pago/services/background_service.dart';
import 'package:turno_pago/utils/app_themes.dart'; // Importe o novo arquivo de temas

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turno Pago',
      debugShowCheckedModeBanner: false,

      // NOVAS CONFIGURAÇÕES DE TEMA
      theme: AppThemes.lightTheme,       // Define o tema claro padrão
      darkTheme: AppThemes.darkTheme,    // Define o tema escuro
      themeMode: ThemeMode.system,       // Faz o app seguir o sistema

      home: const AuthGate(),
    );
  }
}