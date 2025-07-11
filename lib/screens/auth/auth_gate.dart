// lib/screens/auth/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:turno_pago/screens/auth/login_screen.dart'; // Tela que criaremos a seguir
import 'package:turno_pago/screens/main_screen.dart';
import 'package:turno_pago/services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Ouve o stream do nosso AuthService
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // Se estiver esperando, mostra um carregando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Se tiver um usuário logado (snapshot.hasData), mostra a tela principal
          if (snapshot.hasData) {
            return const MainScreen();
          }

          // Se não tiver usuário, mostra a tela de login
          return const LoginScreen();
        },
      ),
    );
  }
}