// lib/services/veiculo_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/veiculo.dart';

class VeiculoService {
  static const String _consumoKey = 'veiculo_consumo_medio';
  static const String _kmAtualKey = 'veiculo_km_atual';
  static const String _precoCombustivelKey = 'veiculo_preco_combustivel';
  static const String _percentualReservaKey = 'veiculo_percentual_reserva'; // NOVA CHAVE

  static Future<void> salvarVeiculo(Veiculo veiculo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_consumoKey, veiculo.consumoMedio);
    await prefs.setInt(_kmAtualKey, veiculo.kmAtual);
    await prefs.setDouble(_precoCombustivelKey, veiculo.precoCombustivel);
    await prefs.setDouble(_percentualReservaKey, veiculo.percentualReserva); // SALVA O NOVO DADO
  }

  static Future<Veiculo> getVeiculo() async {
    final prefs = await SharedPreferences.getInstance();
    final consumo = prefs.getDouble(_consumoKey) ?? 10.0;
    final kmAtual = prefs.getInt(_kmAtualKey) ?? 0;
    final precoCombustivel = prefs.getDouble(_precoCombustivelKey) ?? 0.0;
    final percentualReserva = prefs.getDouble(_percentualReservaKey) ?? 10.0; // LÊ O NOVO DADO

    return Veiculo(
      consumoMedio: consumo,
      kmAtual: kmAtual,
      precoCombustivel: precoCombustivel,
      percentualReserva: percentualReserva, // PASSA PARA O CONSTRUTOR
    );
  }
}