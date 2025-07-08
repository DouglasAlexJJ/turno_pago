// lib/screens/despesas_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turno_pago/widgets/dica_arrastar.dart';
import 'package:turno_pago/models/despesa.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';
import 'add_despesa_screen.dart';

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
    _carregarDespesas();
  }

  void _carregarDespesas() {
    setState(() {
      _despesasFuture = DadosService.getDespesas().then((despesas) {
        despesas.sort((a, b) => b.data.compareTo(a.data));
        return despesas;
      });
    });
  }

  void _navegarParaEditarDespesa(Despesa despesa) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDespesaScreen(despesaParaEditar: despesa),
      ),
    );
    if (result == true) {
      _carregarDespesas();
    }
  }

  void _navegarParaAddDespesa() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDespesaScreen()),
    );
    if (result == true) {
      _carregarDespesas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Despesas')),
      body: FutureBuilder<List<Despesa>>(
        future: _despesasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar despesas.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma despesa registrada.'));
          }

          var despesas = snapshot.data!;

          return Column(
            children: [
              if (despesas.isNotEmpty) const DicaArrastar(),
              Expanded(
                child: ListView.builder(
                  itemCount: despesas.length,
                  itemBuilder: (context, index) {
                    final despesa = despesas[index];
                    return Dismissible(
                      key: Key(despesa.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        final despesaRemovida = despesas[index];
                        final int itemIndex = index;

                        setState(() {
                          despesas.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text("${despesa.descricao} removida."),
                            action: SnackBarAction(
                              label: "Desfazer",
                              onPressed: () {
                                setState(() {
                                  despesas.insert(itemIndex, despesaRemovida);
                                });
                              },
                            ),
                          ),
                        )
                            .closed
                            .then((reason) {
                          if (reason != SnackBarClosedReason.action) {
                            DadosService.removerDespesa(despesaRemovida.id);
                          }
                        });
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: InkWell(
                          onTap: () => _navegarParaEditarDespesa(despesa),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(_getIconForCategory(despesa.categoria)),
                            ),
                            title: Text(despesa.descricao),
                            subtitle: Text(
                                '${despesa.categoria} - ${DateFormat('dd/MM/yyyy').format(despesa.data)}'),
                            trailing: Text(
                              AppFormatters.formatCurrency(despesa.valor),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaAddDespesa,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Combustível':
        return Icons.local_gas_station;
      case 'Alimentação':
        return Icons.restaurant;
      case 'Manutenção':
        return Icons.build;
      case 'Lavagem':
        return Icons.local_car_wash;
      case 'Pedágio':
        return Icons.signpost;
      default:
        return Icons.receipt_long;
    }
  }
}