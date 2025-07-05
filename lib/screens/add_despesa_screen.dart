// lib/screens/add_despesa_screen.dart

import 'package:flutter/material.dart';
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
  final _valorController = TextEditingController();
  String _categoriaSelecionada = 'Combustível'; // Categoria padrão

  final List<String> _categorias = [
    'Combustível',
    'Alimentação',
    'Manutenção',
    'Lavagem',
    'Pedágio',
    'Outros',
  ];

  Future<void> _salvarDespesa() async {
    if (_formKey.currentState!.validate()) {
      final novaDespesa = Despesa(
        id: const Uuid().v4(), // Gera um ID único
        descricao: _descricaoController.text,
        valor: double.parse(_valorController.text.replaceAll(',', '.')),
        data: DateTime.now(),
        categoria: _categoriaSelecionada,
      );

      await DadosService.adicionarDespesa(novaDespesa);

      if (!mounted) return;
      Navigator.pop(context, true); // Volta e indica que a lista deve ser atualizada
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
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
                validator: (value) =>
                value!.isEmpty ? 'Por favor, insira uma descrição' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Por favor, insira um número válido';
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