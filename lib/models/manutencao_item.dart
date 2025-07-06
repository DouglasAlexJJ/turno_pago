// lib/models/manutencao_item.dart

import 'dart:convert';

class ManutencaoItem {
  final String id;
  final String nome;
  final double custo;
  final int vidaUtilKm;
  final int kmUltimaTroca;
  final DateTime? dataUltimaTroca;

  ManutencaoItem({
    required this.id,
    required this.nome,
    required this.custo,
    required this.vidaUtilKm,
    this.kmUltimaTroca = 0,
    this.dataUltimaTroca,
  });

  double get custoPorKm => vidaUtilKm > 0 ? custo / vidaUtilKm : 0;

  int get proximaTrocaKm => kmUltimaTroca + vidaUtilKm;

  ManutencaoItem copyWith({
    int? kmUltimaTroca,
    DateTime? dataUltimaTroca,
  }) {
    return ManutencaoItem(
      id: id,
      nome: nome,
      custo: custo,
      vidaUtilKm: vidaUtilKm,
      kmUltimaTroca: kmUltimaTroca ?? this.kmUltimaTroca,
      dataUltimaTroca: dataUltimaTroca ?? this.dataUltimaTroca,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'custo': custo,
      'vidaUtilKm': vidaUtilKm,
      'kmUltimaTroca': kmUltimaTroca,
      'dataUltimaTroca': dataUltimaTroca?.toIso8601String(),
    };
  }

  factory ManutencaoItem.fromMap(Map<String, dynamic> map) {
    return ManutencaoItem(
      id: map['id'],
      nome: map['nome'],
      custo: map['custo'],
      vidaUtilKm: map['vidaUtilKm'],
      kmUltimaTroca: map['kmUltimaTroca'] ?? 0,
      dataUltimaTroca: map['dataUltimaTroca'] != null
          ? DateTime.parse(map['dataUltimaTroca'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ManutencaoItem.fromJson(String source) =>
      ManutencaoItem.fromMap(json.decode(source));
}