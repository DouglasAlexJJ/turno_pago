// lib/screens/turno_ativo_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/main_screen.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'package:uuid/uuid.dart';

class TurnoAtivoScreen extends StatefulWidget {
  const TurnoAtivoScreen({super.key});

  @override
  State<TurnoAtivoScreen> createState() => _TurnoAtivoScreenState();
}

class _TurnoAtivoScreenState extends State<TurnoAtivoScreen> {
  String _tempoFormatado = "00:00:00";
  Veiculo? _veiculo;
  final service = FlutterBackgroundService();

  bool _isTurnoAtivo = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    _veiculo = await VeiculoService.getVeiculo();
    bool isRunning = await service.isRunning();

    if (mounted) {
      setState(() {
        _isTurnoAtivo = isRunning;
        _isLoading = false;
      });

      if (isRunning) {
        _ouvirServico();
      }
    }
  }

  void _ouvirServico() {
    service.on('update').listen((event) {
      if(mounted) {
        setState(() {
          _tempoFormatado = event!['tempo'] ?? '00:00:00';
        });
      }
    });
  }

  Future<void> _iniciarServicoETurno() async {
    await service.startService();
    if (mounted) {
      setState(() {
        _isTurnoAtivo = true;
      });
      _ouvirServico();
    }
  }

  Future<void> _finalizarTurno() async {
    final ganhosController = MoneyMaskedTextController(
        leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
    final kmRodadoController = TextEditingController();
    final kmAtualVeiculoController = TextEditingController(text: _veiculo?.kmAtual.toString() ?? '0');

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Finalizar Turno'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tempo de Trabalho: $_tempoFormatado', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ganhosController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ganhos Totais do Turno'),
                    validator: (v) => ganhosController.numberValue <= 0 ? 'Insira um valor' : null,
                  ),
                  TextFormField(
                    controller: kmRodadoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'KM Rodados no Turno'),
                    validator: (v) => (double.tryParse(v ?? '0') ?? 0) <= 0 ? 'Insira um valor' : null,
                  ),
                  TextFormField(
                      controller: kmAtualVeiculoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'KM Atual do Veículo',
                        hintText: 'Última KM: ${_veiculo?.kmAtual ?? 0}',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo obrigatório';
                        final km = int.tryParse(v);
                        if (km == null) return 'Número inválido';
                        if (km <= (_veiculo?.kmAtual ?? 0)) return 'Deve ser maior que a última KM';
                        return null;
                      }
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'ganhos': ganhosController.numberValue,
                    'kmRodados': double.tryParse(kmRodadoController.text) ?? 0.0,
                    'kmAtual': int.tryParse(kmAtualVeiculoController.text) ?? 0,
                  });
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _salvarDados(result);

      service.invoke('stopService');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('turno_start_time');

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen(verificarTurnoAoIniciar: false)),
            (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _salvarDados(Map<String, dynamic> dados) async {
    final precoCombustivel = _veiculo?.precoCombustivel ?? 0.0;
    final novoTurno = Turno(
      id: const Uuid().v4(),
      data: DateTime.now(),
      ganhos: dados['ganhos'],
      kmRodados: dados['kmRodados'],
      corridas: 0,
      precoCombustivel: precoCombustivel,
    );
    await DadosService.adicionarTurno(novoTurno);
    final veiculoAtualizado = _veiculo!.copyWith(kmAtual: dados['kmAtual']);
    await VeiculoService.salvarVeiculo(veiculoAtualizado);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isTurnoAtivo,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isTurnoAtivo ? 'Turno em Andamento' : 'Novo Turno'),
          automaticallyImplyLeading: !_isTurnoAtivo,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isTurnoAtivo
            ? _buildVisorTurnoAtivo()
            : _buildVisorPreInicio(),
      ),
    );
  }

  Widget _buildVisorTurnoAtivo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tempo de Trabalho',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            _tempoFormatado,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Finalizar Turno'),
            onPressed: _finalizarTurno,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisorPreInicio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline, size: 100, color: Colors.green),
          const SizedBox(height: 20),
          Text(
            'Pronto para começar?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
              onPressed: _iniciarServicoETurno,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 30),
                  SizedBox(width: 8),
                  Text('INICIAR', style: TextStyle(fontSize: 20)),
                ],
              )
          ),
        ],
      ),
    );
  }
}