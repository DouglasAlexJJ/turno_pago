// lib/screens/manutencao_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/screens/add_edit_manutencao_screen.dart';
import 'package:turno_pago/services/dados_service.dart';

class ManutencaoScreen extends StatefulWidget {
  const ManutencaoScreen({super.key});

  @override
  ManutencaoScreenState createState() => ManutencaoScreenState();
}

class ManutencaoScreenState extends State<ManutencaoScreen> {
  List<ManutencaoItem> _itens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  Future<void> _carregarItens() async {
    setState(() => _isLoading = true);
    final itens = await DadosService.getManutencaoItens();
    setState(() {
      _itens = itens;
      _isLoading = false;
    });
  }

  void _navegarParaAddItem() async {
    final bool? recarregar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditManutencaoScreen()),
    );
    if (recarregar == true) {
      _carregarItens();
    }
  }

  void _navegarParaEditItem(ManutencaoItem item) async {
    final bool? recarregar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditManutencaoScreen(item: item)),
    );
    if (recarregar == true) {
      _carregarItens();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcula o custo total por KM somando o custo de cada item
    final double custoTotalPorKm = _itens.fold(0.0, (soma, item) => soma + item.custoPorKm);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custos de Manutenção'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Card com o resumo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Custo Total de Manutenção por KM:',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'R\$ ${custoTotalPorKm.toStringAsFixed(3)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Lista de itens
          Expanded(
            child: ListView.builder(
              itemCount: _itens.length,
              itemBuilder: (context, index) {
                final item = _itens[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(item.nome),
                    subtitle: Text('Custo/KM: R\$ ${item.custoPorKm.toStringAsFixed(3)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _navegarParaEditItem(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await DadosService.removerManutencaoItem(item.id);
                            _carregarItens();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaAddItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}