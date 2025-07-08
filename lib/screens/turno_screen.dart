// lib/screens/turno_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:turno_pago/models/turno.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'package:uuid/uuid.dart';

class TurnoScreen extends StatefulWidget {
  const TurnoScreen({super.key});

  @override
  TurnoScreenState createState() => TurnoScreenState();
}

class TurnoScreenState extends State<TurnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ganhosController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  final _kmRodadoController = TextEditingController();
  final _kmAtualVeiculoController = TextEditingController();
  final _corridasController = TextEditingController();
  final _precoCombustivelController = MoneyMaskedTextController(
      leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');

  Veiculo? _veiculo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosVeiculo();
  }

  Future<void> _carregarDadosVeiculo() async {
    setState(() => _isLoading = true);
    final veiculoData = await VeiculoService.getVeiculo();
    setState(() {
      _veiculo = veiculoData;
      // Preenche o campo de KM total com o último valor salvo para facilitar
      if (veiculoData.kmAtual > 0) {
        _kmAtualVeiculoController.text = veiculoData.kmAtual.toString();
      }
      if (veiculoData.precoCombustivel > 0) {
        _precoCombustivelController.updateValue(veiculoData.precoCombustivel);
      }
      _isLoading = false;
    });
  }

  Future<void> _salvarTurno() async {
    if (_formKey.currentState!.validate()) {
      final kmRodadosNoTurno = double.tryParse(_kmRodadoController.text) ?? 0.0;
      final kmAtualVeiculo = int.tryParse(_kmAtualVeiculoController.text) ?? 0;

      // Cria o objeto do turno com a data atual e os KMs rodados
      final novoTurno = Turno(
        id: const Uuid().v4(),
        data: DateTime.now(), // Sempre a data atual
        ganhos: _ganhosController.numberValue,
        kmRodados: kmRodadosNoTurno,
        corridas: int.tryParse(_corridasController.text) ?? 0,
        precoCombustivel: _precoCombustivelController.numberValue,
      );

      await DadosService.adicionarTurno(novoTurno);

      // Atualiza o veículo com a KM total para o controle de manutenção
      final veiculoAtualizado = _veiculo!.copyWith(
        kmAtual: kmAtualVeiculo,
        precoCombustivel: _precoCombustivelController.numberValue,
      );
      await VeiculoService.salvarVeiculo(veiculoAtualizado);

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Turno'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _ganhosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ganhos Totais do Turno',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _ganhosController.numberValue <= 0 ? 'Insira um valor válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmRodadoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'KM Rodados no Turno (Hodômetro Parcial)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (double.tryParse(v ?? '0') ?? 0) <= 0 ? 'Insira um valor válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _kmAtualVeiculoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'KM Atual do Veículo (Hodômetro Total)',
                    hintText: 'Última KM registrada: ${_veiculo?.kmAtual ?? 0}',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    final km = int.tryParse(v);
                    if (km == null) return 'Número inválido';
                    if (km <= (_veiculo?.kmAtual ?? 0)) return 'Deve ser maior que a última KM';
                    return null;
                  }
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _corridasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade de Corridas',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoCombustivelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço do Combustível (por litro)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _precoCombustivelController.numberValue <= 0 ? 'Insira um valor válido' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarTurno,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Salvar Turno'),
              )
            ],
          ),
        ),
      ),
    );
  }
}