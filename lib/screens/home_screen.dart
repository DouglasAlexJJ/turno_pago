// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/despesa.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/historico_turnos_screen.dart';
import 'package:turno_pago/screens/manutencao_screen.dart';
import 'package:turno_pago/utils/app_formatters.dart';
import 'despesas_screen.dart';
import 'turno_screen.dart';
import '../services/dados_service.dart';
import '../services/veiculo_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _dadosDoDiaFuture;

  @override
  void initState() {
    super.initState();
    _dadosDoDiaFuture = _carregarDadosDoDia();
  }

  Future<Map<String, dynamic>> _carregarDadosDoDia() async {
    final hoje = DateTime.now();

    final results = await Future.wait([
      DadosService.getTurnos(),
      DadosService.getDespesas(),
      VeiculoService.getVeiculo(),
      DadosService.getManutencaoItens(),
    ]);

    final todosOsTurnos = results[0] as List<Turno>;
    final todasAsDespesas = results[1] as List<Despesa>;
    final veiculo = results[2] as Veiculo;
    final itensManutencao = results[3] as List<ManutencaoItem>;

    final turnosDeHoje = todosOsTurnos.where((t) => t.data.year == hoje.year && t.data.month == hoje.month && t.data.day == hoje.day).toList();
    final despesasDeHoje = todasAsDespesas.where((d) => d.data.year == hoje.year && d.data.month == hoje.month && d.data.day == hoje.day).toList();
    final custoManutencaoPorKm = itensManutencao.fold(0.0, (soma, item) => soma + item.custoPorKm);

    double ganhosBrutos = 0, kmRodados = 0, gastoCombustivel = 0, provisaoManutencao = 0;
    for (final turno in turnosDeHoje) {
      ganhosBrutos += turno.ganhos;
      kmRodados += turno.kmRodados;
      if (veiculo.consumoMedio > 0) {
        gastoCombustivel += (turno.kmRodados / veiculo.consumoMedio) * turno.precoCombustivel;
      }
      provisaoManutencao += turno.kmRodados * custoManutencaoPorKm;
    }
    final totalDespesas = despesasDeHoje.fold(0.0, (soma, despesa) => soma + despesa.valor);

    // LÓGICA CORRIGIDA: Gasto com combustível não é mais subtraído aqui
    final lucroLiquido = ganhosBrutos - totalDespesas - provisaoManutencao;

    final double valorReserva = (lucroLiquido > 0) ? lucroLiquido * (veiculo.percentualReserva / 100) : 0;
    final double lucroFinal = lucroLiquido - valorReserva;
    final reaisPorKm = (kmRodados > 0) ? ganhosBrutos / kmRodados : 0.0;

    final List<ManutencaoItem> itensVencidos = itensManutencao.where((item) {
      final kmRestantes = item.proximaTrocaKm - veiculo.kmAtual;
      return kmRestantes <= 0;
    }).toList();

    return {
      'ganhosBrutos': ganhosBrutos,
      'kmRodados': kmRodados,
      'despesas': totalDespesas,
      'gastoCombustivel': gastoCombustivel, // Mantém para exibição
      'provisaoManutencao': provisaoManutencao,
      'lucroLiquido': lucroLiquido,
      'valorReserva': valorReserva,
      'lucroFinal': lucroFinal,
      'reaisPorKm': reaisPorKm,
      'itensVencidos': itensVencidos,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _dadosDoDiaFuture = _carregarDadosDoDia();
          });
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dadosDoDiaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Nenhum dado encontrado.'));
            }

            final dados = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildResumoDoDiaCard(dados),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Gerenciar Despesas'),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await navigator.push(MaterialPageRoute(builder: (_) => const DespesasScreen()));
                      setState(() { _dadosDoDiaFuture = _carregarDadosDoDia(); });
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Ver Histórico de Turnos'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoricoTurnosScreen()));
                    },
                  )
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          final result = await navigator.push(
            MaterialPageRoute(builder: (_) => const TurnoScreen()),
          );

          if (result != true) return;

          scaffoldMessenger.showSnackBar(const SnackBar(
            content: Text("Salvando e verificando manutenções..."),
            duration: Duration(seconds: 1),
          ));

          final novosDados = await _carregarDadosDoDia();

          if (!mounted) return;

          setState(() {
            _dadosDoDiaFuture = Future.value(novosDados);
          });

          final List<ManutencaoItem> itensVencidos = novosDados['itensVencidos'];

          if (itensVencidos.isNotEmpty) {
            showDialog(
                context: navigator.context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      SizedBox(width: 10),
                      Text('Alerta de Manutenção'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'Os seguintes itens estão com a manutenção vencida:'),
                      const SizedBox(height: 10),
                      ...itensVencidos.map((item) => Text('• ${item.nome}',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        navigator.push(MaterialPageRoute(
                            builder: (_) => const ManutencaoScreen()));
                      },
                      child: const Text('Ver Manutenções'),
                    ),
                  ],
                ));
          }
        },
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildResumoDoDiaCard(Map<String, dynamic> dados) {
    final double ganhosBrutos = dados['ganhosBrutos'];
    final double despesas = dados['despesas'];
    final double gastoCombustivel = dados['gastoCombustivel'];
    final double provisaoManutencao = dados['provisaoManutencao'];
    final double valorReserva = dados['valorReserva'];
    final double lucroFinal = dados['lucroFinal'];
    final double kmRodados = dados['kmRodados'];
    final double reaisPorKm = dados['reaisPorKm'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo Financeiro do Dia', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow('💰 Ganhos Brutos', AppFormatters.formatCurrency(ganhosBrutos)),
            const Divider(height: 20),
            Text('Custos e Provisões do Dia:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildInfoRow('💸 Despesas', AppFormatters.formatCurrency(despesas), isNegative: true),
            _buildInfoRow('🛠️ Provisão Manutenção', AppFormatters.formatCurrency(provisaoManutencao), isNegative: true),
            _buildInfoRow('🚨 Reserva de Emergência', AppFormatters.formatCurrency(valorReserva), isNegative: true, negativeColor: Colors.orange.shade800),
            const Divider(height: 20),
            _buildInfoRow('✅ Lucro Final (no bolso)', AppFormatters.formatCurrency(lucroFinal), isHighlight: true, lucroValor: lucroFinal),
            const SizedBox(height: 10),
            const Divider(height: 20),
            // LINHA DE COMBUSTÍVEL ALTERADA
            _buildInfoRow('⛽ Combustível Gasto (Estimado)', AppFormatters.formatCurrency(gastoCombustivel), isInformational: true),
            _buildInfoRow('🛣️ KM Rodados no Dia', AppFormatters.formatKm(kmRodados), isInformational: true),
            _buildInfoRow('📈 R\$ por KM Rodado', AppFormatters.formatCurrency(reaisPorKm), isInformational: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isNegative = false, bool isInformational = false, double? lucroValor, Color? negativeColor}) {
    Color? textColor;
    FontWeight fontWeight = FontWeight.w500;

    if (isNegative) {
      textColor = negativeColor ?? Colors.redAccent;
    } else if (isHighlight) {
      fontWeight = FontWeight.bold;
      textColor = (lucroValor ?? 0) >= 0 ? Colors.green.shade800 : Colors.redAccent;
    } else if (isInformational) {
      textColor = Colors.blueGrey.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: fontWeight, color: textColor),
          ),
        ],
      ),
    );
  }
}