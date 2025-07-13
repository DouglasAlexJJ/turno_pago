// lib/models/turno.dart

class Turno {
  final String id;
  final DateTime data;
  final double ganhos;
  final double kmRodados;
  final int corridas;
  final double precoCombustivel;
  final int duracaoEmSegundos; // NOVO CAMPO

  Turno({
    required this.id,
    required this.data,
    this.ganhos = 0,
    this.kmRodados = 0,
    this.corridas = 0,
    this.precoCombustivel = 0,
    this.duracaoEmSegundos = 0, // Valor padrão
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'ganhos': ganhos,
      'kmRodados': kmRodados,
      'corridas': corridas,
      'precoCombustivel': precoCombustivel,
      'duracaoEmSegundos': duracaoEmSegundos, // Salva no banco
    };
  }

  factory Turno.fromMap(Map<String, dynamic> map) {
    return Turno(
      id: map['id'],
      data: DateTime.parse(map['data']),
      ganhos: map['ganhos']?.toDouble() ?? 0.0,
      kmRodados: map['kmRodados']?.toDouble() ?? 0.0,
      corridas: map['corridas']?.toInt() ?? 0,
      precoCombustivel: map['precoCombustivel']?.toDouble() ?? 0.0,
      duracaoEmSegundos: map['duracaoEmSegundos']?.toInt() ?? 0, // Carrega do banco
    );
  }
}