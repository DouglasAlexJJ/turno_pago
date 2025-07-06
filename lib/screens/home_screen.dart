import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    if (!mounted) return;

    setState(() {
      ultimoTurno = turnoMaisRecente;
      ganhosDoDia = somaGanhos;
      totalDespesasDoDia = somaDespesas;
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
                  _buildInfoRow('💰 Ganhos Brutos (Dia)', 'R\$ ${ganhosDoDia.toStringAsFixed(2)}'),
                  _buildInfoRow('💸 Despesas (Dia)', 'R\$ ${totalDespesasDoDia.toStringAsFixed(2)}', isNegative: true),
                  const Divider(),
                  _buildInfoRow('✅ Lucro Líquido (Dia)', 'R\$ ${(ganhosDoDia - totalDespesasDoDia).toStringAsFixed(2)}', isHighlight: true),
                ],
              ),
              const SizedBox(height: 16),

              if (ultimoTurno == null)
                const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Nenhum turno registrado ainda. Adicione um no botão '+'.")))
              else
                FutureBuilder<Map<String, dynamic>>(
                  future: _getDadosDeCusto(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const SizedBox.shrink();
                    }

                    final custos = snapshot.data!;
                    return _buildAnaliseTurnoCard(
                      turno: ultimoTurno!,
                      custoProvisionadoPorKm: custos['custoProvisionado']!,
                      consumoMedio: custos['consumoMedio']!,
                    );
                  },
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

    final consumo = prefs.getDouble('veiculo_consumo_medio') ?? 10.0; // Padrão 10km/l

    return {
      'custoProvisionado': custoManutencaoPorKm + custoDepreciacaoPorKm,
      'consumoMedio': consumo,
    };
  }

  Widget _buildAnaliseTurnoCard({
    required Turno turno,
    required double custoProvisionadoPorKm,
    required double consumoMedio,
  }) {
    final gastoCombustivel = (consumoMedio > 0)
        ? (turno.kmRodados / consumoMedio) * turno.precoCombustivel
        : 0.0;

    final custoTotalProvisionado = turno.kmRodados * custoProvisionadoPorKm;
    final lucroLiquidoTurno = turno.ganhos - gastoCombustivel - custoTotalProvisionado;

    return _buildCard(
      title: 'Análise do Último Turno',
      children: [
        _buildInfoRow('🛣️ KM Rodados', '${turno.kmRodados.toStringAsFixed(1)} km'),
        _buildInfoRow('💰 Ganhos Brutos', 'R\$ ${turno.ganhos.toStringAsFixed(2)}'),
        _buildInfoRow('⛽ Gasto Combustível', 'R\$ ${gastoCombustivel.toStringAsFixed(2)}', isNegative: true),
        _buildInfoRow('🛠️ Custos Futuros', 'R\$ ${custoTotalProvisionado.toStringAsFixed(2)}', isNegative: true),
        const Divider(),
        _buildInfoRow('✅ Lucro Líquido (Turno)', 'R\$ ${lucroLiquidoTurno.toStringAsFixed(2)}', isHighlight: true),
      ],
    );
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