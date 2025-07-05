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
  double horas = 0;
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
    final horasTrabalhadas = await DadosService.lerDouble('horas_turno');
    final tipoApp = await DadosService.lerString('plataforma_turno');
    final consumo = prefs.getDouble('consumo_urbano') ?? 10;
    final corridas = await DadosService.lerInt('corridas_turno');

    final gastoComb = (km > 0 && consumo > 0) ? (km / consumo) * 5.50 : 0; // gasolina média
    final ganhoKm = (km > 0) ? ganhosTurno / km : 0;
    final ganhoCorrida = (tipoApp == '99' && corridas > 0) ? ganhosTurno / corridas : 0;

    setState(() {
      ganhos = ganhosTurno.toDouble();
      kmRodado = km.toDouble();
      horas = horasTrabalhadas.toDouble();
      consumoCarro = consumo.toDouble();
      plataforma = tipoApp;
      qtdCorridas = corridas;
      gastoCombustivel = gastoComb.toDouble();
      ganhoPorKm = ganhoKm.toDouble();
      ganhoPorCorrida = ganhoCorrida.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumo do Turno')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('🗂 Plataforma: ${plataforma == '99' ? '99' : 'Outro App'}'),
            Text('💰 Ganho: R\$ ${ganhos.toStringAsFixed(2)}'),
            Text('🛣 KM Rodado: ${kmRodado.toStringAsFixed(1)} km'),
            Text('🕓 Horas trabalhadas: ${horas.toStringAsFixed(1)} h'),
            const Divider(height: 24),
            Text('⛽ Gasto estimado com combustível: R\$ ${gastoCombustivel.toStringAsFixed(2)}'),
            Text('📊 Ganho por KM: R\$ ${ganhoPorKm.toStringAsFixed(2)}'),
            if (plataforma == '99')
              Text('📦 Ganho por Corrida: R\$ ${ganhoPorCorrida.toStringAsFixed(2)}'),
            if (plataforma == '99')
              Text('🚗 Corridas feitas: $qtdCorridas'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TurnoScreen()),
          );
        },
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
