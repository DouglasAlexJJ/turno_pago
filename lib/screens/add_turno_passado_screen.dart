// lib/screens/add_turno_passado_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:uuid/uuid.dart';

class AddTurnoPassadoScreen extends StatefulWidget {
  final Turno? turnoParaEditar; // ACEITA UM TURNO PARA EDIÇÃO

  const AddTurnoPassadoScreen({super.key, this.turnoParaEditar});

  @override
  State<AddTurnoPassadoScreen> createState() => _AddTurnoPassadoScreenState();
}

class _AddTurnoPassadoScreenState extends State<AddTurnoPassadoScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _dataSelecionada = DateTime.now();

  final _ganhosController = MoneyMaskedTextController(leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _kmRodadoController = TextEditingController();
  final _corridasController = TextEditingController();
  final _precoCombustivelController = MoneyMaskedTextController(leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');

  final _kmRodadoFocus = FocusNode();
  final _corridasFocus = FocusNode();
  final _precoCombustivelFocus = FocusNode();

  bool get _isEditing => widget.turnoParaEditar != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final turno = widget.turnoParaEditar!;
      _dataSelecionada = turno.data;
      _ganhosController.updateValue(turno.ganhos);
      _kmRodadoController.text = turno.kmRodados.toString();
      _corridasController.text = turno.corridas.toString();
      _precoCombustivelController.updateValue(turno.precoCombustivel);
    }
  }

  @override
  void dispose() {
    _kmRodadoFocus.dispose();
    _corridasFocus.dispose();
    _precoCombustivelFocus.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (dataEscolhida != null && dataEscolhida != _dataSelecionada) {
      setState(() {
        _dataSelecionada = dataEscolhida;
      });
    }
  }

  Future<void> _salvarTurnoPassado() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final turnoProcessado = Turno(
        id: widget.turnoParaEditar?.id ?? const Uuid().v4(),
        data: _dataSelecionada,
        ganhos: _ganhosController.numberValue,
        kmRodados: double.tryParse(_kmRodadoController.text) ?? 0.0,
        corridas: int.tryParse(_corridasController.text) ?? 0,
        precoCombustivel: _precoCombustivelController.numberValue,
      );

      if (_isEditing) {
        await DadosService.atualizarTurno(turnoProcessado);
      } else {
        await DadosService.adicionarTurno(turnoProcessado);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Turno Passado' : 'Adicionar Turno Passado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: const Text('Data do Turno'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selecionarData(context),
              ),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ganhosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ganhos Totais do Turno'),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).requestFocus(_kmRodadoFocus),
                validator: (v) => _ganhosController.numberValue <= 0 ? 'Insira um valor válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmRodadoController,
                focusNode: _kmRodadoFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'KM Rodados no Turno'),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).requestFocus(_corridasFocus),
                validator: (v) => (double.tryParse(v ?? '0') ?? 0) <= 0 ? 'Insira um valor válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _corridasController,
                focusNode: _corridasFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade de Corridas'),
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).requestFocus(_precoCombustivelFocus),
                validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoCombustivelController,
                focusNode: _precoCombustivelFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Preço do Combustível (na data)'),
                textInputAction: TextInputAction.done,
                onEditingComplete: _salvarTurnoPassado,
                validator: (v) => _precoCombustivelController.numberValue <= 0 ? 'Insira um valor válido' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvarTurnoPassado,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Salvar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}