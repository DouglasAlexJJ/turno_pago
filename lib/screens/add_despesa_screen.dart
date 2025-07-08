// lib/screens/add_despesa_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/despesa.dart';
import '../services/dados_service.dart';

class AddDespesaScreen extends StatefulWidget {
  final Despesa? despesaParaEditar; // ACEITA UMA DESPESA PARA EDIÇÃO

  const AddDespesaScreen({super.key, this.despesaParaEditar});

  @override
  AddDespesaScreenState createState() => AddDespesaScreenState();
}

class AddDespesaScreenState extends State<AddDespesaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  String _categoriaSelecionada = 'Combustível';
  DateTime _dataSelecionada = DateTime.now();

  final _valorFocusNode = FocusNode();

  bool get _isEditing => widget.despesaParaEditar != null;

  final List<String> _categorias = [
    'Combustível',
    'Alimentação',
    'Manutenção',
    'Lavagem',
    'Pedágio',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    // Se estiver editando, preenche os campos com os dados existentes
    if (_isEditing) {
      final despesa = widget.despesaParaEditar!;
      _descricaoController.text = despesa.descricao;
      _valorController.updateValue(despesa.valor);
      _categoriaSelecionada = despesa.categoria;
      _dataSelecionada = despesa.data;
    }
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

  Future<void> _salvarDespesa() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final despesaProcessada = Despesa(
        // Usa o ID existente se estiver editando, ou cria um novo se não estiver
        id: widget.despesaParaEditar?.id ?? const Uuid().v4(),
        descricao: _descricaoController.text,
        valor: _valorController.numberValue,
        data: _dataSelecionada,
        categoria: _categoriaSelecionada,
      );

      if (_isEditing) {
        await DadosService.atualizarDespesa(despesaProcessada);
      } else {
        await DadosService.adicionarDespesa(despesaProcessada);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _valorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Despesa' : 'Adicionar Despesa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                title: const Text('Data da Despesa'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selecionarData(context),
              ),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                textInputAction: TextInputAction.next,
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(_valorFocusNode),
                validator: (value) =>
                value!.isEmpty ? 'Por favor, insira uma descrição' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                focusNode: _valorFocusNode,
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onEditingComplete: _salvarDespesa,
                validator: (value) {
                  if (_valorController.numberValue <= 0) {
                    return 'Por favor, insira um valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: _categorias.map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _categoriaSelecionada = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarDespesa,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}