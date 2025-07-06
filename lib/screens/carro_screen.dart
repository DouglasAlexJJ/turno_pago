// lib/screens/carro_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CarroScreen extends StatefulWidget {
  const CarroScreen({super.key});

  @override
  CarroScreenState createState() => CarroScreenState();
}

class CarroScreenState extends State<CarroScreen> {
  final _valorVeiculoController = TextEditingController();
  final _vidaUtilKmController = TextEditingController();
  double _custoPorKm = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    _valorVeiculoController.text = (prefs.getDouble('carro_valor') ?? 0.0).toString();
    _vidaUtilKmController.text = (prefs.getInt('carro_vida_util_km') ?? 0).toString();
    _calcularCustoPorKm();
  }

  void _calcularCustoPorKm() {
    final valor = double.tryParse(_valorVeiculoController.text) ?? 0;
    final km = int.tryParse(_vidaUtilKmController.text) ?? 0;
    setState(() {
      _custoPorKm = (km > 0) ? valor / km : 0.0;
    });
  }

  Future<void> _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = double.tryParse(_valorVeiculoController.text) ?? 0;
    final km = int.tryParse(_vidaUtilKmController.text) ?? 0;

    await prefs.setDouble('carro_valor', valor);
    await prefs.setInt('carro_vida_util_km', km);

    _calcularCustoPorKm();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plano de troca salvo!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plano de Troca de veículo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Informe os dados para calcular o custo que deverá ser guardado por quilômetro rodado.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _valorVeiculoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor estimado do próximo veículo (R\$)'),
              onChanged: (_) => _calcularCustoPorKm(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vidaUtilKmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Próxima troca de veículo em (KM)'),
              onChanged: (_) => _calcularCustoPorKm(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvarDados,
              child: const Text('Salvar Dados'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Text('Valor a guardar por KM:', style: TextStyle(fontSize: 16)),
                  Text(
                    'R\$ ${_custoPorKm.toStringAsFixed(3)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.amber[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}