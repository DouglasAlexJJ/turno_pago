import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class CarroScreen extends StatefulWidget {
  const CarroScreen({super.key});

  @override
  CarroScreenState createState() => CarroScreenState();
}

class CarroScreenState extends State<CarroScreen> {
  final _valorAlvoController = TextEditingController();
  final _prazoMesesController = TextEditingController();
  final _valorGuardadoController = TextEditingController();

  double valorDiario = 0.0;
  double progresso = 0.0;

  Future<void> _salvarPlano() async {
    final prefs = await SharedPreferences.getInstance();

    final valorAlvo = double.tryParse(_valorAlvoController.text) ?? 0;
    final prazo = int.tryParse(_prazoMesesController.text) ?? 1;
    final guardado = double.tryParse(_valorGuardadoController.text) ?? 0;

    await prefs.setDouble('carro_valor_alvo', valorAlvo);
    await prefs.setInt('carro_prazo_meses', prazo);
    await prefs.setDouble('carro_valor_guardado', guardado);
    await prefs.setString('carro_data_inicio', DateTime.now().toIso8601String());

    if (!mounted) return;

    final dias = prazo * 30;
    setState(() {
      valorDiario = valorAlvo / dias;
      progresso = min(1.0, guardado / valorAlvo);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plano salvo com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Troca de Carro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              controller: _valorAlvoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor do carro desejado (R\$)'),
            ),
            TextFormField(
              controller: _prazoMesesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prazo para trocar (em meses)'),
            ),
            TextFormField(
              controller: _valorGuardadoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quanto já guardou? (R\$)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarPlano,
              child: const Text('Salvar plano'),
            ),
            const SizedBox(height: 20),
            Text('💰 Valor sugerido por dia: R\$ ${valorDiario.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progresso,
              backgroundColor: Colors.grey[700],
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 10),
            Text('Progresso: ${(progresso * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }
}
