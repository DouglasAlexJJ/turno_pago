// lib/screens/painel_financeiro_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/despesa.dart';
import '../models/turno.dart';
import '../services/dados_service.dart';

class PainelFinanceiroScreen extends StatefulWidget {
  const PainelFinanceiroScreen({super.key});

  @override
  State<PainelFinanceiroScreen> createState() => _PainelFinanceiroScreenState();
}

class _PainelFinanceiroScreenState extends State<PainelFinanceiroScreen> {
  String _periodoSelecionado = 'semana'; // 'semana' ou 'mes'
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
    setState(() {
      _isLoading = true;
    });

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
      appBar: AppBar(
        title: const Text('Painel Financeiro'),
        actions: [
          // Adiciona um botão para recarregar os dados manualmente
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calcularTotais,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Seletor de período
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'semana', label: Text('Semana')),
                ButtonSegment<String>(value: 'mes', label: Text('Mês')),
              ],
              selected: {_periodoSelecionado},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _periodoSelecionado = newSelection.first;
                  _calcularTotais();
                });
              },
            ),
            const SizedBox(height: 24),
            // Exibição dos dados
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPainelResumo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPainelResumo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('💰 Ganhos Brutos', 'R\$ ${_ganhosPeriodo.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildInfoRow('💸 Despesas Totais', 'R\$ ${_despesasPeriodo.toStringAsFixed(2)}', isNegative: true),
            const Divider(height: 24),
            _buildInfoRow('✅ Lucro Líquido', 'R\$ ${_lucroPeriodo.toStringAsFixed(2)}', isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isNegative = false}) {
    final textTheme = Theme.of(context).textTheme;
    Color? textColor;
    if (isNegative) {
      textColor = Colors.redAccent;
    } else if (isHighlight) {
      textColor = _lucroPeriodo >= 0 ? Colors.green : Colors.redAccent;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.titleMedium),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
        ),
      ],
    );
  }
}