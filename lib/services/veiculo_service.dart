// lib/services/veiculo_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/veiculo.dart'; // Importa o modelo

class VeiculoService {
  // Chaves para salvar os dados no SharedPreferences
  static const String _consumoKey = 'veiculo_consumo_medio';
  static const String _kmAtualKey = 'veiculo_km_atual';
  static const String _valorVeiculoKey = 'carro_valor';
  static const String _vidaUtilKey = 'carro_vida_util_km';

  // Salva o objeto Veiculo completo
  static Future<void> salvarVeiculo(Veiculo veiculo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_consumoKey, veiculo.consumoMedio);
    await prefs.setInt(_kmAtualKey, veiculo.kmAtual);
    await prefs.setDouble(_valorVeiculoKey, veiculo.valorProximoVeiculo);
    await prefs.setInt(_vidaUtilKey, veiculo.proximaTrocaKm);
  }

  // Carrega o objeto Veiculo
  static Future<Veiculo> getVeiculo() async {
    final prefs = await SharedPreferences.getInstance();
    final consumo = prefs.getDouble(_consumoKey) ?? 10.0;
    final kmAtual = prefs.getInt(_kmAtualKey) ?? 0;
    final valor = prefs.getDouble(_valorVeiculoKey) ?? 0.0;
    final vidaUtil = prefs.getInt(_vidaUtilKey) ?? 0;

    return Veiculo(
      consumoMedio: consumo,
      kmAtual: kmAtual,
      valorProximoVeiculo: valor,
      proximaTrocaKm: vidaUtil,
    );
  }
}