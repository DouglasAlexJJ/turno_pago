import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  GastosScreenState createState() => GastosScreenState();
}

class GastosScreenState extends State<GastosScreen> {
  final _valorController = TextEditingController();
  String _categoriaSelecionada = 'Alimentação';

  List<Map<String, dynamic>> _gastos = [];

  @override
  void initState() {
    super.initState();
    _carregarGastos();
  }

  Future<void> _carregarGastos() async {
    final prefs = await SharedPreferences.getInstance();
    final gastosString = prefs.getStringList('gastos') ?? [];

    setState(() {
      _gastos = gastosString
          .map((g) => jsonDecode(g) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _adicionarGasto() async {
    final prefs = await SharedPreferences.getInstance();
    final novoGasto = {
      'valor': double.parse(_valorController.text),
      'categoria': _categoriaSelecionada,
      'data': DateTime.now().toIso8601String(),
    };

    _gastos.add(novoGasto);
    final listaConvertida = _gastos.map((g) => jsonEncode(g)).toList();
    await prefs.setStringList('gastos', listaConvertida);

    _valorController.clear();
    _carregarGastos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gastos do Dia')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valorController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Valor (R\$)'),
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: _categoriaSelecionada,
                  onChanged: (String? newValue) {
                    setState(() {
                      _categoriaSelecionada = newValue!;
                    });
                  },
                  items: [
                    'Alimentação',
                    'Lavagem',
                    'Estacionamento',
                    'Manutenção',
                    'Outros'
                  ].map<DropdownMenuItem<String>>((String valor) {
                    return DropdownMenuItem<String>(
                      value: valor,
                      child: Text(valor),
                    );
                  }).toList(),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _adicionarGasto,
                  child: Text('+'),
                )
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _gastos.length,
              itemBuilder: (context, index) {
                final gasto = _gastos[index];
                return ListTile(
                  title: Text('${gasto['categoria']} - R\$ ${gasto['valor'].toStringAsFixed(2)}'),
                  subtitle: Text(gasto['data'].toString().substring(0, 10)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
