// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:turno_pago/firebase_options.dart';
import 'package:turno_pago/screens/auth/auth_gate.dart'; // Importe o AuthGate
import 'package:turno_pago/services/background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeService();

  // A lógica de primeiro acesso foi removida daqui temporariamente
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turno Pago',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // A TELA INICIAL AGORA É O NOSSO PORTÃO DE AUTENTICAÇÃO
      home: const AuthGate(),
    );
  }
}