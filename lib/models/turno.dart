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

  Turno({
    required this.id,
    required this.data,
    required this.plataforma,
    required this.ganhos,
    required this.kmRodados,
    required this.precoCombustivel, // Adicione esta linha
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
    );
  }

  String toJson() => json.encode(toMap());

  factory Turno.fromJson(String source) => Turno.fromMap(json.decode(source));
}