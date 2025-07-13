// lib/screens/manutencao_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/models/veiculo.dart';
import 'package:turno_pago/screens/add_edit_manutencao_screen.dart';
import 'package:turno_pago/screens/main_screen.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/services/veiculo_service.dart';
import 'package:turno_pago/utils/app_formatters.dart';

class ManutencaoScreen extends StatefulWidget {
  final bool isFirstTimeSetup;

  const ManutencaoScreen({super.key, this.isFirstTimeSetup = false});

  @override
  ManutencaoScreenState createState() => ManutencaoScreenState();
}

class ManutencaoScreenState extends State<ManutencaoScreen> {
  List<ManutencaoItem> _itens = [];
  Veiculo? _veiculo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final itensData = await DadosService.getManutencaoItens();
    final veiculoData = await VeiculoService().getVeiculo();
    if(mounted) {
      setState(() {
        _itens = itensData;
        _veiculo = veiculoData;
        _isLoading = false;
      });
    }
  }

  Future<void> _registrarTroca(ManutencaoItem item) async {
    final kmController =
    TextEditingController(text: _veiculo?.kmAtual.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Troca de "${item.nome}"'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: kmController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'KM atual do veículo',
              hintText: 'Digite a quilometragem exata',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Campo obrigatório';
              if (int.tryParse(v) == null) return 'Número inválido';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final kmAtual = int.parse(kmController.text);

      final itemAtualizado = item.copyWith(
        kmUltimaTroca: kmAtual,
        dataUltimaTroca: DateTime.now(),
      );
      await DadosService.salvarManutencaoItem(itemAtualizado);

      if (_veiculo != null) {
        // CORREÇÃO: Usa a nova função segura para atualizar APENAS a KM
        await VeiculoService().atualizarKm(kmAtual);
      }
      _carregarDados();
    }
  }

  void _navegarParaAddItem() async {
    final bool? recarregar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditManutencaoScreen()),
    );
    if (recarregar == true) {
      _carregarDados();
    }
  }

  void _navegarParaEditItem(ManutencaoItem item) async {
    final bool? recarregar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditManutencaoScreen(item: item)),
    );
    if (recarregar == true) {
      _carregarDados();
    }
  }

  void _concluirSetup() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double custoTotalPorKm =
    _itens.fold(0.0, (soma, item) => soma + item.custoPorKm);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custos de Manutenção'),
        automaticallyImplyLeading: !widget.isFirstTimeSetup,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (widget.isFirstTimeSetup)
                      Padding(
                        padding: const EdgeInsets.only(bottom:16.0),
                        child: Text(
                          'Passo 2 de 2: Adicione itens de manutenção para um cálculo de custos preciso. Ex: Pneus, Troca de Óleo.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    const Text(
                      'Custo Total de Manutenção por KM:',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      AppFormatters.formatCurrencyPerKm(custoTotalPorKm),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _itens.isEmpty
                ? const Center(
                child: Text(
                    "Nenhum item adicionado.\nUse o botão '+' para começar.",
                    textAlign: TextAlign.center))
                : ListView.builder(
              itemCount: _itens.length,
              itemBuilder: (context, index) {
                final item = _itens[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    final itemRemovido = _itens[index];
                    final int itemIndex = index;

                    setState(() {
                      _itens.removeAt(index);
                    });

                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${item.nome} removido."),
                        action: SnackBarAction(
                          label: "Desfazer",
                          onPressed: () {
                            setState(() {
                              _itens.insert(itemIndex, itemRemovido);
                            });
                          },
                        ),
                      ),
                    ).closed.then((reason) {
                      if (reason != SnackBarClosedReason.action) {
                        DadosService.removerManutencaoItem(itemRemovido.id);
                      }
                    });
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: InkWell(
                      onTap: () => _navegarParaEditItem(item),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(
                                'Custo/KM: ${AppFormatters.formatCurrencyPerKm(item.custoPorKm)}'),
                            const Divider(height: 20),
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.sync, size: 18),
                                label: const Text('Troca Realizada'),
                                onPressed: () => _registrarTroca(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade50,
                                  foregroundColor: Colors.green.shade800,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.isFirstTimeSetup)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _concluirSetup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Concluir e Ir para o App'),
              ),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaAddItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}