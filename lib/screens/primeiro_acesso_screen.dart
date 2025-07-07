// lib/screens/primeiro_acesso_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/services/veiculo_service.dart'; // Importa o novo serviço
import 'main_screen.dart';

class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _consumoController = TextEditingController();
  final _valorVeiculoController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _vidaUtilController = TextEditingController();
  final _kmAtualController = TextEditingController();

  Future<void> _salvarEContinuar() async {
    if (_formKey.currentState!.validate()) {
      // Cria um objeto Veiculo com os dados da tela
      final veiculo = Veiculo(
        consumoMedio: double.tryParse(_consumoController.text) ?? 0.0,
        valorProximoVeiculo: _valorVeiculoController.numberValue,
        proximaTrocaKm: int.tryParse(_vidaUtilController.text) ?? 0,
        kmAtual: int.tryParse(_kmAtualController.text) ?? 0,
      );

      // Usa o VeiculoService para salvar os dados
      await VeiculoService.salvarVeiculo(veiculo);

      // Marca que o primeiro acesso foi concluído
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('primeiro_acesso_concluido', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Icon(Icons.directions_car, size: 60, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  'Bem-vindo ao Turno Pago!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vamos começar configurando os dados do seu veículo para cálculos mais precisos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _kmAtualController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quilometragem ATUAL do veículo (km)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consumoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Consumo médio do veículo (km/l)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorVeiculoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor estimado do próximo veículo (R\$)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vidaUtilController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Próxima troca de veículo em (KM)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _salvarEContinuar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Salvar e Começar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}