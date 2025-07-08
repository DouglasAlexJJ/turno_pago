// lib/screens/painel_financeiro_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/despesa.dart'; // IMPORT ADICIONADO
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/manutencao_screen.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';

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
    _dadosPainelFuture = _carregarDadosDoPainel();
  }

  Future<Map<String, dynamic>> _carregarDadosDoPainel() async {
    final results = await Future.wait([
      DadosService.getTurnos(),
      VeiculoService.getVeiculo(),
      DadosService.getManutencaoItens(),
      DadosService.getDespesas(),
    ]);

    final turnosData = results[0] as List<Turno>;
    final veiculoData = results[1] as Veiculo;
    final manutencaoData = results[2] as List<ManutencaoItem>;
    final despesasData = results[3] as List<Despesa>;

    manutencaoData.sort((a, b) {
      final kmRestantesA = a.proximaTrocaKm - veiculoData.kmAtual;
      final kmRestantesB = b.proximaTrocaKm - veiculoData.kmAtual;
      return kmRestantesA.compareTo(kmRestantesB);
    });

    double ganhoTotal = turnosData.fold(0.0, (soma, t) => soma + t.ganhos);
    double despesasTotal = despesasData.fold(0.0, (soma, d) => soma + d.valor);

    return {
      'veiculo': veiculoData,
      'itensManutencao': manutencaoData,
      'ganhoTotal': ganhoTotal,
      'despesasTotal': despesasTotal,
    };
  }

  void _recarregar() {
    setState(() {
      _dadosPainelFuture = _carregarDadosDoPainel();
    });
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
            onRefresh: () async => _recarregar(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildResumoGeralCard(dados),
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

  Widget _buildResumoGeralCard(Map<String, dynamic> dados) {
    final double ganhoTotal = dados['ganhoTotal'];
    final double despesasTotal = dados['despesasTotal'];
    final lucroLiquido = ganhoTotal - despesasTotal;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financeiro Geral (Todos os Tempos)',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('💰 Ganhos Brutos Totais:',
                AppFormatters.formatCurrency(ganhoTotal)),
            _buildInfoRow('💸 Despesas Totais:',
                AppFormatters.formatCurrency(despesasTotal), isNegative: true),
            const Divider(),
            _buildInfoRow('✅ Lucro Líquido Total:',
                AppFormatters.formatCurrency(lucroLiquido),
                isHighlight: true, lucroValor: lucroLiquido),
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
              const Center(
                  child: Text('Nenhum item de manutenção configurado.'))
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
                    ).then((_) => _recarregar());
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
      {bool isHighlight = false, bool isNegative = false, double? lucroValor}) {
    Color? textColor;
    FontWeight fontWeight = FontWeight.w500;

    if (isNegative) {
      textColor = Colors.redAccent;
    } else if (isHighlight) {
      fontWeight = FontWeight.bold;
      textColor =
      (lucroValor ?? 0) >= 0 ? Colors.green.shade800 : Colors.redAccent;
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