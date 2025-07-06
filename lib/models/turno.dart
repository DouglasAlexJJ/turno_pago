// lib/models/turno.dart

import 'dart:convert';

class Turno {
  final String id;
  final DateTime data;
  final String plataforma;
  final double ganhos;
  final double kmRodados;
  final int corridas;
  final double precoCombustivel;
  final int kmAtualVeiculo;

  Turno({
    required this.id,
    required this.data,
    required this.plataforma,
    required this.ganhos,
    required this.kmRodados,
    required this.precoCombustivel,
    required this.kmAtualVeiculo,
    this.corridas = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'plataforma': plataforma,
      'ganhos': ganhos,
      'kmRodados': kmRodados,
      'corridas': corridas,
      'precoCombustivel': precoCombustivel,
      'kmAtualVeiculo': kmAtualVeiculo,
    };
  }

  factory Turno.fromMap(Map<String, dynamic> map) {
    return Turno(
      id: map['id'],
      data: DateTime.parse(map['data']),
      plataforma: map['plataforma'],
      ganhos: map['ganhos'],
      kmRodados: map['kmRodados'],
      corridas: map['corridas'] ?? 0,
      precoCombustivel: map['precoCombustivel'] ?? 0.0,
      kmAtualVeiculo: map['kmAtualVeiculo'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Turno.fromJson(String source) => Turno.fromMap(json.decode(source));
}