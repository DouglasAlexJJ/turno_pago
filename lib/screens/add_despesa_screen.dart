// lib/screens/add_despesa_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:uuid/uuid.dart';
import '../models/despesa.dart';
import '../services/dados_service.dart';

class AddDespesaScreen extends StatefulWidget {
  const AddDespesaScreen({super.key});

  @override
  AddDespesaScreenState createState() => AddDespesaScreenState();
}

class AddDespesaScreenState extends State<AddDespesaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  String _categoriaSelecionada = 'Combustível';

  // Controladores de foco
  final _valorFocusNode = FocusNode();

  final List<String> _categorias = [
    'Combustível',
    'Alimentação',
    'Manutenção',
    'Lavagem',
    'Pedágio',
    'Outros',
  ];

  Future<void> _salvarDespesa() async {
    // Esconde o teclado antes de salvar
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final novaDespesa = Despesa(
        id: const Uuid().v4(),
        descricao: _descricaoController.text,
        valor: _valorController.numberValue,
        data: DateTime.now(),
        categoria: _categoriaSelecionada,
      );

      await DadosService.adicionarDespesa(novaDespesa);

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _valorFocusNode.dispose(); // Limpa o focus node
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Despesa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                textInputAction: TextInputAction.next, // Ação do teclado
                onEditingComplete: () =>
                    FocusScope.of(context).requestFocus(_valorFocusNode), // Pula para o próximo
                validator: (value) =>
                value!.isEmpty ? 'Por favor, insira uma descrição' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                focusNode: _valorFocusNode, // Associa o focus node
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done, // Ação final
                onEditingComplete: _salvarDespesa, // Salva ao concluir
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
                child: const Text('Salvar Despesa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}