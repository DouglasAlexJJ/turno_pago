// lib/screens/relatorios_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';
import 'package:collection/collection.dart';

// Enum para controlar a visão do relatório
enum TipoRelatorio { porDia, porHora }

// Classes de dados para os relatórios
class RelatorioDiario {
  final DateTime data;
  double ganhos = 0;
  double lucroLiquido = 0;
  RelatorioDiario({required this.data});
}

class RelatorioPorHora {
  final int hora;
  double ganhos = 0;
  int totalSegundos = 0;
  double get ganhoPorHora => (totalSegundos > 0) ? (ganhos / (totalSegundos / 3600)) : 0;
  RelatorioPorHora({required this.hora});
}

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  late Future<Map<TipoRelatorio, List>> _relatoriosFuture;
  TipoRelatorio _tipoSelecionado = TipoRelatorio.porDia;

  @override
  void initState() {
    super.initState();
    _relatoriosFuture = _processarDadosRelatorios();
  }

  Future<Map<TipoRelatorio, List>> _processarDadosRelatorios() async {
    final todosOsTurnos = await DadosService.getTurnos();
    // No futuro, podemos adicionar despesas e custos do veículo para um lucro mais preciso

    final relatoriosPorDia = _calcularRelatorioPorDia(todosOsTurnos);
    final relatoriosPorHora = _calcularRelatorioPorHora(todosOsTurnos);

    return {
      TipoRelatorio.porDia: relatoriosPorDia,
      TipoRelatorio.porHora: relatoriosPorHora,
    };
  }

  List<RelatorioDiario> _calcularRelatorioPorDia(List<Turno> turnos) {
    final mapaDeDias = groupBy(turnos, (Turno t) => DateTime(t.data.year, t.data.month, t.data.day));
    final List<RelatorioDiario> listaRelatorio = [];

    mapaDeDias.forEach((dia, turnosDoDia) {
      final relatorioDoDia = RelatorioDiario(data: dia);
      relatorioDoDia.ganhos = turnosDoDia.fold(0.0, (soma, t) => soma + t.ganhos);
      relatorioDoDia.lucroLiquido = relatorioDoDia.ganhos; // Cálculo simplificado por enquanto
      listaRelatorio.add(relatorioDoDia);
    });

    listaRelatorio.sort((a, b) => b.lucroLiquido.compareTo(a.lucroLiquido));
    return listaRelatorio;
  }

  List<RelatorioPorHora> _calcularRelatorioPorHora(List<Turno> turnos) {
    final mapaDeHoras = <int, RelatorioPorHora>{};

    for (var turno in turnos) {
      final hora = turno.data.hour;
      if (!mapaDeHoras.containsKey(hora)) {
        mapaDeHoras[hora] = RelatorioPorHora(hora: hora);
      }
      mapaDeHoras[hora]!.ganhos += turno.ganhos;
      mapaDeHoras[hora]!.totalSegundos += turno.duracaoEmSegundos;
    }

    final listaRelatorio = mapaDeHoras.values.toList();
    listaRelatorio.sort((a, b) => b.ganhoPorHora.compareTo(a.ganhoPorHora));
    return listaRelatorio;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<TipoRelatorio>(
              segments: const [
                ButtonSegment(value: TipoRelatorio.porDia, label: Text("Por Dia"), icon: Icon(Icons.calendar_month)),
                ButtonSegment(value: TipoRelatorio.porHora, label: Text("Por Hora"), icon: Icon(Icons.access_time)),
              ],
              selected: {_tipoSelecionado},
              onSelectionChanged: (selection) {
                setState(() {
                  _tipoSelecionado = selection.first;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<TipoRelatorio, List>>(
              future: _relatoriosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.values.every((list) => list.isEmpty)) {
                  return const Center(child: Text('Nenhum dado para gerar relatórios.'));
                }

                if (_tipoSelecionado == TipoRelatorio.porDia) {
                  final List<RelatorioDiario> relatorio = snapshot.data![TipoRelatorio.porDia] as List<RelatorioDiario>;
                  return _buildListaRelatorioDiario(relatorio);
                } else {
                  final List<RelatorioPorHora> relatorio = snapshot.data![TipoRelatorio.porHora] as List<RelatorioPorHora>;
                  return _buildVisaoRelatorioPorHora(relatorio);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET DO RELATÓRIO DIÁRIO (COMPLETO AGORA)
  Widget _buildListaRelatorioDiario(List<RelatorioDiario> relatorio) {
    if (relatorio.isEmpty) {
      return const Center(child: Text('Nenhum dado para este relatório.'));
    }
    return ListView.builder(
      itemCount: relatorio.length,
      itemBuilder: (context, index) {
        final relatorioDoDia = relatorio[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 ? Colors.green.shade100 : Colors.grey.shade200,
              child: Text(
                '${index + 1}º',
                style: TextStyle(
                    color: index < 3 ? Colors.green.shade800 : Colors.grey.shade700,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              DateFormat('EEEE, dd \'de\' MMMM', 'pt_BR').format(relatorioDoDia.data),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Ganhos: ${AppFormatters.formatCurrency(relatorioDoDia.ganhos)}'),
            trailing: Text(
              AppFormatters.formatCurrency(relatorioDoDia.lucroLiquido),
              style: TextStyle(
                color: relatorioDoDia.lucroLiquido >= 0 ? Colors.green.shade800 : Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisaoRelatorioPorHora(List<RelatorioPorHora> relatorio) {
    if (relatorio.isEmpty) {
      return const Center(child: Text('Nenhum dado para este relatório.'));
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Rendimento Médio por Faixa de Horário", style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: relatorio.isNotEmpty ? relatorio.first.ganhoPorHora * 1.2 : 20,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: const TextStyle(fontSize: 10)),
                      reservedSize: 20,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
                barGroups: relatorio
                    .map(
                      (item) => BarChartGroupData(
                    x: item.hora,
                    barRods: [BarChartRodData(toY: item.ganhoPorHora, color: Colors.green, width: 12, borderRadius: BorderRadius.circular(4))],
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        ),
        const Divider(),
        ...relatorio.map((item) {
          return ListTile(
            leading: CircleAvatar(child: Text('${item.hora}h')),
            title: Text('Rendimento: ${AppFormatters.formatCurrency(item.ganhoPorHora)} / hora'),
            subtitle: Text('Ganhos Totais na Faixa: ${AppFormatters.formatCurrency(item.ganhos)}'),
          );
        })
      ],
    );
  }
}