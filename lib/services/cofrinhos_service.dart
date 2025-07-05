import 'package:shared_preferences/shared_preferences.dart';

class CofrinhoService {
  Future<Map<String, double>> calcularRecomendacoes() async {
    final prefs = await SharedPreferences.getInstance();

    final ganhos = prefs.getDouble('ganhos_dia') ?? 0.0;
    final combustivel = prefs.getDouble('combustivel_dia') ?? 0.0;

    // Mock de médias mensais (em produção virá de dados históricos)
    final double mediaManutencao = 180.0; // ex: mês passado
    final double mediaAlimentacao = 120.0;
    final double mediaTrocaCarro = 300.0;

    final diasAtivos = 30; // ajustar dinamicamente depois

    double manutencaoDia = mediaManutencao / diasAtivos;
    double alimentacaoDia = mediaAlimentacao / diasAtivos;
    double trocaCarroDia = mediaTrocaCarro / diasAtivos;

    double totalCofrinhos = manutencaoDia + alimentacaoDia + trocaCarroDia;
    double lucroReal = ganhos - combustivel - totalCofrinhos;

    return {
      'manutencao': manutencaoDia,
      'alimentacao': alimentacaoDia,
      'trocaCarro': trocaCarroDia,
      'lucroReal': lucroReal,
    };
  }
}
