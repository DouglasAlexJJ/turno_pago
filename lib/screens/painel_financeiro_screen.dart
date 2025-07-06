// lib/screens/painel_financeiro_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/utils/app_formatters.dart'; // Importa nosso formatador
import '../models/despesa.dart';
import '../models/turno.dart';
import '../services/dados_service.dart';
import 'historico_turnos_screen.dart';

class PainelFinanceiroScreen extends StatefulWidget {
  const PainelFinanceiroScreen({super.key});

  @override
  State<PainelFinanceiroScreen> createState() => _PainelFinanceiroScreenState();
}

class _PainelFinanceiroScreenState extends State<PainelFinanceiroScreen> {
  String _periodoSelecionado = 'semana';
  double _ganhosPeriodo = 0;
  double _despesasPeriodo = 0;
  double _lucroPeriodo = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calcularTotais();
  }

  Future<void> _calcularTotais() async {
    setState(() => _isLoading = true);

    final turnos = await DadosService.getTurnos();
    final despesas = await DadosService.getDespesas();
    final agora = DateTime.now();

    List<Turno> turnosFiltrados;
    List<Despesa> despesasFiltradas;

    if (_periodoSelecionado == 'semana') {
      final inicioDaSemana = agora.subtract(Duration(days: agora.weekday - 1));
      turnosFiltrados = turnos.where((t) => t.data.isAfter(inicioDaSemana)).toList();
      despesasFiltradas = despesas.where((d) => d.data.isAfter(inicioDaSemana)).toList();
    } else { // Mês
      turnosFiltrados = turnos.where((t) => t.data.month == agora.month && t.data.year == agora.year).toList();
      despesasFiltradas = despesas.where((d) => d.data.month == agora.month && d.data.year == agora.year).toList();
    }

    final ganhos = turnosFiltrados.fold(0.0, (s, t) => s + t.ganhos);
    final gastos = despesasFiltradas.fold(0.0, (s, d) => s + d.valor);

    setState(() {
      _ganhosPeriodo = ganhos;
      _despesasPeriodo = gastos;
      _lucroPeriodo = ganhos - gastos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A AppBar foi removida daqui e está na MainScreen
      body: RefreshIndicator(
        onRefresh: _calcularTotais,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'semana', label: Text('Esta Semana')),
                  ButtonSegment<String>(value: 'mes', label: Text('Este Mês')),
                ],
                selected: {_periodoSelecionado},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _periodoSelecionado = newSelection.first;
                    _calcularTotais();
                  });
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPainelResumo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPainelResumo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Resumo do Período',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('💰 Ganhos Brutos', AppFormatters.formatCurrency(_ganhosPeriodo)),
            const SizedBox(height: 8),
            _buildInfoRow('💸 Despesas Totais', AppFormatters.formatCurrency(_despesasPeriodo), isNegative: true),
            const Divider(height: 24),
            _buildInfoRow('✅ Lucro Líquido', AppFormatters.formatCurrency(_lucroPeriodo), isHighlight: true),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Ver Histórico de Turnos'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoricoTurnosScreen()),
                );
              },
            ),
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
      final cleanValue = value.replaceAll(RegExp(r'[R$\s.]'), '').replaceAll(',', '.');
      final lucro = double.tryParse(cleanValue) ?? 0;
      textColor = lucro >= 0 ? Colors.green.shade700 : Colors.redAccent;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}