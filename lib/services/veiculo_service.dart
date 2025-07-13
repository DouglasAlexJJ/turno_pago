// lib/services/veiculo_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/veiculo.dart';

class VeiculoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference _getVeiculoDocRef() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não está logado.");
    return _firestore.collection('users').doc(user.uid).collection('veiculo').doc('config');
  }

  // Usado para salvar o objeto COMPLETO na configuração
  Future<void> salvarVeiculo(Veiculo veiculo) async {
    await _getVeiculoDocRef().set(veiculo.toMap());
  }

  // MÉTODO SEGURO: Atualiza apenas a quilometragem
  Future<void> atualizarKm(int novaKm) async {
    await _getVeiculoDocRef().update({'kmAtual': novaKm});
  }

  Future<Veiculo> getVeiculo() async {
    try {
      final docSnapshot = await _getVeiculoDocRef().get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Veiculo.fromMap(docSnapshot.data() as Map<String, dynamic>);
      } else {
        return Veiculo();
      }
    } catch (e) {
      return Veiculo();
    }
  }
}