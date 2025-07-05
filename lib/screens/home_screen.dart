// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/turno.dart';
import '../services/dados_service.dart';
import 'despesas_screen.dart';
import 'turno_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // Variáveis para o resumo do último turno
  Turno? ultimoTurno;

  // Variáveis para o resumo do dia
  double ganhosDoDia = 0;
  double totalDespesasDoDia = 0;
  double _custoProvisionadoTurno = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    // --- LÓGICA DE CÁLCULO DE PROVISIONAMENTO ---
    final prefs = await SharedPreferences.getInstance();
    final itensManutencao = await DadosService.getManutencaoItens();
    final custoManutencaoPorKm = itensManutencao.fold(0.0, (soma, item) => soma + item.custoPorKm);
    final valorCarro = prefs.getDouble('carro_valor') ?? 0;
    final vidaUtilKm = prefs.getInt('carro_vida_util_km') ?? 0;
    final custoDepreciacaoPorKm = (vidaUtilKm > 0) ? valorCarro / vidaUtilKm : 0.0;
    final custoTotalPorKm = custoManutencaoPorKm + custoDepreciacaoPorKm;

    // --- LÓGICA DE DADOS DO DIA E DO TURNO ---
    final todosOsTurnos = await DadosService.getTurnos();
    final todasAsDespesas = await DadosService.getDespesas();
    final hoje = DateTime.now();

    final turnosDeHoje = todosOsTurnos.where((t) =>
    t.data.year == hoje.year && t.data.month == hoje.month && t.data.day == hoje.day);
    final despesasDeHoje = todasAsDespesas.where((d) =>
    d.data.year == hoje.year && d.data.month == hoje.month && d.data.day == hoje.day);

    final double somaGanhos = turnosDeHoje.fold(0.0, (soma, turno) => soma + turno.ganhos);
    final double somaDespesas = despesasDeHoje.fold(0.0, (soma, despesa) => soma + despesa.valor);

    Turno? turnoMaisRecente;
    if (todosOsTurnos.isNotEmpty) {
      todosOsTurnos.sort((a, b) => b.data.compareTo(a.data));
      turnoMaisRecente = todosOsTurnos.first;
    }

    // Calcula o valor final a ser provisionado com base no último turno
    final double valorProvisaoFinal = (turnoMaisRecente?.kmRodados ?? 0) * custoTotalPorKm;

    if (!mounted) return;

    setState(() {
      ultimoTurno = turnoMaisRecente;
      ganhosDoDia = somaGanhos;
      totalDespesasDoDia = somaDespesas;
      _custoProvisionadoTurno = valorProvisaoFinal; // Atribuição direta
    });
  }

  @override
  Widget build(BuildContext context) {
    final lucroDoDia = ganhosDoDia - totalDespesasDoDia;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _carregarDados,
          child: ListView(
            children: [
              _buildCard(
                title: 'Financeiro do Dia',
                children: [
                  _buildInfoRow('💰 Ganhos Brutos', 'R\$ ${ganhosDoDia.toStringAsFixed(2)}'),
                  _buildInfoRow('💸 Despesas Totais', 'R\$ ${totalDespesasDoDia.toStringAsFixed(2)}', isNegative: true),
                  const Divider(),
                  _buildInfoRow('✅ Lucro Líquido', 'R\$ ${lucroDoDia.toStringAsFixed(2)}', isHighlight: true),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Métricas do Último Turno',
                children: ultimoTurno != null
                    ? _buildMetricasTurno(ultimoTurno!)
                    : [const Text('Nenhum turno registrado ainda.')],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text('Gerenciar Despesas'),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DespesasScreen()),
                  );
                  _carregarDados();
                },
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: '💰 Cofrinho do Veículo',
                children: [
                  const Text(
                    'Valor a separar do último turno para cobrir custos futuros do veículo:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'R\$ ${_custoProvisionadoTurno.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TurnoScreen()),
          );
          if (result == true) {
            _carregarDados();
          }
        },
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  // Helper para construir as métricas do turno e evitar repetição de código
  List<Widget> _buildMetricasTurno(Turno turno) {
    final ganhoPorKm = turno.kmRodados > 0 ? turno.ganhos / turno.kmRodados : 0.0;
    final ganhoPorCorrida = turno.plataforma == '99' && turno.corridas > 0 ? turno.ganhos / turno.corridas : 0.0;

    return [
      _buildInfoRow('🗂 Plataforma', turno.plataforma == '99' ? '99' : 'Outro App'),
      _buildInfoRow('🛣 KM Rodados', '${turno.kmRodados.toStringAsFixed(1)} km'),
      _buildInfoRow('📊 Ganho por KM', 'R\$ ${ganhoPorKm.toStringAsFixed(2)}'),
      if (turno.plataforma == '99') ...[
        _buildInfoRow('🚗 Corridas Feitas', '${turno.corridas}'),
        _buildInfoRow('📦 Ganho por Corrida', 'R\$ ${ganhoPorCorrida.toStringAsFixed(2)}'),
      ]
    ];
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isNegative = false}) {
    Color? textColor;
    if (isNegative) {
      textColor = Colors.redAccent;
    } else if (isHighlight) {
      final lucro = double.tryParse(value.replaceAll('R\$ ', '')) ?? 0;
      textColor = lucro >= 0 ? Colors.green : Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}