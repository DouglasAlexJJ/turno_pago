// lib/screens/manutencao_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/screens/add_edit_manutencao_screen.dart';
import 'package:turno_pago/screens/main_screen.dart';
import 'package:turno_pago/services/dados_service.dart';
import 'package:turno_pago/utils/app_formatters.dart'; // Importa nosso formatador

class ManutencaoScreen extends StatefulWidget {
  final bool isFirstTimeSetup;

  const ManutencaoScreen({super.key, this.isFirstTimeSetup = false});

  @override
  ManutencaoScreenState createState() => ManutencaoScreenState();
}

class ManutencaoScreenState extends State<ManutencaoScreen> {
  List<ManutencaoItem> _itens = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  Future<void> _carregarItens() async {
    setState(() => _isLoading = true);
    final itens = await DadosService.getManutencaoItens();
    setState(() {
      _itens = itens;
      _isLoading = false;
    });
  }

  void _navegarParaAddItem() async {
    final bool? recarregar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditManutencaoScreen()),
    );
    if (recarregar == true) {
      _carregarItens();
    }
  }

  void _navegarParaEditItem(ManutencaoItem item) async {
    final bool? recarregar = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditManutencaoScreen(item: item)),
    );
    if (recarregar == true) {
      _carregarItens();
    }
  }

  Future<void> _concluirSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('primeiro_acesso_concluido', true);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double custoTotalPorKm = _itens.fold(0.0, (soma, item) => soma + item.custoPorKm);

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
                      Text(
                        'Passo 2 de 2: Adicione itens de manutenção para um cálculo de custos preciso. Ex: Pneus, Troca de Óleo.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (widget.isFirstTimeSetup) const SizedBox(height: 16),
                    const Text(
                      'Custo Total de Manutenção por KM:',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    // VALOR MODIFICADO AQUI
                    Text(
                      AppFormatters.formatCurrencyPerKm(custoTotalPorKm),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                ? const Center(child: Text("Nenhum item adicionado.\nUse o botão '+' para começar.", textAlign: TextAlign.center))
                : ListView.builder(
              itemCount: _itens.length,
              itemBuilder: (context, index) {
                final item = _itens[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(item.nome),
                    // VALOR MODIFICADO AQUI
                    subtitle: Text('Custo/KM: ${AppFormatters.formatCurrencyPerKm(item.custoPorKm)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () => _navegarParaEditItem(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await DadosService.removerManutencaoItem(item.id);
                            _carregarItens();
                          },
                        ),
                      ],
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
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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