// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // GETTER PARA SABER O USUÁRIO ATUAL
  User? get currentUser => _firebaseAuth.currentUser;

  // STREAM PARA OUVIR AS MUDANÇAS DE ESTADO DE AUTENTICAÇÃO (MÁGICA ACONTECE AQUI)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // MÉTODO DE LOGIN
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Aqui podemos tratar erros específicos de login no futuro
      print(e.message);
      return null;
    }
  }

  // MÉTODO DE CADASTRO
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Tratar erros de cadastro
      print(e.message);
      return null;
    }
  }

  // MÉTODO DE LOGOUT
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}