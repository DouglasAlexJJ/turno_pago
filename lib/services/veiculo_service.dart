// lib/services/veiculo_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/veiculo.dart';

class VeiculoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Caminho para a configuração do veículo do usuário logado
  DocumentReference _getVeiculoDocRef() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuário não está logado.");
    return _firestore.collection('users').doc(user.uid).collection('veiculo').doc('config');
  }

  // Salva os dados do veículo na nuvem
  Future<void> salvarVeiculo(Veiculo veiculo) async {
    await _getVeiculoDocRef().set(veiculo.toMap());
  }

  // Pega os dados do veículo da nuvem
  Future<Veiculo> getVeiculo() async {
    final docSnapshot = await _getVeiculoDocRef().get();

    if (docSnapshot.exists) {
      // Se já existem dados salvos, usa eles
      return Veiculo.fromMap(docSnapshot.data() as Map<String, dynamic>);
    } else {
      // Se não, retorna um veículo com valores padrão
      return Veiculo();
    }
  }
}