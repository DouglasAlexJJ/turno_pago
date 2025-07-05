// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/turno.dart';
import '../services/dados_service.dart';
import 'despesas_screen.dart';
import 'turno_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    // Carrega todos os turnos e todas as despesas
    final todosOsTurnos = await DadosService.getTurnos();
    final todasAsDespesas = await DadosService.getDespesas();

    final hoje = DateTime.now();

    // Filtra para pegar os dados do dia atual
    final turnosDeHoje = todosOsTurnos.where((t) {
      return t.data.year == hoje.year && t.data.month == hoje.month && t.data.day == hoje.day;
    }).toList();

    final despesasDeHoje = todasAsDespesas.where((d) {
      return d.data.year == hoje.year && d.data.month == hoje.month && d.data.day == hoje.day;
    }).toList();

    // Calcula os totais do dia
    final double somaGanhos = turnosDeHoje.fold(0.0, (soma, turno) => soma + turno.ganhos);
    final double somaDespesas = despesasDeHoje.fold(0.0, (soma, despesa) => soma + despesa.valor);

    if (!mounted) return;

    setState(() {
      // Ordena os turnos por data para pegar o mais recente
      if (todosOsTurnos.isNotEmpty) {
        todosOsTurnos.sort((a, b) => b.data.compareTo(a.data));
        ultimoTurno = todosOsTurnos.first;
      } else {
        ultimoTurno = null;
      }

      ganhosDoDia = somaGanhos;
      totalDespesasDoDia = somaDespesas;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lucroDoDia = ganhosDoDia - totalDespesasDoDia;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumo')),
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
              )
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