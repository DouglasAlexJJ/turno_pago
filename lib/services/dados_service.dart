// lib/services/dados_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/despesa.dart';
import '../models/manutencao_item.dart';
import '../models/turno.dart';

class DadosService {
  static const String _turnosKey = 'turnos_salvos';
  static const String _despesasKey = 'despesas_salvas';
  static const String _manutencaoKey = 'manutencao_itens_salvos';

  // --- MÉTODOS DE TURNO ---
  static Future<void> adicionarTurno(Turno turno) async {
    final turnos = await getTurnos();
    turnos.add(turno);
    await _salvarListaTurnos(turnos);
  }

  static Future<void> atualizarTurno(Turno turnoAtualizado) async {
    final turnos = await getTurnos();
    final index = turnos.indexWhere((t) => t.id == turnoAtualizado.id);
    if (index != -1) {
      turnos[index] = turnoAtualizado;
      await _salvarListaTurnos(turnos);
    }
  }

  static Future<void> removerTurno(String id) async {
    final turnos = await getTurnos();
    turnos.removeWhere((t) => t.id == id);
    await _salvarListaTurnos(turnos);
  }

  static Future<List<Turno>> getTurnos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_turnosKey) ?? '[]';
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Turno.fromMap(json)).toList();
  }

  static Future<void> _salvarListaTurnos(List<Turno> turnos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = turnos.map((t) => t.toMap()).toList();
    await prefs.setString(_turnosKey, jsonEncode(jsonList));
  }

  // --- MÉTODOS DE DESPESA ---
  static Future<void> adicionarDespesa(Despesa despesa) async {
    final despesas = await getDespesas();
    despesas.add(despesa);
    await _salvarListaDespesas(despesas);
  }

  static Future<void> atualizarDespesa(Despesa despesaAtualizada) async {
    final despesas = await getDespesas();
    final index = despesas.indexWhere((d) => d.id == despesaAtualizada.id);
    if (index != -1) {
      despesas[index] = despesaAtualizada;
      await _salvarListaDespesas(despesas);
    }
  }

  static Future<void> removerDespesa(String id) async {
    final despesas = await getDespesas();
    despesas.removeWhere((d) => d.id == id);
    await _salvarListaDespesas(despesas);
  }

  static Future<List<Despesa>> getDespesas() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_despesasKey) ?? '[]';
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Despesa.fromMap(json)).toList();
  }

  static Future<void> _salvarListaDespesas(List<Despesa> despesas) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = despesas.map((d) => d.toMap()).toList();
    await prefs.setString(_despesasKey, jsonEncode(jsonList));
  }

  // --- MÉTODOS DE MANUTENÇÃO ---
  static Future<void> salvarManutencaoItem(ManutencaoItem item) async {
    final itens = await getManutencaoItens();
    final index = itens.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      itens[index] = item;
    } else {
      itens.add(item);
    }
    await _salvarListaManutencao(itens);
  }

  static Future<void> removerManutencaoItem(String id) async {
    final itens = await getManutencaoItens();
    itens.removeWhere((i) => i.id == id);
    await _salvarListaManutencao(itens);
  }

  // LÓGICA DA LISTA PADRÃO ADICIONADA DE VOLTA
  static Future<List<ManutencaoItem>> getManutencaoItens() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itensJson = prefs.getString(_manutencaoKey);

    List<ManutencaoItem> itens = [];

    if (itensJson != null && itensJson.isNotEmpty) {
      final List<dynamic> itensMap = json.decode(itensJson);
      itens = itensMap.map((map) => ManutencaoItem.fromMap(map)).toList();
    }

    // Se a lista estiver vazia (primeiro acesso a esta funcionalidade),
    // criamos e salvamos uma lista padrão.
    if (itens.isEmpty) {
      itens = [
        ManutencaoItem(id: 'pneu', nome: 'Pneus', custo: 1600, vidaUtilKm: 40000),
        ManutencaoItem(id: 'oleo', nome: 'Troca de Óleo e Filtro', custo: 250, vidaUtilKm: 8000),
        ManutencaoItem(id: 'pastilha', nome: 'Pastilhas de Freio', custo: 300, vidaUtilKm: 30000),
        ManutencaoItem(id: 'correia', nome: 'Correia Dentada e Tensor', custo: 600, vidaUtilKm: 50000),
      ];
      // Salva a lista padrão para que ela seja carregada nas próximas vezes
      await _salvarListaManutencao(itens);
    }

    return itens;
  }

  static Future<void> _salvarListaManutencao(List<ManutencaoItem> itens) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = itens.map((i) => i.toMap()).toList();
    await prefs.setString(_manutencaoKey, jsonEncode(jsonList));
  }
}