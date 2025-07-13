// lib/screens/config_veiculo_alugado_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/main_screen.dart';
import 'package:turno_pago/services/veiculo_service.dart';

class ConfigVeiculoAlugadoScreen extends StatefulWidget {
  const ConfigVeiculoAlugadoScreen({super.key});

  @override
  State<ConfigVeiculoAlugadoScreen> createState() =>
      _ConfigVeiculoAlugadoScreenState();
}

class _ConfigVeiculoAlugadoScreenState
    extends State<ConfigVeiculoAlugadoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _custoTotalController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _kmContratadoController = TextEditingController();
  final _kmAtualController = TextEditingController();
  final _consumoController = TextEditingController();

  // Nós de Foco
  final _custoTotalFocus = FocusNode();
  final _kmContratadoFocus = FocusNode();
  final _kmAtualFocus = FocusNode();
  final _consumoFocus = FocusNode();

  DateTime? _dataFimAluguel;

  @override
  void initState() {
    super.initState();
    _adicionarListenersDeFoco();
  }

  @override
  void dispose() {
    // Limpa os nós de foco
    _custoTotalFocus.dispose();
    _kmContratadoFocus.dispose();
    _kmAtualFocus.dispose();
    _consumoFocus.dispose();
    super.dispose();
  }

  void _adicionarListenersDeFoco() {
    void addSelectAllOnFocus(FocusNode focusNode, TextEditingController controller) {
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
        }
      });
    }

    addSelectAllOnFocus(_custoTotalFocus, _custoTotalController);
    addSelectAllOnFocus(_kmContratadoFocus, _kmContratadoController);
    addSelectAllOnFocus(_kmAtualFocus, _kmAtualController);
    addSelectAllOnFocus(_consumoFocus, _consumoController);
  }

  Future<void> _selecionarDataDevolucao(BuildContext context) async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (dataEscolhida != null && dataEscolhida != _dataFimAluguel) {
      setState(() {
        _dataFimAluguel = dataEscolhida;
      });
    }
  }

  Future<void> _salvarConfiguracao() async {
    if (_formKey.currentState!.validate()) {
      if (_dataFimAluguel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione a data de devolução.'), backgroundColor: Colors.red),
        );
        return;
      }

      // LÓGICA DE SALVAMENTO CORRIGIDA
      final kmAtualDigitado = int.tryParse(_kmAtualController.text) ?? 0;

      final veiculo = Veiculo(
        tipoVeiculo: TipoVeiculo.alugado,
        custoTotalAluguel: _custoTotalController.numberValue,
        dataInicioAluguel: DateTime.now(),
        dataFimAluguel: _dataFimAluguel,
        kmContratadoAluguel: int.tryParse(_kmContratadoController.text),
        // AQUI ESTÁ A CORREÇÃO: O KM inicial do aluguel é o KM atual informado.
        kmInicialAluguel: kmAtualDigitado,
        kmAtual: kmAtualDigitado,
        consumoMedio: double.tryParse(_consumoController.text) ?? 10.0,
      );

      await VeiculoService().salvarVeiculo(veiculo);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Veículo Alugado'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Detalhes do Contrato de Aluguel',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _custoTotalController,
                focusNode: _custoTotalFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Custo Total do Aluguel (R\$)'),
                validator: (v) => _custoTotalController.numberValue <= 0
                    ? 'Insira um custo válido'
                    : null,
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4)
                ),
                title: Text(
                  _dataFimAluguel == null
                      ? 'Data de Devolução do Veículo'
                      : 'Devolver em: ${DateFormat('dd/MM/yyyy').format(_dataFimAluguel!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selecionarDataDevolucao(context),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kmContratadoController,
                focusNode: _kmContratadoFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Franquia de KM do Pacote (Opcional)'),
              ),

              const Divider(height: 32),

              Text(
                'Outras informações',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kmAtualController,
                focusNode: _kmContratadoFocus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'KM atual do veículo (no odômetro)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _consumoController,
                focusNode: _kmContratadoFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Consumo médio (km/l)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _salvarConfiguracao,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('SALVAR E CONCLUIR'),
              )
            ],
          ),
        ),
      ),
    );
  }
}