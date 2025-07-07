// lib/screens/config_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'carro_screen.dart';
import 'manutencao_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consumoController = TextEditingController();
  final _metaDiariaController = TextEditingController(); // Ainda usa SharedPreferences direto
  late Veiculo _veiculo;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final veiculoData = await VeiculoService.getVeiculo();
    // Você precisará adicionar a lógica para a meta diária se ela continuar aqui
    setState(() {
      _veiculo = veiculoData;
      _consumoController.text = _veiculo.consumoMedio.toString();
    });
  }

  Future<void> _salvarConfiguracoes() async {
    if (_formKey.currentState!.validate()) {
      final novoVeiculo = Veiculo(
        consumoMedio: double.tryParse(_consumoController.text) ?? _veiculo.consumoMedio,
        kmAtual: _veiculo.kmAtual, // Preserva os dados não editáveis aqui
        valorProximoVeiculo: _veiculo.valorProximoVeiculo,
        proximaTrocaKm: _veiculo.proximaTrocaKm,
      );

      await VeiculoService.salvarVeiculo(novoVeiculo);
      // Salvar a meta diária continua igual por enquanto
      // ...

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Veículo', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _consumoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Consumo médio do veículo (km/l)'),
                        validator: (value) => value!.isEmpty ? 'Informe o consumo' : null,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.build),
                          label: const Text('Custos de Manutenção'),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManutencaoScreen())),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Plano de Troca do Veículo'),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CarroScreen())),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Metas', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _metaDiariaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Meta diária de lucro (R\$)'),
                        validator: (value) => value!.isEmpty ? 'Informe sua meta diária' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarConfiguracoes,
                child: const Text('Salvar Tudo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}