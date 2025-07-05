// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/screens/home_screen.dart';
import 'package:turno_pago/screens/painel_financeiro_screen.dart'; // Vamos criar este arquivo a seguir

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indiceSelecionado = 0; // 0 para Home, 1 para Painel

  // Lista de telas que a barra de navegação irá controlar
  static const List<Widget> _telas = <Widget>[
    HomeScreen(),
    PainelFinanceiroScreen(), // A nova tela que vamos construir
  ];

  void _aoTocarNoItem(int index) {
    setState(() {
      _indiceSelecionado = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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