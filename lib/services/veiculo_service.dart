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

  // Este método é para salvar o objeto COMPLETO (usado na configuração)
  Future<void> salvarVeiculo(Veiculo veiculo) async {
    await _getVeiculoDocRef().set(veiculo.toMap());
  }

  // NOVA FUNÇÃO: Atualiza apenas a quilometragem, de forma segura.
  Future<void> atualizarKm(int novaKm) async {
    await _getVeiculoDocRef().update({'kmAtual': novaKm});
  }

  Future<Veiculo> getVeiculo() async {
    try {
      final docSnapshot = await _getVeiculoDocRef().get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Veiculo.fromMap(docSnapshot.data() as Map<String, dynamic>);
      } else {
        return Veiculo(); // Retorna um veículo padrão se não houver dados
      }
    } catch (e) {
      // Em caso de erro (ex: usuário recém-criado sem dados), retorna um veículo padrão
      return Veiculo();
    }
  }
}