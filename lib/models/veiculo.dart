// lib/models/veiculo.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Adiciona os tipos de veículo e aluguel
enum TipoVeiculo { proprio, alugado }
enum TipoAluguel { porDia, porKm } // Adicionado para o seletor na config

class Veiculo {
  // Campos Gerais
  final double consumoMedio;
  final int kmAtual;
  final double precoCombustivel;
  final double percentualReserva;
  final TipoVeiculo tipoVeiculo;

  // Campos para Veículo Próprio (usados para cálculo de provisão)
  // (nenhum campo extra por enquanto)

  // Campos específicos para Veículo Alugado
  final double? custoTotalAluguel;
  final DateTime? dataInicioAluguel;
  final DateTime? dataFimAluguel;
  final int? kmContratadoAluguel;
  final int? kmInicialAluguel;

  Veiculo({
    this.consumoMedio = 10.0,
    this.kmAtual = 0,
    this.precoCombustivel = 0.0,
    this.percentualReserva = 10.0,
    this.tipoVeiculo = TipoVeiculo.proprio,
    // Dados do Aluguel
    this.custoTotalAluguel,
    this.dataInicioAluguel,
    this.dataFimAluguel,
    this.kmContratadoAluguel,
    this.kmInicialAluguel,
  });

  // Helper para calcular a provisão diária do aluguel
  double get provisaoDiariaAluguel {
    if (tipoVeiculo == TipoVeiculo.alugado &&
        custoTotalAluguel != null &&
        custoTotalAluguel! > 0 &&
        dataInicioAluguel != null &&
        dataFimAluguel != null) {
      if (dataFimAluguel!.isAfter(dataInicioAluguel!)) {
        final totalDias = dataFimAluguel!.difference(dataInicioAluguel!).inDays;
        if (totalDias > 0) {
          return custoTotalAluguel! / totalDias;
        }
      }
    }
    return 0.0;
  }

  Veiculo copyWith({
    double? consumoMedio,
    int? kmAtual,
    double? precoCombustivel,
    double? percentualReserva,
    TipoVeiculo? tipoVeiculo,
    double? custoTotalAluguel,
    DateTime? dataInicioAluguel,
    DateTime? dataFimAluguel,
    int? kmContratadoAluguel,
    int? kmInicialAluguel,
  }) {
    return Veiculo(
      consumoMedio: consumoMedio ?? this.consumoMedio,
      kmAtual: kmAtual ?? this.kmAtual,
      precoCombustivel: precoCombustivel ?? this.precoCombustivel,
      percentualReserva: percentualReserva ?? this.percentualReserva,
      tipoVeiculo: tipoVeiculo ?? this.tipoVeiculo,
      custoTotalAluguel: custoTotalAluguel,
      dataInicioAluguel: dataInicioAluguel,
      dataFimAluguel: dataFimAluguel,
      kmContratadoAluguel: kmContratadoAluguel,
      kmInicialAluguel: kmInicialAluguel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'consumoMedio': consumoMedio,
      'kmAtual': kmAtual,
      'precoCombustivel': precoCombustivel,
      'percentualReserva': percentualReserva,
      'tipoVeiculo': tipoVeiculo.name,
      'custoTotalAluguel': custoTotalAluguel,
      'dataInicioAluguel': dataInicioAluguel != null ? Timestamp.fromDate(dataInicioAluguel!) : null,
      'dataFimAluguel': dataFimAluguel != null ? Timestamp.fromDate(dataFimAluguel!) : null,
      'kmContratadoAluguel': kmContratadoAluguel,
      'kmInicialAluguel': kmInicialAluguel,
    };
  }

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      consumoMedio: map['consumoMedio'] ?? 10.0,
      kmAtual: map['kmAtual'] ?? 0,
      precoCombustivel: map['precoCombustivel'] ?? 0.0,
      percentualReserva: map['percentualReserva'] ?? 10.0,
      tipoVeiculo: TipoVeiculo.values.firstWhere(
            (e) => e.name == map['tipoVeiculo'],
        orElse: () => TipoVeiculo.proprio,
      ),
      custoTotalAluguel: map['custoTotalAluguel']?.toDouble(),
      dataInicioAluguel: (map['dataInicioAluguel'] as Timestamp?)?.toDate(),
      dataFimAluguel: (map['dataFimAluguel'] as Timestamp?)?.toDate(),
      kmContratadoAluguel: map['kmContratadoAluguel'],
      kmInicialAluguel: map['kmInicialAluguel'],
    );
  }
}