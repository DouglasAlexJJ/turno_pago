// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/utils/app_formatters.dart';
import 'despesas_screen.dart';
import 'turno_screen.dart';
import '../services/dados_service.dart';
import 'historico_turnos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Turno? ultimoTurno;
  double ganhosDoDia = 0;
  double totalDespesasDoDia = 0;
  double custoLavagemHoje = 0; // NOVA VARIÁVEL

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final todosOsTurnos = await DadosService.getTurnos();
    final todasAsDespesas = await DadosService.getDespesas();
    final hoje = DateTime.now();

    // --- LÓGICA DE CÁLCULO DA LAVAGEM (NOVA) ---
    double custoLavagem = 0;
    final tipoFrequencia = prefs.getString('lavagem_frequencia_tipo') ?? 'semanal';
    final custo = prefs.getDouble('lavagem_custo') ?? 0;
    final dataUltimaLavagemStr = prefs.getString('lavagem_data_ultima');
    final dataUltimaLavagem = dataUltimaLavagemStr != null ? DateTime.parse(dataUltimaLavagemStr) : hoje;

    bool hojeELavagem = false;
    if (tipoFrequencia == 'semanal') {
      final diaSemanaLavagem = prefs.getInt('lavagem_dia_semana') ?? 1;
      if (hoje.weekday == diaSemanaLavagem) {
        hojeELavagem = true;
      }
    } else { // Periódica
      final intervalo = prefs.getInt('lavagem_intervalo_dias') ?? 7;
      if (hoje.difference(dataUltimaLavagem).inDays >= intervalo) {
        hojeELavagem = true;
      }
    }

    if (hojeELavagem) {
      custoLavagem = custo;
    }
    // --- FIM DA LÓGICA DA LAVAGEM ---


    final turnosDeHoje = todosOsTurnos.where((t) =>
    t.data.year == hoje.year && t.data.month == hoje.month && t.data.day == hoje.day);
    final despesasDeHoje = todasAsDespesas.where((d) =>
    d.data.year == hoje.year && d.data.month == hoje.month && d.data.day == hoje.day);

    final double somaGanhos = turnosDeHoje.fold(0.0, (soma, turno) => soma + turno.ganhos);
    // Adiciona o custo da lavagem às despesas do dia
    final double somaDespesas = despesasDeHoje.fold(0.0, (soma, despesa) => soma + despesa.valor) + custoLavagem;

    Turno? turnoMaisRecente;
    if (todosOsTurnos.isNotEmpty) {
      todosOsTurnos.sort((a, b) => b.data.compareTo(a.data));
      turnoMaisRecente = todosOsTurnos.first;
    }

    if (!mounted) return;

    setState(() {
      ultimoTurno = turnoMaisRecente;
      ganhosDoDia = somaGanhos;
      totalDespesasDoDia = somaDespesas;
      custoLavagemHoje = custoLavagem; // Salva o custo para usar no card do turno
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildInfoRow('💰 Ganhos Brutos (Dia)', AppFormatters.formatCurrency(ganhosDoDia)),
                  _buildInfoRow('💸 Despesas (Dia)', AppFormatters.formatCurrency(totalDespesasDoDia), isNegative: true),
                  const Divider(),
                  _buildInfoRow('✅ Lucro Líquido (Dia)', AppFormatters.formatCurrency(ganhosDoDia - totalDespesasDoDia), isHighlight: true),
                ],
              ),
              const SizedBox(height: 16),

              if (ultimoTurno == null)
                const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Nenhum turno registrado ainda. Adicione um no botão '+'.")))
              else
                InkWell(
                  onTap: () {
                    // Ação de navegação ao clicar
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoricoTurnosScreen()),
                    );
                  },
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _getDadosDeCusto(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Mostra um card com loading para não quebrar o layout
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox.shrink();
                      }

                      final custos = snapshot.data!;
                      // O _buildAnaliseTurnoCard continua o mesmo
                      return _buildAnaliseTurnoCard(
                        turno: ultimoTurno!,
                        custoManutencaoPorKm: custos['custoManutencao']!,
                        custoDepreciacaoPorKm: custos['custoDepreciacao']!,
                        consumoMedio: custos['consumoMedio']!,
                        custoLavagem: custoLavagemHoje,
                      );
                    },
                  ),
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

  Future<Map<String, double>> _getDadosDeCusto() async {
    final prefs = await SharedPreferences.getInstance();
    final itensManutencao = await DadosService.getManutencaoItens();

    final custoManutencaoPorKm = itensManutencao.fold(0.0, (soma, item) => soma + item.custoPorKm);

    final valorCarro = prefs.getDouble('carro_valor') ?? 0;
    final vidaUtilKm = prefs.getInt('carro_vida_util_km') ?? 0;
    final custoDepreciacaoPorKm = (vidaUtilKm > 0) ? valorCarro / vidaUtilKm : 0.0;

    final consumo = prefs.getDouble('veiculo_consumo_medio') ?? 10.0;

    return {
      'custoManutencao': custoManutencaoPorKm,
      'custoDepreciacao': custoDepreciacaoPorKm,
      'consumoMedio': consumo,
    };
  }

  Widget _buildAnaliseTurnoCard({
    required Turno turno,
    required double custoManutencaoPorKm,
    required double custoDepreciacaoPorKm,
    required double consumoMedio,
    required double custoLavagem, // Recebe o custo da lavagem
  }) {
    final gastoCombustivel = (consumoMedio > 0)
        ? (turno.kmRodados / consumoMedio) * turno.precoCombustivel
        : 0.0;

    final provisaoManutencao = turno.kmRodados * custoManutencaoPorKm;
    final provisaoDepreciacao = turno.kmRodados * custoDepreciacaoPorKm;

    final lucroLiquidoTurno = turno.ganhos - gastoCombustivel - provisaoManutencao - provisaoDepreciacao - custoLavagem;

    return _buildCard(
      title: 'Análise do Último Turno',
      children: [
        _buildInfoRow('🛣️ KM Rodados', AppFormatters.formatKm(turno.kmRodados)),
        const SizedBox(height: 8),
        _buildInfoRow('💰 Ganhos Brutos', AppFormatters.formatCurrency(turno.ganhos)),
        _buildInfoRow('⛽ Gasto Combustível', AppFormatters.formatCurrency(gastoCombustivel), isNegative: true),
        _buildInfoRow('🛠️ Provisão Manutenção', AppFormatters.formatCurrency(provisaoManutencao), isNegative: true),
        _buildInfoRow('🚗 Provisão Troca Veículo', AppFormatters.formatCurrency(provisaoDepreciacao), isNegative: true),
        if (custoLavagem > 0) // Só mostra a linha se houver custo de lavagem no dia
          _buildInfoRow('🧼 Custo Lavagem (Hoje)', AppFormatters.formatCurrency(custoLavagem), isNegative: true),
        const Divider(),
        _buildInfoRow('✅ Lucro Líquido (Turno)', AppFormatters.formatCurrency(lucroLiquidoTurno), isHighlight: true),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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