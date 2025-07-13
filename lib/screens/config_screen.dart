// lib/screens/config_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/auth/auth_gate.dart';
import 'package:turno_pago/services/auth_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'manutencao_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  late Veiculo _veiculo;
  bool _isLoading = true;

  // Controladores
  final _consumoController = TextEditingController();
  final _percentualReservaController = TextEditingController();
  final _kmAtualController = TextEditingController();
  final _custoTotalAluguelController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _kmContratadoController = TextEditingController();
  final _kmInicialAluguelController = TextEditingController(); // NOVO CONTROLADOR
  DateTime? _dataFimAluguel;

  late TipoVeiculo _tipoVeiculoSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final veiculoData = await VeiculoService().getVeiculo();
    if (mounted) {
      setState(() {
        _veiculo = veiculoData;
        _consumoController.text = _veiculo.consumoMedio.toString();
        _percentualReservaController.text = _veiculo.percentualReserva.toString();
        _kmAtualController.text = _veiculo.kmAtual.toString();
        _tipoVeiculoSelecionado = _veiculo.tipoVeiculo;
        _custoTotalAluguelController.updateValue(_veiculo.custoTotalAluguel ?? 0);
        _dataFimAluguel = _veiculo.dataFimAluguel;
        _kmContratadoController.text = _veiculo.kmContratadoAluguel?.toString() ?? '';
        // Carrega o KM inicial no novo controlador
        _kmInicialAluguelController.text = _veiculo.kmInicialAluguel?.toString() ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _salvarConfiguracoes() async {
    if (_formKey.currentState!.validate()) {
      if (_tipoVeiculoSelecionado == TipoVeiculo.alugado && _dataFimAluguel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione a data de devolução para o aluguel.'), backgroundColor: Colors.red),
        );
        return;
      }

      final novoVeiculo = _veiculo.copyWith(
        consumoMedio: double.tryParse(_consumoController.text) ?? _veiculo.consumoMedio,
        percentualReserva: _tipoVeiculoSelecionado == TipoVeiculo.proprio
            ? (double.tryParse(_percentualReservaController.text) ?? _veiculo.percentualReserva)
            : _veiculo.percentualReserva,
        kmAtual: int.tryParse(_kmAtualController.text) ?? _veiculo.kmAtual,
        tipoVeiculo: _tipoVeiculoSelecionado,
        custoTotalAluguel: _tipoVeiculoSelecionado == TipoVeiculo.alugado ? _custoTotalAluguelController.numberValue : null,
        dataFimAluguel: _tipoVeiculoSelecionado == TipoVeiculo.alugado ? _dataFimAluguel : null,
        dataInicioAluguel: _tipoVeiculoSelecionado == TipoVeiculo.alugado ? (_veiculo.dataInicioAluguel ?? DateTime.now()) : null,
        kmContratadoAluguel: _tipoVeiculoSelecionado == TipoVeiculo.alugado ? int.tryParse(_kmContratadoController.text) : null,
        // Salva o KM inicial do aluguel a partir do novo campo
        kmInicialAluguel: _tipoVeiculoSelecionado == TipoVeiculo.alugado ? int.tryParse(_kmInicialAluguelController.text) : null,
      );

      await VeiculoService().salvarVeiculo(novoVeiculo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipo de Veículo', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      SegmentedButton<TipoVeiculo>(
                        segments: const [
                          ButtonSegment(value: TipoVeiculo.proprio, label: Text('Próprio'), icon: Icon(Icons.directions_car)),
                          ButtonSegment(value: TipoVeiculo.alugado, label: Text('Alugado'), icon: Icon(Icons.key)),
                        ],
                        selected: {_tipoVeiculoSelecionado},
                        onSelectionChanged: (selection) {
                          setState(() { _tipoVeiculoSelecionado = selection.first; });
                        },
                      ),
                      const Divider(height: 32),

                      if (_tipoVeiculoSelecionado == TipoVeiculo.alugado)
                        _buildCamposAluguel()
                      else
                        _buildCamposProprio(),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kmAtualController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quilometragem ATUAL do Veículo (km)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _consumoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Consumo médio (km/l)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton( onPressed: _salvarConfiguracoes, child: const Text('Salvar Tudo')),
              const Divider(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sair da Conta'),
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCamposProprio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _percentualReservaController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Reserva de Emergência (%)'),
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.build),
            label: const Text('Editar Custos de Manutenção'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManutencaoScreen())),
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }

  // WIDGET ATUALIZADO COM OS NOVOS CAMPOS
  Widget _buildCamposAluguel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configuração do Aluguel Atual', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextFormField(
          controller: _custoTotalAluguelController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Custo Total do Contrato (R\$)'),
          validator: (v) => _custoTotalAluguelController.numberValue <= 0 ? 'Insira um custo válido' : null,
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4)
          ),
          title: Text(_dataFimAluguel == null ? 'Data de Devolução' : 'Devolver em: ${DateFormat('dd/MM/yyyy').format(_dataFimAluguel!)}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final data = await showDatePicker(context: context, initialDate: _dataFimAluguel ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (data != null) {
              setState(() { _dataFimAluguel = data; });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _kmContratadoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Franquia de KM do Pacote (Opcional)'),
        ),
        const SizedBox(height: 16),
        // NOVO CAMPO ADICIONADO
        TextFormField(
          controller: _kmInicialAluguelController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'KM Inicial do Contrato de Aluguel'),
          validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
        ),
        const Divider(height: 32),
      ],
    );
  }
}