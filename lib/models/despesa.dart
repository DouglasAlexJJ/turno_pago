// lib/models/despesa.dart

import 'dart:convert';

class Despesa {
  final String id;
  final String descricao;
  final double valor;
  final DateTime data;
  final String categoria;

  Despesa({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.categoria,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
      'categoria': categoria,
    };
  }

  // MÉTODO ATUALIZADO PARA SER MAIS SEGURO
  factory Despesa.fromMap(Map<String, dynamic> map) {
    return Despesa(
      id: map['id'] ?? '',
      descricao: map['descricao'] ?? '',
      valor: map['valor']?.toDouble() ?? 0.0,
      data: map['data'] != null ? DateTime.parse(map['data']) : DateTime.now(),
      categoria: map['categoria'] ?? 'Outros',
    );
  }

  String toJson() => json.encode(toMap());

  factory Despesa.fromJson(String source) => Despesa.fromMap(json.decode(source));
}