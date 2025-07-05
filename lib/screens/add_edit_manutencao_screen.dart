// lib/screens/add_edit_manutencao_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:uuid/uuid.dart';

class AddEditManutencaoScreen extends StatefulWidget {
  final ManutencaoItem? item;

  const AddEditManutencaoScreen({super.key, this.item});

  @override
  State<AddEditManutencaoScreen> createState() => _AddEditManutencaoScreenState();
}

class _AddEditManutencaoScreenState extends State<AddEditManutencaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _custoController = TextEditingController();
  final _vidaUtilController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nomeController.text = widget.item!.nome;
      _custoController.text = widget.item!.custo.toString();
      _vidaUtilController.text = widget.item!.vidaUtilKm.toString();
    }
  }

  Future<void> _salvarItem() async {
    if (_formKey.currentState!.validate()) {
      final item = ManutencaoItem(
        id: widget.item?.id ?? const Uuid().v4(), // Usa o ID existente ou cria um novo
        nome: _nomeController.text,
        custo: double.parse(_custoController.text),
        vidaUtilKm: int.parse(_vidaUtilController.text),
      );
      await DadosService.salvarManutencaoItem(item);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Adicionar Item' : 'Editar Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Item (ex: Pneus)'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _custoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Custo Total da Troca (R\$)'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vidaUtilController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duração Média (em KM)'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarItem,
                child: const Text('Salvar Item'),
              )
            ],
          ),
        ),
      ),
    );
  }
}