import 'package:flutter/material.dart';
import '../services/dados_service.dart';

class TurnoScreen extends StatefulWidget {
  const TurnoScreen({super.key});

  @override
  TurnoScreenState createState() => TurnoScreenState();
}

class TurnoScreenState extends State<TurnoScreen> {
  String _plataformaSelecionada = '99';

  final _ganhosController = TextEditingController();
  final _kmRodadoController = TextEditingController();
  final _corridasController = TextEditingController();
  // O _horasController foi removido

  Future<void> _salvarTurno() async {
    final ganhos = double.tryParse(_ganhosController.text) ?? 0;
    final km = double.tryParse(_kmRodadoController.text) ?? 0;
    final corridas = int.tryParse(_corridasController.text) ?? 0;
    // A variável horas foi removida

    await DadosService.salvarDouble('ganhos_turno', ganhos);
    await DadosService.salvarDouble('km_rodado_turno', km);
    // A linha para salvar 'horas_turno' foi removida
    await DadosService.salvarString('plataforma_turno', _plataformaSelecionada);

    if (_plataformaSelecionada == '99') {
      await DadosService.salvarInt('corridas_turno', corridas);
    } else {
      // Limpa o valor de corridas se a plataforma não for 99
      await DadosService.salvarInt('corridas_turno', 0);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Turno salvo com sucesso!')),
    );

    Navigator.pop(context, true); // Volta para a HomeScreen e indica que deve recarregar
  }

  @override
  void dispose() {
    _ganhosController.dispose();
    _kmRodadoController.dispose();
    _corridasController.dispose();
    // O dispose do _horasController foi removido
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Turno')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Selecione a plataforma:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _plataformaSelecionada,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: '99', child: Text('99')),
                DropdownMenuItem(value: 'outro', child: Text('Outros Apps')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _plataformaSelecionada = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ganhosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ganhos do turno (R\$)'),
            ),
            TextFormField(
              controller: _kmRodadoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'KM rodados'),
            ),
            if (_plataformaSelecionada == '99') ...[
              TextFormField(
                controller: _corridasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade de corridas'),
              ),
            ],
            // O TextFormField de horas foi removido daqui
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarTurno,
              child: const Text('Salvar turno'),
            ),
          ],
        ),
      ),
    );
  }
}