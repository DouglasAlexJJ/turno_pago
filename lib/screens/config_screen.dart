// lib/screens/config_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'manutencao_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consumoController = TextEditingController();
  final _percentualReservaController = TextEditingController();

  // NOVO CONTROLADOR para a quilometragem
  final _kmAtualController = TextEditingController();

  late Veiculo _veiculo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final veiculoData = await VeiculoService.getVeiculo();
    if (mounted) {
      setState(() {
        _veiculo = veiculoData;
        _consumoController.text = _veiculo.consumoMedio.toString();
        _percentualReservaController.text = _veiculo.percentualReserva.toString();

        // CARREGA O NOVO DADO no controlador
        _kmAtualController.text = _veiculo.kmAtual.toString(); //

        _isLoading = false;
      });
    }
  }

  Future<void> _salvarConfiguracoes() async {
    if (_formKey.currentState!.validate()) {
      final novoVeiculo = _veiculo.copyWith(
        consumoMedio: double.tryParse(_consumoController.text) ?? _veiculo.consumoMedio,
        percentualReserva: double.tryParse(_percentualReservaController.text) ?? _veiculo.percentualReserva,

        // SALVA O NOVO DADO da quilometragem
        kmAtual: int.tryParse(_kmAtualController.text) ?? _veiculo.kmAtual,
      );

      await VeiculoService.salvarVeiculo(novoVeiculo);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                      Text('Veículo e Finanças', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),

                      // NOVO CAMPO para editar a quilometragem
                      TextFormField(
                        controller: _kmAtualController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quilometragem ATUAL do Veículo (km)'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe a quilometragem';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _consumoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Consumo médio do veículo (km/l)'),
                        validator: (value) => value!.isEmpty ? 'Informe o consumo' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _percentualReservaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Lucro diário para Reserva de Emergência (%)'),
                        validator: (value) => value!.isEmpty ? 'Informe o percentual' : null,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.build),
                          label: const Text('Custos de Manutenção'),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManutencaoScreen())),
                        ),
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