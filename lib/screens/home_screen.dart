import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dados_service.dart';
import 'turno_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  double ganhos = 0;
  double kmRodado = 0;
  double consumoCarro = 10; // valor padrão
  double gastoCombustivel = 0;
  double ganhoPorKm = 0;
  double ganhoPorCorrida = 0;
  int qtdCorridas = 0;
  String plataforma = 'outro';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    final ganhosTurno = await DadosService.lerDouble('ganhos_turno');
    final km = await DadosService.lerDouble('km_rodado_turno');
    final tipoApp = await DadosService.lerString('plataforma_turno');
    final consumo = prefs.getDouble('consumo_urbano') ?? 10;
    final corridas = await DadosService.lerInt('corridas_turno');

    // Assumindo um valor médio de combustível. Idealmente, viria das configs.
    const precoCombustivel = 5.50;

    // CORREÇÃO APLICADA AQUI: Trocado '0' por '0.0' para garantir o tipo double.
    final gastoComb = (km > 0 && consumo > 0) ? (km / consumo) * precoCombustivel : 0.0;
    final ganhoKm = (km > 0) ? ganhosTurno / km : 0.0;
    final ganhoCorrida = (tipoApp == '99' && corridas > 0) ? ganhosTurno / corridas : 0.0;

    if (!mounted) return;

    setState(() {
      ganhos = ganhosTurno;
      kmRodado = km;
      consumoCarro = consumo;
      plataforma = tipoApp;
      qtdCorridas = corridas;
      gastoCombustivel = gastoComb;
      ganhoPorKm = ganhoKm;
      ganhoPorCorrida = ganhoCorrida;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumo do Último Turno')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildCard(
              title: 'Resumo Financeiro',
              children: [
                _buildInfoRow('🗂 Plataforma', plataforma == '99' ? '99' : 'Outro App'),
                _buildInfoRow('💰 Ganhos Brutos', 'R\$ ${ganhos.toStringAsFixed(2)}'),
                _buildInfoRow('⛽ Gasto Combustível', 'R\$ ${gastoCombustivel.toStringAsFixed(2)}', isNegative: true),
                const Divider(),
                _buildInfoRow('✅ Lucro Estimado', 'R\$ ${(ganhos - gastoCombustivel).toStringAsFixed(2)}', isHighlight: true),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Métricas de Desempenho',
              children: [
                _buildInfoRow('🛣 KM Rodados', '${kmRodado.toStringAsFixed(1)} km'),
                _buildInfoRow('📊 Ganho por KM', 'R\$ ${ganhoPorKm.toStringAsFixed(2)}'),
                if (plataforma == '99') ...[
                  const Divider(),
                  _buildInfoRow('🚗 Corridas Feitas', '$qtdCorridas'),
                  _buildInfoRow('📦 Ganho por Corrida', 'R\$ ${ganhoPorCorrida.toStringAsFixed(2)}'),
                ]
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TurnoScreen()),
          );
          // Recarrega os dados se a tela de turno indicar que algo foi salvo
          if (result == true) {
            _carregarDados();
          }
        },
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, size: 32),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.redAccent : (isHighlight ? Colors.green : null),
            ),
          ),
        ],
      ),
    );
  }
}