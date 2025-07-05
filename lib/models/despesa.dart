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

  // Método para converter um objeto Despesa em um Map (para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(), // Salva a data como string
      'categoria': categoria,
    };
  }

  // Método para criar um objeto Despesa a partir de um Map (de JSON)
  factory Despesa.fromMap(Map<String, dynamic> map) {
    return Despesa(
      id: map['id'],
      descricao: map['descricao'],
      valor: map['valor'],
      data: DateTime.parse(map['data']), // Converte a string de volta para DateTime
      categoria: map['categoria'],
    );
  }

  // Funções de conveniência para JSON
  String toJson() => json.encode(toMap());

  factory Despesa.fromJson(String source) => Despesa.fromMap(json.decode(source));
}