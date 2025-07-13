// lib/screens/painel_financeiro_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/despesa.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';
import 'package:collection/collection.dart';
import 'package:turno_pago/screens/relatorios_screen.dart';

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

  // FUNÇÃO DE PROCESSAMENTO ATUALIZADA
  Future<Map<String, dynamic>> _processarDadosDoPeriodo() async {
    final veiculo = await VeiculoService().getVeiculo();
    final todosOsTurnos = await DadosService.getTurnos();
    final todasAsDespesas = await DadosService.getDespesas();
    final itensManutencao = await DadosService.getManutencaoItens();

    final agora = DateTime.now();
    DateTime inicioPeriodo;

    if (_periodoSelecionado == 'semana') {
      inicioPeriodo = agora.subtract(Duration(days: agora.weekday - 1));
    } else { // Mês
      inicioPeriodo = DateTime(agora.year, agora.month, 1);
    }
    inicioPeriodo = DateTime(inicioPeriodo.year, inicioPeriodo.month, inicioPeriodo.day);

    final turnosDoPeriodo = todosOsTurnos.where((t) => !t.data.isBefore(inicioPeriodo)).toList();
    final despesasDoPeriodo = todasAsDespesas.where((d) => !d.data.isBefore(inicioPeriodo)).toList();

    double ganhosDoPeriodo = turnosDoPeriodo.fold(0.0, (soma, t) => soma + t.ganhos);
    double kmRodadosPeriodo = turnosDoPeriodo.fold(0.0, (soma, t) => soma + t.kmRodados);
    int corridasPeriodo = turnosDoPeriodo.fold(0, (soma, t) => soma + t.corridas);
    // NOVO CÁLCULO: Soma a duração de todos os turnos
    int totalSegundosTrabalhados = turnosDoPeriodo.fold(0, (soma, t) => soma + t.duracaoEmSegundos);

    final ganhoPorKm = (kmRodadosPeriodo > 0) ? ganhosDoPeriodo / kmRodadosPeriodo : 0.0;
    final ganhoPorCorrida = (corridasPeriodo > 0) ? ganhosDoPeriodo / corridasPeriodo : 0.0;
    // NOVO CÁLCULO: Calcula o ganho por hora
    final ganhoPorHora = (totalSegundosTrabalhados > 0) ? (ganhosDoPeriodo / (totalSegundosTrabalhados / 3600)) : 0.0;

    final despesasAgrupadas = groupBy(despesasDoPeriodo, (Despesa d) => d.categoria);
    final Map<String, double> somaPorCategoria = despesasAgrupadas.map(
          (categoria, lista) => MapEntry(
        categoria,
        lista.fold(0.0, (soma, d) => soma + d.valor),
      ),
    );
    double totalDespesas = somaPorCategoria.values.fold(0.0, (soma, valor) => soma + valor);

    double custosVeiculoPeriodo = 0;
    if (veiculo.tipoVeiculo == TipoVeiculo.proprio) {
      final custoPorKm = itensManutencao.fold(0.0, (soma, item) => soma + item.custoPorKm);
      custosVeiculoPeriodo = kmRodadosPeriodo * custoPorKm;
    } else {
      final diasTrabalhados = turnosDoPeriodo.map((t) => DateTime(t.data.year, t.data.month, t.data.day)).toSet();
      custosVeiculoPeriodo = diasTrabalhados.length * veiculo.provisaoDiariaAluguel;
    }

    return {
      'totalSegundosTrabalhados': totalSegundosTrabalhados,
      'ganhoPorHora': ganhoPorHora,
      'ganhosDoPeriodo': ganhosDoPeriodo,
      'kmRodadosPeriodo': kmRodadosPeriodo,
      'ganhoPorKm': ganhoPorKm,
      'ganhoPorCorrida': ganhoPorCorrida,
      'somaPorCategoria': somaPorCategoria,
      'totalDespesas': totalDespesas,
      'custosVeiculoPeriodo': custosVeiculoPeriodo,
    };
  }

  // Função helper para formatar a duração
  String _formatarDuracao(int totalSegundos) {
    final duracao = Duration(seconds: totalSegundos);
    final horas = duracao.inHours;
    final minutos = duracao.inMinutes.remainder(60);
    return '${horas.toString().padLeft(2, '0')}h ${minutos.toString().padLeft(2, '0')}min';
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
                if (!snapshot.hasData || (snapshot.data!['ganhosDoPeriodo'] == 0 && snapshot.data!['totalDespesas'] == 0)) {
                  return const Center(child: Text('Nenhum dado no período.'));
                }

                final dados = snapshot.data!;
                final double ganhosDoPeriodo = dados['ganhosDoPeriodo'];
                final double totalDespesas = dados['totalDespesas'];
                final double custosVeiculo = dados['custosVeiculoPeriodo'];
                final Map<String, double> somaPorCategoria = dados['somaPorCategoria'];

                return RefreshIndicator(
                  onRefresh: () async => _carregarDados(),
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildMetricasCard(dados),
                      const SizedBox(height: 16),
                      _buildDespesasDetalhadasCard(somaPorCategoria, ganhosDoPeriodo, totalDespesas, custosVeiculo),
                      const SizedBox(height: 16), // Espaçamento
                      _buildCustosPorCategoriaCard(somaPorCategoria),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Ver Relatórios Detalhados'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RelatoriosScreen()),
                          );
                        },
                      ),
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

  // WIDGET DE MÉTRICAS ATUALIZADO
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
            // NOVA LINHA PARA HORAS TRABALHADAS
            _buildInfoRow('🕒 Horas Trabalhadas:', _formatarDuracao(dados['totalSegundosTrabalhados'])),
            _buildInfoRow('💰 Ganhos por Hora:', AppFormatters.formatCurrency(dados['ganhoPorHora'])),
            _buildInfoRow('🛣️ Ganhos por KM:', AppFormatters.formatCurrency(dados['ganhoPorKm'])),
            _buildInfoRow('🏁 Média por Corrida:', AppFormatters.formatCurrency(dados['ganhoPorCorrida'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDespesasDetalhadasCard(Map<String, double> somaPorCategoria, double ganhos, double totalDespesas, double custosVeiculo) {
    final sortedEntries = somaPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final double lucroLiquido = ganhos - totalDespesas - custosVeiculo;

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
            _buildInfoRow('🚗 Custos do Veículo:', AppFormatters.formatCurrency(custosVeiculo), isNegative: true),
            const Divider(),
            _buildInfoRow(
                '✅ Lucro Líquido:',
                AppFormatters.formatCurrency(lucroLiquido),
                isHighlight: true,
                lucroValor: lucroLiquido
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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54))),
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

  Widget _buildCustosPorCategoriaCard(Map<String, double> somaPorCategoria) {
    final double totalDespesas = somaPorCategoria.values.fold(0.0, (soma, valor) => soma + valor);
    final sortedEntries = somaPorCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink(); // Não mostra o card se não houver despesas
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Custos por Categoria', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final percentual = (totalDespesas > 0) ? (entry.value / totalDespesas) * 100 : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('💸 ${entry.key}:', style: const TextStyle(fontSize: 16)),
                    Text(
                      '${AppFormatters.formatCurrency(entry.value)} (${percentual.toStringAsFixed(1)}%)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            _buildInfoRow(
                'Total de Custos:',
                AppFormatters.formatCurrency(totalDespesas),
                isHighlight: true
            ),
          ],
        ),
      ),
    );
  }
}