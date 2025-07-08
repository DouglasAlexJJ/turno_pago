// lib/models/veiculo.dart

class Veiculo {
  final double consumoMedio;
  final int kmAtual;
  final double precoCombustivel;
  final double percentualReserva; // NOVO CAMPO

  Veiculo({
    this.consumoMedio = 10.0,
    this.kmAtual = 0,
    this.precoCombustivel = 0.0,
    this.percentualReserva = 10.0, // NOVO CAMPO (padrão 10%)
  });

  // 'depreciacaoPorKm' foi removido pois não é mais necessário

  Veiculo copyWith({
    double? consumoMedio,
    int? kmAtual,
    double? precoCombustivel,
    double? percentualReserva, // NOVO CAMPO
  }) {
    return Veiculo(
      consumoMedio: consumoMedio ?? this.consumoMedio,
      kmAtual: kmAtual ?? this.kmAtual,
      precoCombustivel: precoCombustivel ?? this.precoCombustivel,
      percentualReserva: percentualReserva ?? this.percentualReserva, // NOVO CAMPO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'consumoMedio': consumoMedio,
      'kmAtual': kmAtual,
      'precoCombustivel': precoCombustivel,
      'percentualReserva': percentualReserva, // NOVO CAMPO
    };
  }

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      consumoMedio: map['consumoMedio'] ?? 10.0,
      kmAtual: map['kmAtual'] ?? 0,
      precoCombustivel: map['precoCombustivel'] ?? 0.0,
      percentualReserva: map['percentualReserva'] ?? 10.0, // NOVO CAMPO
    );
  }
}