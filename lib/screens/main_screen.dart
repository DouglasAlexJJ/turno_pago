// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/screens/config_screen.dart';
import 'package:turno_pago/screens/home_screen.dart';
import 'package:turno_pago/screens/monitor_screen.dart';
import 'package:turno_pago/screens/painel_financeiro_screen.dart';

class MainScreen extends StatefulWidget {
  // NOVO PARÂMETRO
  final bool verificarTurnoAoIniciar;

  const MainScreen({super.key, this.verificarTurnoAoIniciar = true});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indiceSelecionado = 0;

  // A LISTA DE TELAS NÃO PODE SER MAIS 'static const'
  late final List<Widget> _telas;

  @override
  void initState() {
    super.initState();
    // Inicializamos a lista aqui, passando o parâmetro para a HomeScreen
    _telas = <Widget>[
      HomeScreen(verificarTurnoAoIniciar: widget.verificarTurnoAoIniciar),
      const PainelFinanceiroScreen(),
      const MonitorScreen(),
    ];
  }

  static const List<String> _titulos = <String>[
    'Resumo do Dia',
    'Painel Financeiro',
    'Monitor e Provisões',
  ];

  void _aoTocarNoItem(int index) {
    setState(() {
      _indiceSelecionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos.elementAt(_indiceSelecionado)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfigScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _telas.elementAt(_indiceSelecionado),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Resumo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            label: 'Monitor',
          ),
        ],
        currentIndex: _indiceSelecionado,
        onTap: _aoTocarNoItem,
      ),
    );
  }
}