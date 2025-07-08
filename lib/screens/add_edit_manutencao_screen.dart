// lib/screens/add_edit_manutencao_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:uuid/uuid.dart';

class AddEditManutencaoScreen extends StatefulWidget {
  final ManutencaoItem? item;

  const AddEditManutencaoScreen({super.key, this.item});

  @override
  State<AddEditManutencaoScreen> createState() =>
      _AddEditManutencaoScreenState();
}

class _AddEditManutencaoScreenState extends State<AddEditManutencaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _vidaUtilController = TextEditingController();
  final _kmUltimaTrocaController = TextEditingController(); // CAMPO CORRIGIDO/ADICIONADO

  final _custoController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nomeController.text = widget.item!.nome;
      _custoController.updateValue(widget.item!.custo);
      _vidaUtilController.text = widget.item!.vidaUtilKm.toString();
      _kmUltimaTrocaController.text = widget.item!.kmUltimaTroca.toString(); // CAMPO CORRIGIDO/ADICIONADO
    }
  }

  Future<void> _salvarItem() async {
    if (_formKey.currentState!.validate()) {
      final item = ManutencaoItem(
        id: widget.item?.id ?? const Uuid().v4(),
        nome: _nomeController.text,
        custo: _custoController.numberValue,
        vidaUtilKm: int.tryParse(_vidaUtilController.text) ?? 0,
        kmUltimaTroca: int.tryParse(_kmUltimaTrocaController.text) ?? 0, // CAMPO CORRIGIDO/ADICIONADO
        dataUltimaTroca: widget.item?.dataUltimaTroca,
      );
      await DadosService.salvarManutencaoItem(item);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  // NOVA FUNÇÃO PARA EXCLUIR O ITEM
  Future<void> _excluirItem() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o item "${widget.item!.nome}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DadosService.removerManutencaoItem(widget.item!.id);
      if (!mounted) return;
      // Sai da tela de edição após excluir
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Adicionar Item' : 'Editar Item'),
        // BOTÃO DE EXCLUIR NA BARRA SUPERIOR
        actions: [
          if (widget.item != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _excluirItem,
            ),
        ],
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
                decoration: const InputDecoration(labelText: 'Custo Total da Troca'),
                validator: (v) => _custoController.numberValue == 0 ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vidaUtilController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Vida Útil do item (em KM)'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              // CAMPO CORRIGIDO/ADICIONADO
              TextFormField(
                controller: _kmUltimaTrocaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quilometragem da Última Troca',
                  hintText: 'A KM do veículo quando o item foi trocado',
                ),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarItem,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}