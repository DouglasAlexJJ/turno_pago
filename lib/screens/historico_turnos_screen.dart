// lib/screens/historico_turnos_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turno_pago/widgets/dica_arrastar.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/screens/add_turno_passado_screen.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';

class HistoricoTurnosScreen extends StatefulWidget {
  const HistoricoTurnosScreen({super.key});

  @override
  State<HistoricoTurnosScreen> createState() => _HistoricoTurnosScreenState();
}

class _HistoricoTurnosScreenState extends State<HistoricoTurnosScreen> {
  late Future<List<Turno>> _turnosFuture;

  @override
  void initState() {
    super.initState();
    _carregarTurnos();
  }

  void _carregarTurnos() {
    setState(() {
      _turnosFuture = DadosService.getTurnos().then((turnos) {
        turnos.sort((a, b) => b.data.compareTo(a.data));
        return turnos;
      });
    });
  }

  void _navegarParaEditarTurno(Turno turno) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTurnoPassadoScreen(turnoParaEditar: turno),
      ),
    );
    if (result == true) {
      _carregarTurnos();
    }
  }

  void _navegarParaAdicionarTurnoPassado() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTurnoPassadoScreen()),
    );
    if (result == true) {
      _carregarTurnos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Turnos'),
      ),
      body: FutureBuilder<List<Turno>>(
        future: _turnosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os turnos.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum turno registrado.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          var turnos = snapshot.data!;

          return Column(
            children: [
              if (turnos.isNotEmpty) const DicaArrastar(),
              Expanded(
                child: ListView.builder(
                  itemCount: turnos.length,
                  itemBuilder: (context, index) {
                    final turno = turnos[index];
                    return Dismissible(
                      key: Key(turno.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        final turnoRemovido = turnos[index];
                        final int itemIndex = index;

                        setState(() {
                          turnos.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                                "Turno de ${DateFormat('dd/MM/yyyy').format(turno.data)} removido."),
                            action: SnackBarAction(
                              label: "Desfazer",
                              onPressed: () {
                                setState(() {
                                  turnos.insert(itemIndex, turnoRemovido);
                                });
                              },
                            ),
                          ),
                        )
                            .closed
                            .then((reason) {
                          if (reason != SnackBarClosedReason.action) {
                            DadosService.removerTurno(turnoRemovido.id);
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
                            horizontal: 16, vertical: 8),
                        child: InkWell(
                          onTap: () => _navegarParaEditarTurno(turno),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: const CircleAvatar(
                              child: Icon(Icons.calendar_month),
                            ),
                            title: Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(turno.data)}',
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Ganhos: ${AppFormatters.formatCurrency(turno.ganhos)} | KM: ${AppFormatters.formatKm(turno.kmRodados)}',
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
        onPressed: _navegarParaAdicionarTurnoPassado,
        tooltip: 'Adicionar Turno Passado',
        child: const Icon(Icons.add),
      ),
    );
  }
}