// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:turno_pago/models/despesa.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/historico_turnos_screen.dart';
import 'package:turno_pago/screens/despesas_screen.dart';
import 'package:turno_pago/screens/turno_ativo_screen.dart';
import '../services/dados_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';

class HomeScreen extends StatefulWidget {
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

    if (widget.verificarTurnoAoIniciar) {
      _verificarTurnoAtivo();
    }
  }

  void _verificarTurnoAtivo() async {
    bool isRunning = await service.isRunning();
    if (isRunning && mounted) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TurnoAtivoScreen()));
    }
  }

  void _recarregarDados() {
    setState(() {
      _dadosDoDiaFuture = _carregarDadosDoDia();
    });
  }

  Future<Map<String, dynamic>> _carregarDadosDoDia() async {
    final hoje = DateTime.now();
    final veiculoService = VeiculoService();

    final results = await Future.wait([
      DadosService.getTurnos(),
      DadosService.getDespesas(),
      veiculoService.getVeiculo(),
      DadosService.getManutencaoItens(),
    ]);

    final todosOsTurnos = results[0] as List<Turno>;
    final todasAsDespesas = results[1] as List<Despesa>;
    final veiculo = results[2] as Veiculo;
    final itensManutencao = results[3] as List<ManutencaoItem>;

    final turnosDeHoje = todosOsTurnos
        .where((t) =>
    t.data.year == hoje.year &&
        t.data.month == hoje.month &&
        t.data.day == hoje.day)
        .toList();

    final despesasDeHoje = todasAsDespesas
        .where((d) =>
    d.data.year == hoje.year &&
        d.data.month == hoje.month &&
        d.data.day == hoje.day)
        .toList();

    double ganhosBrutos = 0;
    double kmRodados = 0;
    int totalSegundosDia = 0;

    for (final turno in turnosDeHoje) {
      ganhosBrutos += turno.ganhos;
      kmRodados += turno.kmRodados;
      totalSegundosDia += turno.duracaoEmSegundos;
    }

    final totalDespesas =
    despesasDeHoje.fold(0.0, (soma, d) => soma + d.valor);

    double provisaoManutencao = 0;
    double custoAluguelDia = 0;
    double kmRestantesFranquia = 0;

    if (veiculo.tipoVeiculo == TipoVeiculo.proprio) {
      final custoManutencaoPorKm =
      itensManutencao.fold(0.0, (soma, item) => soma + item.custoPorKm);
      provisaoManutencao = kmRodados * custoManutencaoPorKm;
    } else {
      if (turnosDeHoje.isNotEmpty) {
        custoAluguelDia = veiculo.provisaoDiariaAluguel;
      }
      if (veiculo.kmContratadoAluguel != null &&
          veiculo.kmInicialAluguel != null) {
        final kmRodadosNoCiclo = veiculo.kmAtual - veiculo.kmInicialAluguel!;
        kmRestantesFranquia =
            (veiculo.kmContratadoAluguel! - kmRodadosNoCiclo).toDouble();
      }
    }

    final lucroLiquido =
        ganhosBrutos - totalDespesas - provisaoManutencao - custoAluguelDia;
    final double valorReserva =
    (lucroLiquido > 0) ? lucroLiquido * (veiculo.percentualReserva / 100) : 0;
    final double lucroFinal = lucroLiquido - valorReserva;

    return {
      'veiculo': veiculo,
      'ganhosBrutos': ganhosBrutos,
      'despesas': totalDespesas,
      'provisaoManutencao': provisaoManutencao,
      'custoAluguelDia': custoAluguelDia,
      'kmRestantesFranquia': kmRestantesFranquia,
      'totalSegundosDia': totalSegundosDia,
      'valorReserva': valorReserva,
      'lucroFinal': lucroFinal,
    };
  }

  String _formatarDuracao(int totalSegundos) {
    final duracao = Duration(seconds: totalSegundos);
    final horas = duracao.inHours;
    final minutos = duracao.inMinutes.remainder(60);
    return '${horas.toString().padLeft(2, '0')}h ${minutos.toString().padLeft(2, '0')}min';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resumo do Dia"),
        centerTitle: true,
        actions: const [],
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
              return Center(
                  child: Text('Erro ao carregar dados: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('Nenhum dado encontrado.'));
            }

            final dados = snapshot.data!;
            final Veiculo veiculo = dados['veiculo'];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  if (veiculo.tipoVeiculo == TipoVeiculo.alugado)
                    _buildControleAluguelCard(dados),
                  const SizedBox(height: 16),
                  _buildResumoDoDiaCard(dados),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Gerenciar Despesas'),
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DespesasScreen()));
                      _recarregarDados();
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('Ver Histórico de Turnos'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoricoTurnosScreen()));
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

  Widget _buildControleAluguelCard(Map<String, dynamic> dados) {
    final Veiculo veiculo = dados['veiculo'];
    final double kmRestantes = dados['kmRestantesFranquia'];

    int diasRestantes = 0;
    if (veiculo.dataFimAluguel != null) {
      diasRestantes =
          veiculo.dataFimAluguel!.difference(DateTime.now()).inDays;
      if (diasRestantes < 0) diasRestantes = 0;
    }

    if (veiculo.dataFimAluguel == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controle do Aluguel',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.blue.shade800)),
            const Divider(height: 20),
            _buildInfoRow('🗓️ Dias Restantes:', '$diasRestantes dias'),
            if (veiculo.kmContratadoAluguel != null)
              _buildInfoRow('🛣️ KM Restantes da Franquia:',
                  AppFormatters.formatKm(kmRestantes)),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoDoDiaCard(Map<String, dynamic> dados) {
    final Veiculo veiculo = dados['veiculo'];
    final double ganhosBrutos = dados['ganhosBrutos'];
    final double despesas = dados['despesas'];
    final double provisaoManutencao = dados['provisaoManutencao'];
    final double custoAluguelDia = dados['custoAluguelDia'];
    final double valorReserva = dados['valorReserva'];
    final double lucroFinal = dados['lucroFinal'];
    final int totalSegundosDia = dados['totalSegundosDia'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                '💰 Ganhos Brutos', AppFormatters.formatCurrency(ganhosBrutos)),
            if (totalSegundosDia > 0)
              _buildInfoRow(
                  '🕒 Horas Trabalhadas', _formatarDuracao(totalSegundosDia)),
            const Divider(height: 20),
            Text('Custos e Provisões do Dia:',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildInfoRow(
                '💸 Despesas', AppFormatters.formatCurrency(despesas),
                isNegative: true),
            if (veiculo.tipoVeiculo == TipoVeiculo.alugado)
              _buildInfoRow('🔑 Provisão Aluguel',
                  AppFormatters.formatCurrency(custoAluguelDia),
                  isNegative: true),
            if (veiculo.tipoVeiculo == TipoVeiculo.proprio)
              _buildInfoRow('🛠️ Provisão Manutenção',
                  AppFormatters.formatCurrency(provisaoManutencao),
                  isNegative: true),
            _buildInfoRow('🚨 Reserva de Emergência',
                AppFormatters.formatCurrency(valorReserva),
                isNegative: true,
                negativeColor: Colors.orange.shade800),
            const Divider(height: 20),
            _buildInfoRow(
                '✅ Lucro Final (no bolso)',
                AppFormatters.formatCurrency(lucroFinal),
                isHighlight: true,
                lucroValor: lucroFinal),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isHighlight = false,
        bool isNegative = false,
        double? lucroValor,
        Color? negativeColor}) {
    Color? textColor;
    FontWeight fontWeight = FontWeight.w500;

    if (isNegative) {
      textColor = negativeColor ?? Colors.redAccent;
    } else if (isHighlight) {
      fontWeight = FontWeight.bold;
      textColor = (lucroValor ?? 0) >= 0
          ? Colors.green.shade800
          : Colors.red.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.black54))),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}