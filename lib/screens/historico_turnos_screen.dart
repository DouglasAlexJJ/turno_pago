// lib/screens/historico_turnos_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Future<void> _removerTurno(String id) async {
    // ... (código de remoção continua o mesmo)
  }

  // NOVA FUNÇÃO PARA EDITAR
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

          final turnos = snapshot.data!;

          return ListView.builder(
            itemCount: turnos.length,
            itemBuilder: (context, index) {
              final turno = turnos[index];
              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // ENVOLVIDO COM INKWELL
                child: InkWell(
                  onTap: () => _navegarParaEditarTurno(turno),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      child: Icon(Icons.calendar_month),
                    ),
                    title: Text(
                      'Data: ${DateFormat('dd/MM/yyyy').format(turno.data)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Ganhos: ${AppFormatters.formatCurrency(turno.ganhos)} | KM: ${AppFormatters.formatKm(turno.kmRodados)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever,
                          color: Colors.redAccent),
                      onPressed: () => _removerTurno(turno.id),
                    ),
                  ),
                ),
              );
            },
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