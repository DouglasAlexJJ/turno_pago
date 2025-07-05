// lib/main.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/screens/main_screen.dart'; // Importa a nossa nova tela principal

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turno Pago',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Exemplo de um tema um pouco mais moderno
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Remove o banner de "Debug"
      home: const MainScreen(), // O app agora começa aqui!
    );
  }
}