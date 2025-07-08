// lib/models/veiculo.dart

class Veiculo {
  final double consumoMedio;
  final int kmAtual;
  final double valorProximoVeiculo;
  final int proximaTrocaKm;
  final double precoCombustivel; // NOVO CAMPO

  Veiculo({
    this.consumoMedio = 10.0,
    this.kmAtual = 0,
    this.valorProximoVeiculo = 0,
    this.proximaTrocaKm = 0,
    this.precoCombustivel = 0.0, // NOVO CAMPO
  });

  double get depreciacaoPorKm {
    if (proximaTrocaKm > 0 && valorProximoVeiculo > 0) {
      return valorProximoVeiculo / proximaTrocaKm;
    }
    return 0;
  }

  Veiculo copyWith({
    double? consumoMedio,
    int? kmAtual,
    double? valorProximoVeiculo,
    int? proximaTrocaKm,
    double? precoCombustivel, // NOVO CAMPO
  }) {
    return Veiculo(
      consumoMedio: consumoMedio ?? this.consumoMedio,
      kmAtual: kmAtual ?? this.kmAtual,
      valorProximoVeiculo: valorProximoVeiculo ?? this.valorProximoVeiculo,
      proximaTrocaKm: proximaTrocaKm ?? this.proximaTrocaKm,
      precoCombustivel: precoCombustivel ?? this.precoCombustivel, // NOVO CAMPO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'consumoMedio': consumoMedio,
      'kmAtual': kmAtual,
      'valorProximoVeiculo': valorProximoVeiculo,
      'proximaTrocaKm': proximaTrocaKm,
      'precoCombustivel': precoCombustivel, // NOVO CAMPO
    };
  }

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      consumoMedio: map['consumoMedio'] ?? 10.0,
      kmAtual: map['kmAtual'] ?? 0,
      valorProximoVeiculo: map['valorProximoVeiculo'] ?? 0.0,
      proximaTrocaKm: map['proximaTrocaKm'] ?? 0,
      precoCombustivel: map['precoCombustivel'] ?? 0.0, // NOVO CAMPO
    );
  }
}