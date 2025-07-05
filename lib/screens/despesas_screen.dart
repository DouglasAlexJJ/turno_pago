// lib/screens/despesas_screen.dart

import 'package:flutter/material.dart';
import '../models/despesa.dart';
import '../services/dados_service.dart';
import 'add_despesa_screen.dart';
import 'package:intl/intl.dart'; // Para formatar a data

class DespesasScreen extends StatefulWidget {
  const DespesasScreen({super.key});

  @override
  DespesasScreenState createState() => DespesasScreenState();
}

class DespesasScreenState extends State<DespesasScreen> {
  late Future<List<Despesa>> _despesasFuture;

  @override
  void initState() {
    super.initState();
    _reloadDespesas();
  }

  void _reloadDespesas() {
    setState(() {
      _despesasFuture = DadosService.getDespesas();
    });
  }

  Future<void> _removerDespesa(String id) async {
    // Confirmação opcional
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja apagar esta despesa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );

    if (confirmado == true) {
      await DadosService.removerDespesa(id);
      _reloadDespesas(); // Recarrega a lista
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Despesas')),
      body: FutureBuilder<List<Despesa>>(
        future: _despesasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma despesa registrada.'));
          }

          final despesas = snapshot.data!;
          // Ordena as despesas pela data mais recente primeiro
          despesas.sort((a, b) => b.data.compareTo(a.data));

          return ListView.builder(
            itemCount: despesas.length,
            itemBuilder: (context, index) {
              final despesa = despesas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(despesa.descricao),
                  subtitle: Text('${despesa.categoria} - ${DateFormat('dd/MM/yy').format(despesa.data)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'R\$ ${despesa.valor.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => _removerDespesa(despesa.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDespesaScreen()),
          );
          if (result == true) {
            _reloadDespesas(); // Recarrega a lista se uma nova despesa foi adicionada
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}