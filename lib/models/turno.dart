// lib/models/turno.dart

import 'dart:convert';

class Turno {
  final String id;
  final DateTime data;
  final double ganhos;
  final double kmRodados;
  final int corridas;
  final double precoCombustivel;

  Turno({
    required this.id,
    required this.data,
    required this.ganhos,
    required this.kmRodados,
    required this.precoCombustivel,
    required this.corridas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'ganhos': ganhos,
      'kmRodados': kmRodados,
      'corridas': corridas,
      'precoCombustivel': precoCombustivel,
    };
  }

  // MÉTODO ATUALIZADO PARA SER MAIS SEGURO
  factory Turno.fromMap(Map<String, dynamic> map) {
    return Turno(
      id: map['id'] ?? '',
      data: map['data'] != null ? DateTime.parse(map['data']) : DateTime.now(),
      ganhos: map['ganhos']?.toDouble() ?? 0.0,
      kmRodados: map['kmRodados']?.toDouble() ?? 0.0,
      corridas: map['corridas']?.toInt() ?? 0,
      precoCombustivel: map['precoCombustivel']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Turno.fromJson(String source) => Turno.fromMap(json.decode(source));
}