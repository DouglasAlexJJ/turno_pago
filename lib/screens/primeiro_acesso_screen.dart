// lib/screens/primeiro_acesso_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'main_screen.dart'; // Para navegar para a tela principal depois

class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para os campos
  final _consumoController = TextEditingController();
  final _valorVeiculoController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _vidaUtilController = TextEditingController();
  final _kmAtualController = TextEditingController();

  Future<void> _salvarEContinuar() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // Salva os dados de configuração
      await prefs.setDouble('veiculo_consumo_medio', double.tryParse(_consumoController.text) ?? 0.0);
      await prefs.setDouble('carro_valor', _valorVeiculoController.numberValue);
      await prefs.setInt('carro_vida_util_km', int.tryParse(_vidaUtilController.text) ?? 0);
      await prefs.setInt('veiculo_km_atual', int.tryParse(_kmAtualController.text) ?? 0);

      // Marca que o primeiro acesso foi concluído
      await prefs.setBool('primeiro_acesso_concluido', true);

      if (!mounted) return;

      // Navega para a tela principal, substituindo a tela de setup
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

                // Campo de KM Atual
                TextFormField(
                  controller: _kmAtualController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quilometragem ATUAL do veículo (km)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),

                // Campo de Consumo
                TextFormField(
                  controller: _consumoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Consumo médio do veículo (km/l)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),

                // Campo de Valor do Veículo
                TextFormField(
                  controller: _valorVeiculoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor estimado do próximo veículo (R\$)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),

                // Campo de Vida Útil
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