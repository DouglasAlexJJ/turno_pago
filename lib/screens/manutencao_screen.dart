// lib/screens/manutencao_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/models/manutencao_item.dart';
import 'package:turno_pago/screens/add_edit_manutencao_screen.dart';
import 'package:turno_pago/services/dados_service.dart';

class ManutencaoScreen extends StatefulWidget {
  const ManutencaoScreen({super.key});

  @override
  ManutencaoScreenState createState() => ManutencaoScreenState();
}

class ManutencaoScreenState extends State<ManutencaoScreen> {
  List<ManutencaoItem> _itens = [];
  int _kmAtualVeiculo = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    // Carrega a lista de itens de manutenção
    final itensCarregados = await DadosService.getManutencaoItens();

    // Carrega o último turno para saber a KM atual do veículo
    final turnos = await DadosService.getTurnos();
    int kmAtual = 0;
    if (turnos.isNotEmpty) {
      turnos.sort((a, b) => b.data.compareTo(a.data));
      kmAtual = turnos.first.kmAtualVeiculo;
    }

    setState(() {
      _itens = itensCarregados;
      _kmAtualVeiculo = kmAtual;
      _isLoading = false;
    });
  }

  Future<void> _registrarTroca(ManutencaoItem item) async {
    if (_kmAtualVeiculo == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registre um turno com a KM atual antes de marcar uma troca.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registrar Troca de ${item.nome}?'),
        content: Text('Isso atualizará a última troca para a quilometragem atual do veículo ($_kmAtualVeiculo km).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Confirmar Troca'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Cria uma cópia do item com os novos dados da troca
      final itemAtualizado = item.copyWith(
        kmUltimaTroca: _kmAtualVeiculo,
        dataUltimaTroca: DateTime.now(),
      );
      await DadosService.salvarManutencaoItem(itemAtualizado);
      _carregarDados(); // Recarrega a tela para mostrar os dados atualizados
    }
  }

  void _editarItem(ManutencaoItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditManutencaoScreen(item: item)),
    );
    _carregarDados(); // Recarrega caso o usuário tenha salvo alterações
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano de Manutenção'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            if (_kmAtualVeiculo > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  'KM Atual do Veículo: $_kmAtualVeiculo km',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
            ..._itens.map((item) => _buildManutencaoCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildManutencaoCard(ManutencaoItem item) {
    // Lógica para a barra de progresso
    final kmDesdeUltimaTroca = _kmAtualVeiculo - item.kmUltimaTroca;
    double progresso = 0;
    if (item.vidaUtilKm > 0 && kmDesdeUltimaTroca > 0) {
      progresso = kmDesdeUltimaTroca / item.vidaUtilKm;
    }
    progresso = progresso.clamp(0.0, 1.0); // Garante que o progresso fique entre 0 e 1

    Color corProgresso = Colors.green;
    if (progresso > 0.85) {
      corProgresso = Colors.red;
    }
    else if (progresso > 0.65) {
      corProgresso = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.nome, style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _editarItem(item),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Última troca: ${item.kmUltimaTroca} km'),
            Text('Próxima troca: ${item.proximaTrocaKm} km', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progresso,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey.shade300,
              color: corProgresso,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${(progresso * 100).toStringAsFixed(0)}% da vida útil'),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Realizei a Troca'),
                onPressed: () => _registrarTroca(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}