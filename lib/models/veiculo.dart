// lib/models/veiculo.dart

class Veiculo {
  final double consumoMedio;
  final int kmAtual;
  final double valorProximoVeiculo;
  final int proximaTrocaKm;

  Veiculo({
    this.consumoMedio = 10.0, // Valor padrão
    this.kmAtual = 0,
    this.valorProximoVeiculo = 0,
    this.proximaTrocaKm = 0,
  });

  // Calcula o custo de depreciação por KM
  double get depreciacaoPorKm {
    if (proximaTrocaKm > 0 && valorProximoVeiculo > 0) {
      return valorProximoVeiculo / proximaTrocaKm;
    }
    return 0;
  }

  // Converte o objeto para um Map para salvar em SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'consumoMedio': consumoMedio,
      'kmAtual': kmAtual,
      'valorProximoVeiculo': valorProximoVeiculo,
      'proximaTrocaKm': proximaTrocaKm,
    };
  }

  // Cria um objeto Veiculo a partir de um Map
  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      consumoMedio: map['consumoMedio'] ?? 10.0,
      kmAtual: map['kmAtual'] ?? 0,
      valorProximoVeiculo: map['valorProximoVeiculo'] ?? 0.0,
      proximaTrocaKm: map['proximaTrocaKm'] ?? 0,
    );
  }
}