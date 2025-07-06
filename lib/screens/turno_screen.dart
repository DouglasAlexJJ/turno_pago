// lib/screens/turno_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:uuid/uuid.dart';
import '../services/dados_service.dart';

class TurnoScreen extends StatefulWidget {
  final Turno? turno;

  const TurnoScreen({super.key, this.turno});

  @override
  TurnoScreenState createState() => TurnoScreenState();
}

class TurnoScreenState extends State<TurnoScreen> {
  late bool _isEditing;
  String _plataformaSelecionada = '99';

  // Controladores para o modo "Outros Apps" (e para edição)
  final _ganhosController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _kmRodadoController = TextEditingController();

  // Controladores para o modo "99" (criação)
  final _ganhoPorKmController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _ganhoPorCorridaController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _corridasController = TextEditingController();

  // Controladores comuns
  final _precoCombustivelController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _kmAtualController = TextEditingController(); // NOVO CONTROLADOR

  @override
  void initState() {
    super.initState();
    _isEditing = widget.turno != null;

    if (_isEditing) {
      final turno = widget.turno!;
      _plataformaSelecionada = turno.plataforma;
      _ganhosController.updateValue(turno.ganhos);
      _kmRodadoController.text = turno.kmRodados.toString().replaceAll('.', ',');
      _corridasController.text = turno.corridas.toString();
      _precoCombustivelController.updateValue(turno.precoCombustivel);
      _kmAtualController.text = turno.kmAtualVeiculo.toString(); // Preenche o novo campo na edição
    }
  }

  Future<void> _salvarTurno() async {
    double ganhosFinais = 0;
    double kmFinais = 0;
    int corridasFinais = 0;

    // Validação do novo campo
    final kmAtual = int.tryParse(_kmAtualController.text) ?? 0;
    if (kmAtual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, informe a quilometragem atual do veículo.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!_isEditing && _plataformaSelecionada == '99') {
      final ganhoPorCorrida = _ganhoPorCorridaController.numberValue;
      final ganhoPorKm = _ganhoPorKmController.numberValue;
      corridasFinais = int.tryParse(_corridasController.text) ?? 0;

      if (ganhoPorKm <= 0 || ganhoPorCorrida <= 0 || corridasFinais <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preencha todos os campos da 99 para calcular.'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      ganhosFinais = ganhoPorCorrida * corridasFinais;
      kmFinais = ganhosFinais / ganhoPorKm;

    } else {
      ganhosFinais = _ganhosController.numberValue;
      kmFinais = double.tryParse(_kmRodadoController.text.replaceAll(',', '.')) ?? 0;
      corridasFinais = int.tryParse(_corridasController.text) ?? 0;

      if (ganhosFinais <= 0 || kmFinais <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preencha os ganhos e o KM rodado.'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    final precoCombustivel = _precoCombustivelController.numberValue;
    if (precoCombustivel <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, informe o preço do combustível.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final turnoParaSalvar = Turno(
      id: widget.turno?.id ?? const Uuid().v4(),
      data: widget.turno?.data ?? DateTime.now(),
      plataforma: _plataformaSelecionada,
      ganhos: ganhosFinais,
      kmRodados: kmFinais,
      precoCombustivel: precoCombustivel,
      corridas: corridasFinais,
      kmAtualVeiculo: kmAtual, // Salva o novo dado
    );

    if (_isEditing) {
      await DadosService.atualizarTurno(turnoParaSalvar);
    } else {
      await DadosService.adicionarTurno(turnoParaSalvar);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Turno salvo com sucesso!')),
    );
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _kmRodadoController.dispose();
    _corridasController.dispose();
    _kmAtualController.dispose(); // Dispose do novo controller
    super.dispose();
  }

  // ... (os métodos _buildForm99 e _buildFormTotais continuam iguais) ...

  Widget _buildForm99() {
    return Column(
      children: [
        TextFormField(
          controller: _ganhoPorCorridaController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Média de Ganhos por Corrida'),
        ),
        TextFormField(
          controller: _ganhoPorKmController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Média de Ganhos por KM'),
        ),
        TextFormField(
          controller: _corridasController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantidade de corridas'),
        ),
      ],
    );
  }

  Widget _buildFormTotais() {
    return Column(
      children: [
        TextFormField(
          controller: _ganhosController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Ganhos totais do turno'),
        ),
        TextFormField(
          controller: _kmRodadoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'KM totais rodados'),
        ),
        if (_plataformaSelecionada == '99')
          TextFormField(
            controller: _corridasController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade de corridas'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Turno' : 'Adicionar Novo Turno')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // NOVO CAMPO DE KM ATUAL - posicionado no topo para destaque
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextFormField(
                  controller: _kmAtualController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'KM Atual do Veículo',
                    border: InputBorder.none,
                    icon: Icon(Icons.speed),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButton<String>(
              value: _plataformaSelecionada,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: '99', child: Text('99 (Cálculo por Médias)')),
                DropdownMenuItem(value: 'outro', child: Text('Outros Apps (Cálculo por Totais)')),
              ],
              onChanged: _isEditing ? null : (value) {
                if (value != null) {
                  setState(() {
                    _plataformaSelecionada = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            if (_isEditing)
              _buildFormTotais()
            else
              _plataformaSelecionada == '99' ? _buildForm99() : _buildFormTotais(),

            const SizedBox(height: 8),

            TextFormField(
              controller: _precoCombustivelController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preço do combustível (R\$/L)'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarTurno,
              child: Text(_isEditing ? 'Salvar Alterações' : 'Salvar Turno'),
            ),
          ],
        ),
      ),
    );
  }
}