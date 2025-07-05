import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RelatoriosScreen extends StatelessWidget {
  RelatoriosScreen({super.key}); // Removido o 'const'

  final List<double> ganhosSemana = [220, 250, 190, 275, 300, 280, 310];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('📈 Ganhos nos últimos 7 dias', style: TextStyle(fontSize: 16)),
            SizedBox(height: 200, child: _buildBarChart()),
            const SizedBox(height: 20),
            Text('💰 Total: R\$ ${ganhosSemana.reduce((a, b) => a + b).toStringAsFixed(2)}'),
            Text('🧠 Média diária: R\$ ${(ganhosSemana.reduce((a, b) => a + b) / 7).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const dias = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
                return Text(dias[value.toInt()]);
              },
            ),
          ),
        ),
        barGroups: ganhosSemana.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Colors.greenAccent,
                width: 16,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
