import 'package:flutter/material.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:uuid/uuid.dart';
import '../services/dados_service.dart';

class TurnoScreen extends StatefulWidget {
  const TurnoScreen({super.key});

  @override
  TurnoScreenState createState() => TurnoScreenState();
}

class TurnoScreenState extends State<TurnoScreen> {
  String _plataformaSelecionada = '99';

  // Controladores para o modo "Outros Apps"
  final _ganhosController = TextEditingController();
  final _kmRodadoController = TextEditingController();

  // Controladores para o modo "99"
  final _ganhoPorKmController = TextEditingController();
  final _ganhoPorCorridaController = TextEditingController();
  final _corridasController = TextEditingController();

  // Controlador comum
  final _precoCombustivelController = TextEditingController();

  Future<void> _salvarTurno() async {
    double ganhosFinais = 0;
    double kmFinais = 0;
    int corridasFinais = 0;

    // Lógica de cálculo condicional
    if (_plataformaSelecionada == '99') {
      final ganhoPorCorrida = double.tryParse(_ganhoPorCorridaController.text.replaceAll(',', '.')) ?? 0;
      final ganhoPorKm = double.tryParse(_ganhoPorKmController.text.replaceAll(',', '.')) ?? 0;
      corridasFinais = int.tryParse(_corridasController.text) ?? 0;

      if (ganhoPorKm == 0 || ganhoPorCorrida == 0 || corridasFinais == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preencha todos os campos da 99 para calcular.'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      ganhosFinais = ganhoPorCorrida * corridasFinais;
      kmFinais = ganhosFinais / ganhoPorKm;

    } else { // "Outros Apps"
      ganhosFinais = double.tryParse(_ganhosController.text.replaceAll(',', '.')) ?? 0;
      kmFinais = double.tryParse(_kmRodadoController.text.replaceAll(',', '.')) ?? 0;

      if (ganhosFinais == 0 || kmFinais == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preencha os ganhos e o KM rodado.'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    final precoCombustivel = double.tryParse(_precoCombustivelController.text.replaceAll(',', '.')) ?? 0;
    if (precoCombustivel == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, informe o preço do combustível.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final novoTurno = Turno(
      id: const Uuid().v4(),
      data: DateTime.now(),
      plataforma: _plataformaSelecionada,
      ganhos: ganhosFinais,
      kmRodados: kmFinais,
      precoCombustivel: precoCombustivel,
      corridas: corridasFinais,
    );

    await DadosService.adicionarTurno(novoTurno);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Turno salvo com sucesso!')),
    );

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _ganhosController.dispose();
    _kmRodadoController.dispose();
    _ganhoPorKmController.dispose();
    _ganhoPorCorridaController.dispose();
    _corridasController.dispose();
    _precoCombustivelController.dispose();
    super.dispose();
  }

  // Widget que constrói os campos para a 99
  Widget _buildForm99() {
    return Column(
      children: [
        TextFormField(
          controller: _ganhoPorCorridaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Média de Ganhos por Corrida (R\$)'),
        ),
        TextFormField(
          controller: _ganhoPorKmController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Média de Ganhos por KM (R\$)'),
        ),
        TextFormField(
          controller: _corridasController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantidade de corridas'),
        ),
      ],
    );
  }

  // Widget que constrói os campos para Outros Apps
  Widget _buildFormOutros() {
    return Column(
      children: [
        TextFormField(
          controller: _ganhosController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Ganhos totais do turno (R\$)'),
        ),
        TextFormField(
          controller: _kmRodadoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'KM totais rodados'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Novo Turno')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButton<String>(
              value: _plataformaSelecionada,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: '99', child: Text('99 (Cálculo por Médias)')),
                DropdownMenuItem(value: 'outro', child: Text('Outros Apps (Cálculo por Totais)')),
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

            // Renderização condicional do formulário
            if (_plataformaSelecionada == '99')
              _buildForm99()
            else
              _buildFormOutros(),

            const SizedBox(height: 8),

            // Campo comum para ambos
            TextFormField(
              controller: _precoCombustivelController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Preço do combustível (R\$/L)'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarTurno,
              child: const Text('Salvar Turno'),
            ),
          ],
        ),
      ),
    );
  }
}