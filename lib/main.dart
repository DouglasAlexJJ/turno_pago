// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turno_pago/screens/main_screen.dart';
import 'package:turno_pago/screens/primeiro_acesso_screen.dart';
import 'package:turno_pago/services/background_service.dart';

Future<void> main() async {
  // Garante que os bindings do Flutter foram inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o serviço de background
  await initializeService();

  // Verifica se é o primeiro acesso usando a flag
  final prefs = await SharedPreferences.getInstance();
  final bool primeiroAcessoConcluido = prefs.getBool('primeiro_acesso_concluido') ?? false;

  runApp(MyApp(primeiroAcessoConcluido: primeiroAcessoConcluido));
}

class MyApp extends StatelessWidget {
  final bool primeiroAcessoConcluido;

  const MyApp({super.key, required this.primeiroAcessoConcluido});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turno Pago',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Decide qual será a tela inicial com base na flag
      home: primeiroAcessoConcluido ? const MainScreen() : const PrimeiroAcessoScreen(),
    );
  }
}