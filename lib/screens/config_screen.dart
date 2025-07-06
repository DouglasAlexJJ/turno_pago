// lib/screens/config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'carro_screen.dart';
import 'manutencao_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _consumoController = TextEditingController();
  final _metaDiariaController = MoneyMaskedTextController(leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _lavagemCustoController = MoneyMaskedTextController(leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _intervaloDiasLavagemController = TextEditingController();

  // State variables
  String _frequenciaLavagem = 'semanal';
  int _diaDaSemanaLavagem = 1;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    _consumoController.text = (prefs.getDouble('veiculo_consumo_medio') ?? 0.0).toString();
    _metaDiariaController.updateValue(prefs.getDouble('meta_diaria') ?? 0.0);
    _lavagemCustoController.updateValue(prefs.getDouble('lavagem_custo') ?? 0.0);

    setState(() {
      _frequenciaLavagem = prefs.getString('lavagem_frequencia_tipo') ?? 'semanal';
      _diaDaSemanaLavagem = prefs.getInt('lavagem_dia_semana') ?? 1;
      _intervaloDiasLavagemController.text = (prefs.getInt('lavagem_intervalo_dias') ?? 7).toString();
    });
  }

  Future<void> _salvarConfiguracoes() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // Salva dados do veículo e metas
      await prefs.setDouble('veiculo_consumo_medio', double.tryParse(_consumoController.text) ?? 0.0);
      await prefs.setDouble('meta_diaria', _metaDiariaController.numberValue);

      // Salva dados da lavagem
      await prefs.setDouble('lavagem_custo', _lavagemCustoController.numberValue);
      await prefs.setString('lavagem_frequencia_tipo', _frequenciaLavagem);
      await prefs.setInt('lavagem_dia_semana', _diaDaSemanaLavagem);
      await prefs.setInt('lavagem_intervalo_dias', int.tryParse(_intervaloDiasLavagemController.text) ?? 7);

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
              _buildCard(
                  title: "Geral",
                  children: [
                    TextFormField(
                      controller: _metaDiariaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Meta diária de lucro (R\$)'),
                    ),
                  ]
              ),
              const SizedBox(height: 16),
              _buildCard(
                  title: "Veículo",
                  children: [
                    TextFormField(
                      controller: _consumoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Consumo médio do veículo (km/l)'),
                      validator: (value) => value!.isEmpty ? 'Informe o consumo' : null,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        child: const Text('Custos de Manutenção'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManutencaoScreen())),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        child: const Text('Plano de Troca do Veículo'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CarroScreen())),
                      ),
                    ),
                  ]
              ),
              const SizedBox(height: 16),
              _buildCard(
                  title: "Plano de Lavagem",
                  children: [
                    TextFormField(
                      controller: _lavagemCustoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Custo da lavagem (R\$)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _frequenciaLavagem,
                      decoration: const InputDecoration(labelText: 'Frequência da Lavagem'),
                      items: const [
                        DropdownMenuItem(value: 'semanal', child: Text('Semanal (dia fixo)')),
                        DropdownMenuItem(value: 'periodica', child: Text('Periódica (a cada X dias)')),
                      ],
                      onChanged: (val) => setState(() => _frequenciaLavagem = val!),
                    ),
                    if (_frequenciaLavagem == 'semanal')
                      DropdownButtonFormField<int>(
                        value: _diaDaSemanaLavagem,
                        decoration: const InputDecoration(labelText: 'Dia da Semana'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Segunda-feira')),
                          DropdownMenuItem(value: 2, child: Text('Terça-feira')),
                          DropdownMenuItem(value: 3, child: Text('Quarta-feira')),
                          DropdownMenuItem(value: 4, child: Text('Quinta-feira')),
                          DropdownMenuItem(value: 5, child: Text('Sexta-feira')),
                          DropdownMenuItem(value: 6, child: Text('Sábado')),
                          DropdownMenuItem(value: 7, child: Text('Domingo')),
                        ],
                        onChanged: (val) => setState(() => _diaDaSemanaLavagem = val!),
                      )
                    else
                      TextFormField(
                        controller: _intervaloDiasLavagemController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Lavar a cada quantos dias?'),
                      )
                  ]
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

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}