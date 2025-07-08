// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/despesa.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/historico_turnos_screen.dart';
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
  late Future<Map<String, double>> _dadosDoDiaFuture;

  @override
  void initState() {
    super.initState();
    _dadosDoDiaFuture = _carregarDadosDoDia();
  }

  Future<Map<String, double>> _carregarDadosDoDia() async {
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

    final turnosDeHoje = todosOsTurnos
        .where((t) =>
    t.data.year == hoje.year &&
        t.data.month == hoje.month &&
        t.data.day == hoje.day)
        .toList();

    final despesasDeHoje = todasAsDespesas
        .where((d) =>
    d.data.year == hoje.year &&
        d.data.month == hoje.month &&
        d.data.day == hoje.day)
        .toList();

    final custoManutencaoPorKm =
    itensManutencao.fold(0.0, (soma, item) => soma + item.custoPorKm);
    final custoDepreciacaoPorKm = veiculo.depreciacaoPorKm;

    double ganhosBrutos = 0;
    double kmRodados = 0;
    double gastoCombustivel = 0;
    double provisaoManutencao = 0;
    double provisaoDepreciacao = 0;

    for (final turno in turnosDeHoje) {
      ganhosBrutos += turno.ganhos;
      kmRodados += turno.kmRodados;

      if (veiculo.consumoMedio > 0) {
        gastoCombustivel +=
            (turno.kmRodados / veiculo.consumoMedio) * turno.precoCombustivel;
      }
      provisaoManutencao += turno.kmRodados * custoManutencaoPorKm;
      provisaoDepreciacao += turno.kmRodados * custoDepreciacaoPorKm;
    }

    final totalDespesas =
    despesasDeHoje.fold(0.0, (soma, despesa) => soma + despesa.valor);

    final lucroLiquido = ganhosBrutos -
        totalDespesas -
        gastoCombustivel -
        provisaoManutencao -
        provisaoDepreciacao;

    final reaisPorKm = (kmRodados > 0) ? ganhosBrutos / kmRodados : 0.0;

    return {
      'ganhosBrutos': ganhosBrutos,
      'kmRodados': kmRodados,
      'despesas': totalDespesas,
      'gastoCombustivel': gastoCombustivel,
      'provisaoManutencao': provisaoManutencao,
      'provisaoDepreciacao': provisaoDepreciacao,
      'lucroLiquido': lucroLiquido,
      'reaisPorKm': reaisPorKm,
    };
  }

  void _recarregar() {
    setState(() {
      _dadosDoDiaFuture = _carregarDadosDoDia();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _recarregar(),
        child: FutureBuilder<Map<String, double>>(
          future: _dadosDoDiaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Erro ao carregar dados: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DespesasScreen()));
                      _recarregar();
                    },
                  ),
                  const SizedBox(height: 8),
                  // BOTÃO DE HISTÓRICO NO LOCAL CORRETO
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Ver Histórico de Turnos'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoricoTurnosScreen()));
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
          final result = await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const TurnoScreen()));
          if (result == true) {
            _recarregar();
          }
        },
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildResumoDoDiaCard(Map<String, double> dados) {
    final lucroLiquido = dados['lucroLiquido']!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo Financeiro do Dia',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('💰 Ganhos Brutos',
                AppFormatters.formatCurrency(dados['ganhosBrutos']!)),
            const Divider(height: 20),
            Text('Custos e Provisões do Dia:',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildInfoRow('💸 Despesas',
                AppFormatters.formatCurrency(dados['despesas']!),
                isNegative: true),
            _buildInfoRow('⛽ Gasto Combustível',
                AppFormatters.formatCurrency(dados['gastoCombustivel']!),
                isNegative: true),
            _buildInfoRow('🛠️ Provisão Manutenção',
                AppFormatters.formatCurrency(dados['provisaoManutencao']!),
                isNegative: true),
            _buildInfoRow('🚗 Provisão Troca Veículo',
                AppFormatters.formatCurrency(dados['provisaoDepreciacao']!),
                isNegative: true),
            const Divider(height: 20),
            _buildInfoRow('✅ Lucro Líquido', AppFormatters.formatCurrency(lucroLiquido),
                isHighlight: true, lucroValor: lucroLiquido),
            const SizedBox(height: 10),
            const Divider(height: 20),
            _buildInfoRow('🛣️ KM Rodados no Dia',
                AppFormatters.formatKm(dados['kmRodados']!),
                isInformational: true),
            _buildInfoRow('📈 R\$ por KM Rodado',
                AppFormatters.formatCurrency(dados['reaisPorKm']!),
                isInformational: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isHighlight = false,
        bool isNegative = false,
        bool isInformational = false,
        double? lucroValor}) {
    Color? textColor;
    FontWeight fontWeight = FontWeight.w500;

    if (isNegative) {
      textColor = Colors.redAccent;
    } else if (isHighlight) {
      fontWeight = FontWeight.bold;
      textColor =
      (lucroValor ?? 0) >= 0 ? Colors.green.shade800 : Colors.redAccent;
    } else if (isInformational) {
      textColor = Colors.blueGrey.shade700;
      fontWeight = FontWeight.bold;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}