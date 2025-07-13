// lib/screens/monitor_screen.dart

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

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late Future<Map<String, dynamic>> _dadosMonitorFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _dadosMonitorFuture = _processarDadosDoMonitor();
    });
  }

  Future<Map<String, dynamic>> _processarDadosDoMonitor() async {
    final results = await Future.wait([
      DadosService.getTurnos(),
      VeiculoService().getVeiculo(),
      DadosService.getManutencaoItens(),
      DadosService.getDespesas(),
    ]);

    final todosOsTurnos = results[0] as List<Turno>;
    final veiculoData = results[1] as Veiculo;
    final manutencaoData = results[2] as List<ManutencaoItem>;
    final todasAsDespesas = results[3] as List<Despesa>;

    double totalProvisaoManutencao = 0;
    double totalReservaEmergencia = 0;
    double totalProvisaoAluguel = 0;

    // Identifica os dias únicos em que houve trabalho
    final diasTrabalhadosUnicos = todosOsTurnos.map((t) => DateFormat('yyyy-MM-dd').format(t.data)).toSet();

    // Calcula a provisão de aluguel para os dias trabalhados
    if (veiculoData.tipoVeiculo == TipoVeiculo.alugado) {
      totalProvisaoAluguel = diasTrabalhadosUnicos.length * veiculoData.provisaoDiariaAluguel;
    }

    // Calcula a provisão de manutenção apenas para veículo próprio
    if (veiculoData.tipoVeiculo == TipoVeiculo.proprio) {
      final custoManutencaoPorKm = manutencaoData.fold(0.0, (soma, item) => soma + item.custoPorKm);
      for (final turno in todosOsTurnos) {
        totalProvisaoManutencao += turno.kmRodados * custoManutencaoPorKm;
      }
    }

    // Lógica para calcular a reserva de emergência acumulada
    for (final dia in diasTrabalhadosUnicos) {
      final turnosDoDia = todosOsTurnos.where((t) => DateFormat('yyyy-MM-dd').format(t.data) == dia);
      final despesasDoDia = todasAsDespesas.where((d) => DateFormat('yyyy-MM-dd').format(d.data) == dia);

      double ganhosBrutosDia = turnosDoDia.fold(0.0, (sum, t) => sum + t.ganhos);
      double despesasDoDiaValor = despesasDoDia.fold(0.0, (sum, d) => sum + d.valor);

      double custoDoDia = despesasDoDiaValor;
      if (veiculoData.tipoVeiculo == TipoVeiculo.proprio) {
        final custoManutencaoPorKm = manutencaoData.fold(0.0, (soma, item) => soma + item.custoPorKm);
        final kmDoDia = turnosDoDia.fold(0.0, (soma, t) => soma + t.kmRodados);
        custoDoDia += kmDoDia * custoManutencaoPorKm;
      } else {
        custoDoDia += veiculoData.provisaoDiariaAluguel;
      }

      double lucroLiquidoDia = ganhosBrutosDia - custoDoDia;

      if (lucroLiquidoDia > 0) {
        totalReservaEmergencia += lucroLiquidoDia * (veiculoData.percentualReserva / 100);
      }
    }

    manutencaoData.sort((a, b) {
      final kmRestantesA = a.proximaTrocaKm - veiculoData.kmAtual;
      final kmRestantesB = b.proximaTrocaKm - veiculoData.kmAtual;
      return kmRestantesA.compareTo(kmRestantesB);
    });

    return {
      'veiculo': veiculoData,
      'itensManutencao': manutencaoData,
      'totalProvisaoManutencao': totalProvisaoManutencao,
      'totalProvisaoAluguel': totalProvisaoAluguel,
      'totalReservaEmergencia': totalReservaEmergencia,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dadosMonitorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nenhum dado para exibir.'));
          }

          final dados = snapshot.data!;
          final Veiculo veiculo = dados['veiculo'];

          return RefreshIndicator(
            onRefresh: () async => _carregarDados(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildCofrinhoCard(dados),
                const SizedBox(height: 16),

                if (veiculo.tipoVeiculo == TipoVeiculo.proprio)
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
    final Veiculo veiculo = dados['veiculo'];
    final double totalManutencao = dados['totalProvisaoManutencao'];
    final double totalAluguel = dados['totalProvisaoAluguel'];
    final double totalReserva = dados['totalReservaEmergencia'];

    final double totalGuardado = totalManutencao + totalAluguel + totalReserva;

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

            if (veiculo.tipoVeiculo == TipoVeiculo.proprio)
              _buildInfoRow('🛠️ Para Manutenção:', AppFormatters.formatCurrency(totalManutencao)),

            if (veiculo.tipoVeiculo == TipoVeiculo.alugado)
              _buildInfoRow('🔑 Para Aluguel:', AppFormatters.formatCurrency(totalAluguel)),

            _buildInfoRow('🚨 Para Reserva de Emergência:', AppFormatters.formatCurrency(totalReserva)),
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