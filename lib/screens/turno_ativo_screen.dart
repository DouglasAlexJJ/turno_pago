// lib/screens/turno_ativo_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:geolocator/geolocator.dart';
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
  double _distanciaEmKm = 0.0;
  Veiculo? _veiculo;
  final service = FlutterBackgroundService();
  final veiculoService = VeiculoService();
  bool _isTurnoAtivo = false;
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>?>? _serviceSubscription;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setup() async {
    _veiculo = await veiculoService.getVeiculo();
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
    _serviceSubscription = service.on('update').listen((event) {
      if (mounted) {
        setState(() {
          _tempoFormatado = event!['tempo'] ?? '00:00:00';
          _distanciaEmKm = event['distancia'] ?? 0.0;
        });
      }
    });
  }

  Future<void> _iniciarServicoETurno() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissão de Localização'),
          content: const Text("Para calcular sua distância corretamente, mesmo com o app fechado, o Turno Pago precisa de acesso à sua localização 'o tempo todo'.\n\nNa próxima tela, por favor, escolha a opção 'Permitir o tempo todo' se disponível, ou 'Permitir durante o uso do app' para continuarmos."),
          actions: [
            TextButton(
              child: const Text('ENTENDI, CONTINUAR'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await _showSettingsDialog("A permissão de localização foi negada permanentemente. Para usar esta função, você precisa habilitá-la manualmente nas configurações.");
      return;
    }
    if (permission != LocationPermission.always) {
      if (!mounted) return;
      await _showSettingsDialog("A localização em segundo plano é essencial. Por favor, vá para as configurações e mude a permissão para 'Permitir o tempo todo'.");
      return;
    }
    if (!mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Lembrete Importante'),
        content: const Text('Você zerou o odômetro parcial (TRIP) do seu veículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK, INICIAR TURNO'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await service.startService();
      if (mounted) {
        setState(() {
          _isTurnoAtivo = true;
        });
        _ouvirServico();
      }
    }
  }

  Future<void> _showSettingsDialog(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissão Necessária'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('IR PARA CONFIGURAÇÕES'),
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarTurno() async {
    if (!mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Turno'),
        content: const Text('Tem certeza que deseja cancelar o turno atual? Todos os dados serão perdidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      _serviceSubscription?.cancel();
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

  // FUNÇÃO ATUALIZADA COM A LÓGICA DE SELEÇÃO DE TEXTO
  Future<void> _finalizarTurno() async {
    final ganhosController = MoneyMaskedTextController(leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
    final kmRodadoController = TextEditingController(text: _distanciaEmKm.toStringAsFixed(2));
    final kmAtualVeiculoController = TextEditingController(text: _veiculo?.kmAtual.toString() ?? '0');
    final corridasController = TextEditingController();
    final precoCombustivelController = MoneyMaskedTextController(
        leftSymbol: 'R\$ ',
        decimalSeparator: ',',
        thousandSeparator: '.',
        initialValue: _veiculo?.precoCombustivel ?? 0);

    final formKey = GlobalKey<FormState>();

    final ganhosFocus = FocusNode();
    final kmRodadoFocus = FocusNode();
    final kmAtualFocus = FocusNode();
    final corridasFocus = FocusNode();
    final combustivelFocus = FocusNode();

    // Função helper para adicionar o listener de seleção
    void addSelectAllOnFocus(FocusNode focusNode, TextEditingController controller) {
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
        }
      });
    }

    // Adiciona o listener para cada campo
    addSelectAllOnFocus(ganhosFocus, ganhosController);
    addSelectAllOnFocus(kmRodadoFocus, kmRodadoController);
    addSelectAllOnFocus(kmAtualFocus, kmAtualVeiculoController);
    addSelectAllOnFocus(corridasFocus, corridasController);
    addSelectAllOnFocus(combustivelFocus, precoCombustivelController);


    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        void submitForm() {
          if (formKey.currentState!.validate()) {
            Navigator.of(context).pop({
              'ganhos': ganhosController.numberValue,
              'kmRodados': double.tryParse(kmRodadoController.text) ?? 0.0,
              'kmAtual': int.tryParse(kmAtualVeiculoController.text) ?? 0,
              'corridas': int.tryParse(corridasController.text) ?? 0,
              'precoCombustivel': precoCombustivelController.numberValue,
            });
          }
        }
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
                    focusNode: ganhosFocus, // Associa o nó de foco
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ganhos Totais do Turno'),
                    validator: (v) => ganhosController.numberValue <= 0 ? 'Insira um valor' : null,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).requestFocus(kmRodadoFocus),
                  ),
                  TextFormField(
                    controller: kmRodadoController,
                    focusNode: kmRodadoFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'KM Rodados no Turno'),
                    validator: (v) => (double.tryParse(v ?? '0') ?? 0) <= 0 ? 'Insira um valor' : null,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).requestFocus(kmAtualFocus),
                  ),
                  TextFormField(
                    controller: kmAtualVeiculoController,
                    focusNode: kmAtualFocus,
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
                    },
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).requestFocus(corridasFocus),
                  ),
                  TextFormField(
                    controller: corridasController,
                    focusNode: corridasFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantidade de Corridas'),
                    validator: (v) => (int.tryParse(v ?? '0') ?? 0) <= 0 ? 'Insira um valor' : null,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => FocusScope.of(context).requestFocus(combustivelFocus),
                  ),
                  TextFormField(
                    controller: precoCombustivelController,
                    focusNode: combustivelFocus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Preço do Combustível (litro)'),
                    validator: (v) => precoCombustivelController.numberValue <= 0 ? 'Insira um valor' : null,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: submitForm,
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
              onPressed: submitForm,
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      _serviceSubscription?.cancel();
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
    final novoTurno = Turno(
      id: const Uuid().v4(),
      data: DateTime.now(),
      ganhos: dados['ganhos'],
      kmRodados: dados['kmRodados'],
      corridas: dados['corridas'],
      precoCombustivel: dados['precoCombustivel'],
    );
    await DadosService.adicionarTurno(novoTurno);
    await veiculoService.atualizarKm(dados['kmAtual']);
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
          Text('Tempo de Trabalho',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          Text(_tempoFormatado,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontWeight: FontWeight.bold, fontSize: 60)),
          const SizedBox(height: 24),
          Text('Distância Percorrida',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey.shade600)),
          Text('${_distanciaEmKm.toStringAsFixed(2)} km',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontWeight: FontWeight.bold, fontSize: 60)),
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
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cancelarTurno,
            child: const Text('Cancelar Turno', style: TextStyle(color: Colors.grey)),
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
          Text('Pronto para começar?',
              style: Theme.of(context).textTheme.headlineMedium),
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
            ),
          ),
        ],
      ),
    );
  }
}