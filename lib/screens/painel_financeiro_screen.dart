// lib/screens/painel_financeiro_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/despesa.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';
import 'package:collection/collection.dart';

class PainelFinanceiroScreen extends StatefulWidget {
  const PainelFinanceiroScreen({super.key});

  @override
  State<PainelFinanceiroScreen> createState() => _PainelFinanceiroScreenState();
}

class _PainelFinanceiroScreenState extends State<PainelFinanceiroScreen> {
  String _periodoSelecionado = 'semana';
  late Future<Map<String, dynamic>> _dadosDoPeriodoFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _dadosDoPeriodoFuture = _processarDadosDoPeriodo();
    });
  }

  Future<Map<String, dynamic>> _processarDadosDoPeriodo() async {
    final todosOsTurnos = await DadosService.getTurnos();
    final todasAsDespesas = await DadosService.getDespesas();

    final agora = DateTime.now();
    DateTime inicioPeriodo;

    if (_periodoSelecionado == 'semana') {
      final diaDaSemana = agora.weekday == 7 ? 0 : agora.weekday;
      inicioPeriodo = agora.subtract(Duration(days: diaDaSemana));
      inicioPeriodo = DateTime(inicioPeriodo.year, inicioPeriodo.month, inicioPeriodo.day);
    } else { // Mês
      inicioPeriodo = DateTime(agora.year, agora.month, 1);
    }

    final turnosDoPeriodo = todosOsTurnos.where((t) => t.data.isAfter(inicioPeriodo));
    final despesasDoPeriodo = todasAsDespesas.where((d) => d.data.isAfter(inicioPeriodo));

    // Cálculos financeiros
    double ganhosDoPeriodo = turnosDoPeriodo.fold(0.0, (soma, t) => soma + t.ganhos);
    double kmRodadosPeriodo = turnosDoPeriodo.fold(0.0, (soma, t) => soma + t.kmRodados);
    int corridasPeriodo = turnosDoPeriodo.fold(0, (soma, t) => soma + t.corridas);

    // Métricas de desempenho
    final ganhoPorKm = (kmRodadosPeriodo > 0) ? ganhosDoPeriodo / kmRodadosPeriodo : 0.0;
    final ganhoPorCorrida = (corridasPeriodo > 0) ? ganhosDoPeriodo / corridasPeriodo : 0.0;

    // Agrupamento e soma das despesas por categoria
    final despesasAgrupadas = groupBy(despesasDoPeriodo, (Despesa d) => d.categoria);
    final Map<String, double> somaPorCategoria = despesasAgrupadas.map(
          (categoria, lista) => MapEntry(
        categoria,
        lista.fold(0.0, (soma, d) => soma + d.valor),
      ),
    );
    double totalDespesas = somaPorCategoria.values.fold(0.0, (soma, valor) => soma + valor);

    return {
      'ganhosDoPeriodo': ganhosDoPeriodo,
      'kmRodadosPeriodo': kmRodadosPeriodo,
      'ganhoPorKm': ganhoPorKm,
      'ganhoPorCorrida': ganhoPorCorrida,
      'somaPorCategoria': somaPorCategoria,
      'totalDespesas': totalDespesas,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'semana', label: Text('Esta Semana'), icon: Icon(Icons.calendar_view_week)),
                ButtonSegment<String>(value: 'mes', label: Text('Este Mês'), icon: Icon(Icons.calendar_month)),
              ],
              selected: {_periodoSelecionado},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _periodoSelecionado = newSelection.first;
                  _carregarDados();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dadosDoPeriodoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum dado no período.'));
                }

                final dados = snapshot.data!;
                final double ganhosDoPeriodo = dados['ganhosDoPeriodo'];
                final double totalDespesas = dados['totalDespesas'];
                final Map<String, double> somaPorCategoria = dados['somaPorCategoria'];

                return RefreshIndicator(
                  onRefresh: () async => _carregarDados(),
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildMetricasCard(dados),
                      const SizedBox(height: 16),
                      _buildDespesasDetalhadasCard(somaPorCategoria, ganhosDoPeriodo, totalDespesas),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasCard(Map<String, dynamic> dados) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Métricas de Desempenho', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('🛣️ KM Rodados no Período:', AppFormatters.formatKm(dados['kmRodadosPeriodo'])),
            _buildInfoRow('📈 Ganhos por KM:', AppFormatters.formatCurrency(dados['ganhoPorKm'])),
            _buildInfoRow('🏁 Média por Corrida:', AppFormatters.formatCurrency(dados['ganhoPorCorrida'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDespesasDetalhadasCard(Map<String, double> somaPorCategoria, double ganhos, double totalDespesas) {
    final sortedEntries = somaPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo Financeiro', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('💰 Ganhos Brutos:', AppFormatters.formatCurrency(ganhos)),
            const Divider(),
            if (sortedEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Nenhuma despesa registrada no período.'),
              )
            else
              ...sortedEntries.map((entry) {
                return _buildInfoRow('💸 ${entry.key}:', AppFormatters.formatCurrency(entry.value), isNegative: true);
              }),
            const Divider(),
            _buildInfoRow(
                '✅ Lucro Líquido:',
                AppFormatters.formatCurrency(ganhos - totalDespesas),
                isHighlight: true,
                lucroValor: ganhos - totalDespesas
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isNegative = false, double? lucroValor}) {
    Color? textColor;
    FontWeight fontWeight = FontWeight.w500;

    if (isNegative) {
      textColor = Colors.redAccent;
    } else if (isHighlight) {
      fontWeight = FontWeight.bold;
      textColor = (lucroValor ?? 0) >= 0 ? Colors.green.shade800 : Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}