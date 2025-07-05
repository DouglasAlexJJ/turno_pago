import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManutencaoScreen extends StatefulWidget {
  const ManutencaoScreen({super.key});

  @override
  ManutencaoScreenState createState() => ManutencaoScreenState();
}

class ManutencaoScreenState extends State<ManutencaoScreen> {
  final _valorOleoController = TextEditingController();
  final _valorFiltroController = TextEditingController();
  final _valorPastilhaController = TextEditingController();

  double _valorPorKmOleo = 0;
  double _valorPorKmFiltro = 0;
  double _valorPorKmPastilha = 0;

  final int kmTrocaOleo = 8000;
  final int kmTrocaFiltro = 12000;
  final int kmTrocaPastilha = 20000;

  Future<void> _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    double valorOleo = double.tryParse(_valorOleoController.text) ?? 0;
    double valorFiltro = double.tryParse(_valorFiltroController.text) ?? 0;
    double valorPastilha = double.tryParse(_valorPastilhaController.text) ?? 0;

    await prefs.setDouble('oleo_valor', valorOleo);
    await prefs.setDouble('filtro_valor', valorFiltro);
    await prefs.setDouble('pastilha_valor', valorPastilha);

    if (!mounted) return;

    setState(() {
      _valorPorKmOleo = valorOleo / kmTrocaOleo;
      _valorPorKmFiltro = valorFiltro / kmTrocaFiltro;
      _valorPorKmPastilha = valorPastilha / kmTrocaPastilha;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados de manutenção salvos!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    double valorTotalPorKm = _valorPorKmOleo + _valorPorKmFiltro + _valorPorKmPastilha;

    return Scaffold(
      appBar: AppBar(title: const Text('Manutenção Detalhada')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('🔧 Informe os valores aproximados:'),
            TextFormField(
              controller: _valorOleoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Troca de óleo (R\$)'),
            ),
            TextFormField(
              controller: _valorFiltroController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Troca de filtros (R\$)'),
            ),
            TextFormField(
              controller: _valorPastilhaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Troca de pastilhas (R\$)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _salvarDados,
              child: const Text('Salvar Manutenção'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text('💡 Custo estimado por KM rodado:'),
            Text('• Óleo: R\$ ${_valorPorKmOleo.toStringAsFixed(3)}'),
            Text('• Filtros: R\$ ${_valorPorKmFiltro.toStringAsFixed(3)}'),
            Text('• Pastilhas: R\$ ${_valorPorKmPastilha.toStringAsFixed(3)}'),
            const SizedBox(height: 10),
            Text('💰 Total por KM: R\$ ${valorTotalPorKm.toStringAsFixed(3)}'),
          ],
        ),
      ),
    );
  }
}
