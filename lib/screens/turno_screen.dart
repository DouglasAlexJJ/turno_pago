import 'package:flutter/material.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:uuid/uuid.dart'; // Importa o pacote para gerar IDs
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

  Future<void> _salvarTurno() async {
    // Validação simples para garantir que os campos não estão vazios
    if (_ganhosController.text.isEmpty || _kmRodadoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os ganhos e o KM rodado.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_plataformaSelecionada == '99' && _corridasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a quantidade de corridas.'), backgroundColor: Colors.red),
      );
      return;
    }


    // Cria um novo objeto Turno com os dados da tela
    final novoTurno = Turno(
      id: const Uuid().v4(), // Cria um ID único para o turno
      data: DateTime.now(), // Grava a data e hora atual
      plataforma: _plataformaSelecionada,
      ganhos: double.tryParse(_ganhosController.text.replaceAll(',', '.')) ?? 0.0,
      kmRodados: double.tryParse(_kmRodadoController.text.replaceAll(',', '.')) ?? 0.0,
      corridas: _plataformaSelecionada == '99'
          ? int.tryParse(_corridasController.text) ?? 0
          : 0,
    );

    // Usa o novo método do DadosService para adicionar o turno à lista
    await DadosService.adicionarTurno(novoTurno);

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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ganhos do turno (R\$)'),
            ),
            TextFormField(
              controller: _kmRodadoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'KM rodados'),
            ),
            if (_plataformaSelecionada == '99') ...[
              TextFormField(
                controller: _corridasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade de corridas'),
              ),
            ],
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