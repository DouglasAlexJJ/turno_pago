// lib/services/dados_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/despesa.dart';
import '../models/turno.dart'; // Importa o nosso novo modelo

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
}