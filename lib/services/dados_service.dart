// lib/services/dados_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/despesa.dart';
import '../models/turno.dart'; // Importa o nosso novo modelo
import '../models/manutencao_item.dart';

class DadosService {
  // Chaves para as listas
  static const String _despesasKey = 'lista_despesas';
  static const String _turnosKey = 'lista_turnos'; // NOVA CHAVE

  // --- MÉTODOS ANTIGOS (SERÃO REMOVIDOS NO FUTURO) ---
  static Future<void> salvarString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String> lerString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? '';
  }

  static Future<void> salvarDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  static Future<double> lerDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key) ?? 0.0;
  }

  static Future<void> salvarInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  static Future<int> lerInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }
  // --- FIM DOS MÉTODOS ANTIGOS ---

  // --- MÉTODOS DE GERENCIAMENTO DE DESPESAS ---
  static Future<List<Despesa>> getDespesas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? despesasJson = prefs.getString(_despesasKey);
    if (despesasJson != null) {
      final List<dynamic> despesasMap = json.decode(despesasJson);
      return despesasMap.map((map) => Despesa.fromMap(map)).toList();
    }
    return [];
  }

  static Future<void> _salvarListaDespesas(List<Despesa> despesas) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> despesasMap = despesas.map((d) => d.toMap()).toList();
    await prefs.setString(_despesasKey, json.encode(despesasMap));
  }

  static Future<void> adicionarDespesa(Despesa novaDespesa) async {
    final List<Despesa> despesas = await getDespesas();
    despesas.add(novaDespesa);
    await _salvarListaDespesas(despesas);
  }

  static Future<void> removerDespesa(String id) async {
    final List<Despesa> despesas = await getDespesas();
    despesas.removeWhere((d) => d.id == id);
    await _salvarListaDespesas(despesas);
  }

  // --- NOVOS MÉTODOS PARA GERENCIAR TURNOS ---

  // Salva a lista inteira de turnos
  static Future<void> _salvarListaTurnos(List<Turno> turnos) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> turnosMap = turnos.map((t) => t.toMap()).toList();
    await prefs.setString(_turnosKey, json.encode(turnosMap));
  }

  // Carrega a lista de turnos
  static Future<List<Turno>> getTurnos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? turnosJson = prefs.getString(_turnosKey);
    if (turnosJson != null) {
      final List<dynamic> turnosMap = json.decode(turnosJson);
      return turnosMap.map((map) => Turno.fromMap(map)).toList();
    }
    return [];
  }

  // Adiciona um novo turno à lista
  static Future<void> adicionarTurno(Turno novoTurno) async {
    final List<Turno> turnos = await getTurnos();
    turnos.add(novoTurno);
    await _salvarListaTurnos(turnos);
  }
  static const String _manutencaoKey = 'lista_manutencao';

// Salva a lista inteira de itens de manutenção
  static Future<void> _salvarListaManutencao(List<ManutencaoItem> itens) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> itensMap = itens.map((i) => i.toMap()).toList();
    await prefs.setString(_manutencaoKey, json.encode(itensMap));
  }

// Carrega a lista de itens de manutenção
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
        ManutencaoItem(id: 'arrefecimento', nome: 'Líquido de Arrefecimento', custo: 150, vidaUtilKm: 60000),
        ManutencaoItem(id: 'velas', nome: 'Velas de Ignição', custo: 200, vidaUtilKm: 40000),
      ];
      // Salva a lista padrão para que ela seja carregada nas próximas vezes
      await _salvarListaManutencao(itens);
    }

    return itens;
  }

// Adiciona ou atualiza um item na lista
  static Future<void> salvarManutencaoItem(ManutencaoItem item) async {
    final List<ManutencaoItem> itens = await getManutencaoItens();
    // Verifica se o item já existe para atualizá-lo
    final index = itens.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      itens[index] = item; // Atualiza
    } else {
      itens.add(item); // Adiciona
    }
    await _salvarListaManutencao(itens);
  }

// Remove um item da lista
  static Future<void> removerManutencaoItem(String id) async {
    final List<ManutencaoItem> itens = await getManutencaoItens();
    itens.removeWhere((i) => i.id == id);
    await _salvarListaManutencao(itens);
  }
  static Future<void> atualizarTurno(Turno turnoAtualizado) async {
    final List<Turno> turnos = await getTurnos();
    // Encontra o índice do turno com o mesmo ID
    final index = turnos.indexWhere((t) => t.id == turnoAtualizado.id);
    if (index != -1) {
      turnos[index] = turnoAtualizado; // Substitui o turno antigo pelo novo
      await _salvarListaTurnos(turnos);
    }
  }

// Remove um turno da lista pelo seu ID
  static Future<void> removerTurno(String id) async {
    final List<Turno> turnos = await getTurnos();
    turnos.removeWhere((t) => t.id == id); // Remove o turno da lista
    await _salvarListaTurnos(turnos);
  }
}