// lib/screens/turno_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'package:uuid/uuid.dart';

class TurnoScreen extends StatefulWidget {
  const TurnoScreen({super.key});

  @override
  TurnoScreenState createState() => TurnoScreenState();
}

class TurnoScreenState extends State<TurnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ganhosController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _kmRodadoController = TextEditingController();
  final _kmAtualVeiculoController = TextEditingController();
  final _corridasController = TextEditingController();
  final _precoCombustivelController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');

  Veiculo? _veiculo;
  bool _isLoading = true;

  // Controladores de foco
  final _kmRodadoFocus = FocusNode();
  final _kmAtualFocus = FocusNode();
  final _corridasFocus = FocusNode();
  final _precoCombustivelFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _carregarDadosVeiculo();
  }

  @override
  void dispose() {
    _kmRodadoFocus.dispose();
    _kmAtualFocus.dispose();
    _corridasFocus.dispose();
    _precoCombustivelFocus.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosVeiculo() async {
    final veiculoData = await VeiculoService.getVeiculo();
    setState(() {
      _veiculo = veiculoData;
      if (veiculoData.kmAtual > 0) {
        _kmAtualVeiculoController.text = veiculoData.kmAtual.toString();
      }
      if (veiculoData.precoCombustivel > 0) {
        _precoCombustivelController.updateValue(veiculoData.precoCombustivel);
      }
      _isLoading = false;
    });
  }

  Future<void> _salvarTurno() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final kmRodadosNoTurno = double.tryParse(_kmRodadoController.text) ?? 0.0;
      final kmAtualVeiculo = int.tryParse(_kmAtualVeiculoController.text) ?? 0;

      final novoTurno = Turno(
        id: const Uuid().v4(),
        data: DateTime.now(),
        ganhos: _ganhosController.numberValue,
        kmRodados: kmRodadosNoTurno,
        corridas: int.tryParse(_corridasController.text) ?? 0,
        precoCombustivel: _precoCombustivelController.numberValue,
      );

      await DadosService.adicionarTurno(novoTurno);

      final veiculoAtualizado = _veiculo!.copyWith(
        kmAtual: kmAtualVeiculo,
        precoCombustivel: _precoCombustivelController.numberValue,
      );
      await VeiculoService.salvarVeiculo(veiculoAtualizado);

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Novo Turno')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _ganhosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ganhos Totais do Turno',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).requestFocus(_kmRodadoFocus),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmRodadoController,
                focusNode: _kmRodadoFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'KM Rodados no Turno (Hodômetro Parcial)',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).requestFocus(_kmAtualFocus),
                validator: (v) => (double.tryParse(v ?? '0') ?? 0) <= 0 ? 'Valor inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmAtualVeiculoController,
                focusNode: _kmAtualFocus,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'KM Atual do Veículo (Hodômetro Total)',
                  hintText: 'Última KM registrada: ${_veiculo?.kmAtual ?? 0}',
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).requestFocus(_corridasFocus),
                validator: (v) => (int.tryParse(v ?? '0') ?? 0) <= (_veiculo?.kmAtual ?? 0) ? 'Deve ser maior que a última KM' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _corridasController,
                focusNode: _corridasFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de Corridas',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).requestFocus(_precoCombustivelFocus),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoCombustivelController,
                focusNode: _precoCombustivelFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço do Combustível (por litro)',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onEditingComplete: _salvarTurno,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarTurno,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Salvar Turno'),
              )
            ],
          ),
        ),
      ),
    );
  }
}