// lib/models/manutencao_item.dart

import 'dart:convert';

class ManutencaoItem {
  final String id;
  final String nome;
  final double custo;
  final int vidaUtilKm;

  ManutencaoItem({
    required this.id,
    required this.nome,
    required this.custo,
    required this.vidaUtilKm,
  });

  // Custo por KM deste item específico
  double get custoPorKm => vidaUtilKm > 0 ? custo / vidaUtilKm : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'custo': custo,
      'vidaUtilKm': vidaUtilKm,
    };
  }

  factory ManutencaoItem.fromMap(Map<String, dynamic> map) {
    return ManutencaoItem(
      id: map['id'],
      nome: map['nome'],
      custo: map['custo'],
      vidaUtilKm: map['vidaUtilKm'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ManutencaoItem.fromJson(String source) =>
      ManutencaoItem.fromMap(json.decode(source));
}