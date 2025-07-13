// lib/screens/primeiro_acesso_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/services/veiculo_service.dart';

import 'manutencao_screen.dart';

class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consumoController = TextEditingController();
  final _kmAtualController = TextEditingController();
  final _percentualReservaController = TextEditingController(text: '10');

  // Nós de Foco
  final _consumoFocus = FocusNode();
  final _kmAtualFocus = FocusNode();
  final _percentualReservaFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _adicionarListenersDeFoco();
  }

  @override
  void dispose() {
    // Limpa os nós de foco
    _consumoFocus.dispose();
    _kmAtualFocus.dispose();
    _percentualReservaFocus.dispose();
    super.dispose();
  }

  void _adicionarListenersDeFoco() {
    void addSelectAllOnFocus(FocusNode focusNode, TextEditingController controller) {
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
        }
      });
    }

    addSelectAllOnFocus(_consumoFocus, _consumoController);
    addSelectAllOnFocus(_kmAtualFocus, _kmAtualController);
    addSelectAllOnFocus(_percentualReservaFocus, _percentualReservaController);
  }

  Future<void> _salvarEContinuar() async {
    if (_formKey.currentState!.validate()) {
      final veiculo = Veiculo(
        consumoMedio: double.tryParse(_consumoController.text) ?? 10.0,
        kmAtual: int.tryParse(_kmAtualController.text) ?? 0,
        percentualReserva: double.tryParse(_percentualReservaController.text) ?? 10.0,
      );

      // Salva os dados na nuvem
      await VeiculoService().salvarVeiculo(veiculo);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ManutencaoScreen(isFirstTimeSetup: true),
        ),
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
                Image.asset('assets/images/logo_app.png', height: 80),
                const SizedBox(height: 16),
                Text(
                  'Configuração Inicial',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Passo 1 de 2: Configure os dados do seu veículo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _kmAtualController,
                  focusNode: _kmAtualFocus,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quilometragem ATUAL do veículo (km)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consumoController,
                  focusNode: _kmAtualFocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Consumo médio do veículo (km/l)'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _percentualReservaController,
                  focusNode: _kmAtualFocus,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Lucro diário para Reserva de Emergência (%)', hintText: 'Ex: 10 para 10%'),
                  validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _salvarEContinuar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Avançar para Manutenção'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}