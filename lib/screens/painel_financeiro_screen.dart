// lib/screens/painel_financeiro_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turno_pago/models/despesa.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/manutencao_screen.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';
import 'package:collection/collection.dart'; // Import para agrupar dados

class PainelFinanceiroScreen extends StatefulWidget {
  const PainelFinanceiroScreen({super.key});

  @override
  State<PainelFinanceiroScreen> createState() => _PainelFinanceiroScreenState();
}

class _PainelFinanceiroScreenState extends State<PainelFinanceiroScreen> {
  late Future<Map<String, dynamic>> _dadosPainelFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _dadosPainelFuture = _processarDadosDoPainel();
    });
  }

  Future<Map<String, dynamic>> _processarDadosDoPainel() async {
    final results = await Future.wait([
      DadosService.getTurnos(),
      VeiculoService.getVeiculo(),
      DadosService.getManutencaoItens(),
      DadosService.getDespesas(),
    ]);

    final todosOsTurnos = results[0] as List<Turno>;
    final veiculoData = results[1] as Veiculo;
    final manutencaoData = results[2] as List<ManutencaoItem>;
    final todasAsDespesas = results[3] as List<Despesa>;

    // LÓGICA ATUALIZADA PARA O COFRINHO
    double totalProvisaoManutencao = 0;
    double totalReservaEmergencia = 0;
    final custoManutencaoPorKm = manutencaoData.fold(0.0, (soma, item) => soma + item.custoPorKm);

    // Calcula a provisão de manutenção total (baseada em todos os KMs rodados)
    for (final turno in todosOsTurnos) {
      totalProvisaoManutencao += turno.kmRodados * custoManutencaoPorKm;
    }

    // Agrupa turnos e despesas por dia para calcular o lucro diário e a reserva
    final turnosPorDia = groupBy(todosOsTurnos, (Turno t) => DateFormat('yyyy-MM-dd').format(t.data));
    final despesasPorDia = groupBy(todasAsDespesas, (Despesa d) => DateFormat('yyyy-MM-dd').format(d.data));

    turnosPorDia.forEach((dia, turnosDoDia) {
      double ganhosBrutosDia = turnosDoDia.fold(0, (sum, t) => sum + t.ganhos);
      double kmRodadosDia = turnosDoDia.fold(0, (sum, t) => sum + t.kmRodados);
      double gastoCombustivelDia = 0;
      if (veiculoData.consumoMedio > 0) {
        gastoCombustivelDia = turnosDoDia.fold(0, (sum, t) => sum + ((t.kmRodados / veiculoData.consumoMedio) * t.precoCombustivel));
      }
      double provisaoManutencaoDia = kmRodadosDia * custoManutencaoPorKm;
      double despesasDoDiaValor = (despesasPorDia[dia] ?? []).fold(0, (sum, d) => sum + d.valor);

      double lucroLiquidoDia = ganhosBrutosDia - despesasDoDiaValor - gastoCombustivelDia - provisaoManutencaoDia;

      if (lucroLiquidoDia > 0) {
        totalReservaEmergencia += lucroLiquidoDia * (veiculoData.percentualReserva / 100);
      }
    });

    manutencaoData.sort((a, b) {
      final kmRestantesA = a.proximaTrocaKm - veiculoData.kmAtual;
      final kmRestantesB = b.proximaTrocaKm - veiculoData.kmAtual;
      return kmRestantesA.compareTo(kmRestantesB);
    });

    return {
      'veiculo': veiculoData,
      'itensManutencao': manutencaoData,
      'totalProvisaoManutencao': totalProvisaoManutencao,
      'totalReservaEmergencia': totalReservaEmergencia,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dadosPainelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado.'));
          }

          final dados = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _carregarDados(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildCofrinhoCard(dados),
                const SizedBox(height: 16),
                _buildMonitorManutencaoCard(
                    dados['veiculo'], dados['itensManutencao']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCofrinhoCard(Map<String, dynamic> dados) {
    final double totalManutencao = dados['totalProvisaoManutencao'];
    final double totalReserva = dados['totalReservaEmergencia']; // NOVO VALOR
    final double totalGuardado = totalManutencao + totalReserva;

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🐖 Cofrinho de Provisões', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue.shade800)),
            const SizedBox(height: 4),
            Text('Total que você deveria ter guardado para o futuro.', style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 20),
            _buildInfoRow('🛠️ Para Manutenção:', AppFormatters.formatCurrency(totalManutencao)),
            _buildInfoRow('🚨 Para Reserva de Emergência:', AppFormatters.formatCurrency(totalReserva)), // TEXTO ATUALIZADO
            const Divider(height: 20),
            _buildInfoRow('💰 Total Guardado:', AppFormatters.formatCurrency(totalGuardado), isHighlight: true, highlightColor: Colors.blue.shade900),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorManutencaoCard(
      Veiculo veiculo, List<ManutencaoItem> itens) {
    final kmAtual = veiculo.kmAtual;
    final itensCriticos = itens.take(3).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitor de Manutenção',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (itensCriticos.isEmpty)
              const Center(child: Text('Nenhum item de manutenção configurado.'))
            else
              ...itensCriticos.map((item) {
                final kmRestantes = item.proximaTrocaKm - kmAtual;
                final vencido = kmRestantes <= 0;
                final proximo =
                    !vencido && kmRestantes < (item.vidaUtilKm * 0.1);
                Color statusColor = vencido
                    ? Colors.red.shade700
                    : (proximo ? Colors.amber.shade700 : Colors.green.shade700);
                String statusText = vencido
                    ? '${-kmRestantes} KM VENCIDO'
                    : 'Faltam $kmRestantes KM';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.nome, style: const TextStyle(fontSize: 16)),
                      Text(
                        statusText,
                        style: TextStyle(
                            color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            if (itensCriticos.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ManutencaoScreen()),
                    ).then((_) => _carregarDados());
                  },
                  child: const Text('Ver Detalhes'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isHighlight = false, Color? highlightColor}) {
    Color? textColor;
    FontWeight fontWeight = FontWeight.w500;

    if (isHighlight) {
      fontWeight = FontWeight.bold;
      textColor = highlightColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
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