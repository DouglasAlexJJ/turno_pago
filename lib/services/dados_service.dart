// lib/services/dados_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/despesa.dart';
import '../models/manutencao_item.dart';
import '../models/turno.dart';

class DadosService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Função helper para pegar o ID do usuário logado
  static String? get _userId => _auth.currentUser?.uid;

  // --- MÉTODOS DE TURNO (AGORA COM FIREBASE) ---

  static Future<void> adicionarTurno(Turno turno) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('turnos')
        .doc(turno.id) // Usamos o ID do turno como ID do documento
        .set(turno.toMap());
  }

  static Future<void> atualizarTurno(Turno turnoAtualizado) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('turnos')
        .doc(turnoAtualizado.id)
        .update(turnoAtualizado.toMap());
  }

  static Future<void> removerTurno(String id) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('turnos')
        .doc(id)
        .delete();
  }

  static Future<List<Turno>> getTurnos() async {
    if (_userId == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('turnos')
        .get();

    return snapshot.docs.map((doc) => Turno.fromMap(doc.data())).toList();
  }

  // --- MÉTODOS DE DESPESA (AGORA COM FIREBASE) ---

  static Future<void> adicionarDespesa(Despesa despesa) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('despesas')
        .doc(despesa.id)
        .set(despesa.toMap());
  }

  static Future<void> atualizarDespesa(Despesa despesaAtualizada) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('despesas')
        .doc(despesaAtualizada.id)
        .update(despesaAtualizada.toMap());
  }

  static Future<void> removerDespesa(String id) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('despesas')
        .doc(id)
        .delete();
  }

  static Future<List<Despesa>> getDespesas() async {
    if (_userId == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('despesas')
        .get();

    return snapshot.docs.map((doc) => Despesa.fromMap(doc.data())).toList();
  }

  // --- MÉTODOS DE MANUTENÇÃO (AGORA COM FIREBASE) ---

  static Future<void> salvarManutencaoItem(ManutencaoItem item) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('manutencaoItens')
        .doc(item.id)
        .set(item.toMap());
  }

  static Future<void> removerManutencaoItem(String id) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('manutencaoItens')
        .doc(id)
        .delete();
  }

  static Future<List<ManutencaoItem>> getManutencaoItens() async {
    if (_userId == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('manutencaoItens')
        .get();

    // Se não houver itens na nuvem, cria os padrões
    if (snapshot.docs.isEmpty) {
      final itensPadrao = [
        ManutencaoItem(id: 'pneu', nome: 'Pneus', custo: 1600, vidaUtilKm: 40000),
        ManutencaoItem(id: 'oleo', nome: 'Troca de Óleo e Filtro', custo: 250, vidaUtilKm: 8000),
        ManutencaoItem(id: 'pastilha', nome: 'Pastilhas de Freio', custo: 300, vidaUtilKm: 30000),
        ManutencaoItem(id: 'correia', nome: 'Correia Dentada e Tensor', custo: 600, vidaUtilKm: 50000),
      ];
      // Salva os itens padrão na nuvem para o usuário
      for (var item in itensPadrao) {
        await salvarManutencaoItem(item);
      }
      return itensPadrao;
    }

    return snapshot.docs.map((doc) => ManutencaoItem.fromMap(doc.data())).toList();
  }
}