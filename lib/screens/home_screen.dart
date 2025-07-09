// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:turno_pago/models/despesa.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/historico_turnos_screen.dart';
import 'package:turno_pago/screens/manutencao_screen.dart';
import 'package:turno_pago/utils/app_formatters.dart';
import 'despesas_screen.dart';
import 'turno_ativo_screen.dart';
import '../services/dados_service.dart';
import '../services/veiculo_service.dart';

class HomeScreen extends StatefulWidget {
  // NOVO PARÂMETRO: Controla a verificação no início
  final bool verificarTurnoAoIniciar;

  const HomeScreen({super.key, this.verificarTurnoAoIniciar = true});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _dadosDoDiaFuture;
  final service = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    _recarregarDados();

    // A verificação agora depende do novo parâmetro
    if (widget.verificarTurnoAoIniciar) {
      _verificarTurnoAtivo();
    }
  }

  void _verificarTurnoAtivo() async {
    bool isRunning = await service.isRunning();
    if (isRunning) {
      if(mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TurnoAtivoScreen())
        );
      }
    }
  }

  void _recarregarDados() {
    setState(() {
      _dadosDoDiaFuture = _carregarDadosDoDia();
    });
  }

  // O resto do arquivo permanece EXATAMENTE O MESMO...
  // ... (código de _carregarDadosDoDia, _iniciarNovoTurno, build, etc)
  Future<Map<String, dynamic>> _carregarDadosDoDia() async {
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

    final turnosDeHoje = todosOsTurnos.where((t) => t.data.year == hoje.year && t.data.month == hoje.month && t.data.day == hoje.day).toList();
    final despesasDeHoje = todasAsDespesas.where((d) => d.data.year == hoje.year && d.data.month == hoje.month && d.data.day == hoje.day).toList();
    final custoManutencaoPorKm = itensManutencao.fold(0.0, (soma, item) => soma + item.custoPorKm);

    double ganhosBrutos = 0, kmRodados = 0, gastoCombustivel = 0, provisaoManutencao = 0;
    for (final turno in turnosDeHoje) {
      ganhosBrutos += turno.ganhos;
      kmRodados += turno.kmRodados;
      if (veiculo.consumoMedio > 0) {
        gastoCombustivel += (turno.kmRodados / veiculo.consumoMedio) * turno.precoCombustivel;
      }
      provisaoManutencao += turno.kmRodados * custoManutencaoPorKm;
    }
    final totalDespesas = despesasDeHoje.fold(0.0, (soma, despesa) => soma + despesa.valor);

    final lucroLiquido = ganhosBrutos - totalDespesas - provisaoManutencao;

    final double valorReserva = (lucroLiquido > 0) ? lucroLiquido * (veiculo.percentualReserva / 100) : 0;
    final double lucroFinal = lucroLiquido - valorReserva;
    final reaisPorKm = (kmRodados > 0) ? ganhosBrutos / kmRodados : 0.0;

    return {
      'ganhosBrutos': ganhosBrutos,
      'kmRodados': kmRodados,
      'despesas': totalDespesas,
      'gastoCombustivel': gastoCombustivel,
      'provisaoManutencao': provisaoManutencao,
      'lucroLiquido': lucroLiquido,
      'valorReserva': valorReserva,
      'lucroFinal': lucroFinal,
      'reaisPorKm': reaisPorKm,
    };
  }

  void _iniciarNovoTurno() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TurnoAtivoScreen()),
    );
    if (result == true) {
      _recarregarDados();
    }
  }

  void _abrirTelaManutencao() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManutencaoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resumo do Dia"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.build_outlined),
            onPressed: _abrirTelaManutencao,
            tooltip: 'Manutenção',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _recarregarDados(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dadosDoDiaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
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
                      final navigator = Navigator.of(context);
                      await navigator.push(MaterialPageRoute(builder: (_) => const DespesasScreen()));
                      _recarregarDados();
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Ver Histórico de Turnos'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoricoTurnosScreen()));
                    },
                  )
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _iniciarNovoTurno,
        icon: const Icon(Icons.play_arrow),
        label: const Text("Iniciar Turno"),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  Widget _buildResumoDoDiaCard(Map<String, dynamic> dados) {
    final double ganhosBrutos = dados['ganhosBrutos'];
    final double despesas = dados['despesas'];
    final double gastoCombustivel = dados['gastoCombustivel'];
    final double provisaoManutencao = dados['provisaoManutencao'];
    final double valorReserva = dados['valorReserva'];
    final double lucroFinal = dados['lucroFinal'];
    final double kmRodados = dados['kmRodados'];
    final double reaisPorKm = dados['reaisPorKm'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('💰 Ganhos Brutos', AppFormatters.formatCurrency(ganhosBrutos)),
            const Divider(height: 20),
            Text('Custos e Provisões do Dia:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildInfoRow('💸 Despesas', AppFormatters.formatCurrency(despesas), isNegative: true),
            _buildInfoRow('🛠️ Provisão Manutenção', AppFormatters.formatCurrency(provisaoManutencao), isNegative: true),
            _buildInfoRow('🚨 Reserva de Emergência', AppFormatters.formatCurrency(valorReserva), isNegative: true, negativeColor: Colors.orange.shade800),
            const Divider(height: 20),
            _buildInfoRow('✅ Lucro Final (no bolso)', AppFormatters.formatCurrency(lucroFinal), isHighlight: true, lucroValor: lucroFinal),
            const SizedBox(height: 10),
            const Divider(height: 20),
            _buildInfoRow('⛽ Combustível Gasto (Estimado)', AppFormatters.formatCurrency(gastoCombustivel), isInformational: true),
            _buildInfoRow('🛣️ KM Rodados no Dia', AppFormatters.formatKm(kmRodados), isInformational: true),
            _buildInfoRow('📈 R\$ por KM Rodado', AppFormatters.formatCurrency(reaisPorKm), isInformational: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isNegative = false, bool isInformational = false, double? lucroValor, Color? negativeColor}) {
    Color? textColor;
    FontWeight fontWeight = FontWeight.w500;

    if (isNegative) {
      textColor = negativeColor ?? Colors.redAccent;
    } else if (isHighlight) {
      fontWeight = FontWeight.bold;
      textColor = (lucroValor ?? 0) >= 0 ? Colors.green.shade800 : Colors.redAccent;
    } else if (isInformational) {
      textColor = Colors.blueGrey.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: fontWeight, color: textColor),
          ),
        ],
      ),
    );
  }
}