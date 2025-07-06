// lib/screens/primeiro_acesso_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'main_screen.dart';

class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para Veículo
  final _consumoController = TextEditingController();
  final _valorVeiculoController = MoneyMaskedTextController(leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _vidaUtilController = TextEditingController();
  final _kmAtualController = TextEditingController();

  // Controllers para Lavagem (NOVOS)
  final _lavagemCustoController = MoneyMaskedTextController(leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  String _frequenciaLavagem = 'semanal'; // 'semanal' ou 'periodica'
  int _diaDaSemanaLavagem = 1; // 1=Seg, 2=Ter... 7=Dom
  final _intervaloDiasLavagemController = TextEditingController(text: '7');


  Future<void> _salvarEContinuar() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // Salva dados do veículo
      await prefs.setDouble('veiculo_consumo_medio', double.tryParse(_consumoController.text) ?? 0.0);
      await prefs.setDouble('carro_valor', _valorVeiculoController.numberValue);
      await prefs.setInt('carro_vida_util_km', int.tryParse(_vidaUtilController.text) ?? 0);
      await prefs.setInt('veiculo_km_atual', int.tryParse(_kmAtualController.text) ?? 0);

      // Salva dados da lavagem (NOVOS)
      await prefs.setDouble('lavagem_custo', _lavagemCustoController.numberValue);
      await prefs.setString('lavagem_frequencia_tipo', _frequenciaLavagem);
      await prefs.setInt('lavagem_dia_semana', _diaDaSemanaLavagem);
      await prefs.setInt('lavagem_intervalo_dias', int.tryParse(_intervaloDiasLavagemController.text) ?? 7);
      // Salva a data atual como a "última lavagem" para iniciar a contagem
      await prefs.setString('lavagem_data_ultima', DateTime.now().toIso8601String());

      // Marca que o primeiro acesso foi concluído
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
                Text('Bem-vindo ao Turno Pago!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Vamos configurar alguns dados para cálculos mais precisos.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),

                const SizedBox(height: 24),
                _buildCard(title: "Dados do Veículo", children: [
                  TextFormField(
                    controller: _kmAtualController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quilometragem ATUAL do veículo (km)'),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    controller: _consumoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Consumo médio do veículo (km/l)'),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    controller: _valorVeiculoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor de compra do veículo (R\$)'),
                  ),
                  TextFormField(
                    controller: _vidaUtilController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Próxima troca de veículo em (km)'),
                  ),
                ]),

                const SizedBox(height: 24),
                _buildCard(title: "Plano de Lavagem", children: [
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
                ]),

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