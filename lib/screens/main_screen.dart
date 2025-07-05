// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/screens/config_screen.dart'; // Importa a tela de config
import 'package:turno_pago/screens/home_screen.dart';
import 'package:turno_pago/screens/painel_financeiro_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indiceSelecionado = 0;

  static const List<Widget> _telas = <Widget>[
    HomeScreen(),
    PainelFinanceiroScreen(),
  ];

  void _aoTocarNoItem(int index) {
    setState(() {
      _indiceSelecionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Adicionamos uma AppBar aqui para o botão de Configurações
      appBar: AppBar(
        title: Text(_indiceSelecionado == 0 ? 'Resumo do Dia' : 'Painel Financeiro'),
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
            icon: Icon(Icons.home),
            label: 'Resumo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Painel',
          ),
        ],
        currentIndex: _indiceSelecionado,
        selectedItemColor: Colors.amber[800],
        onTap: _aoTocarNoItem,
      ),
    );
  }
}