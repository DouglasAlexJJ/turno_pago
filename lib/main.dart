import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/gastos_screen.dart';
import 'screens/relatorios_screen.dart';
import 'screens/config_screen.dart';

void main() {
  runApp(TurnoPagoApp());
}

class TurnoPagoApp extends StatelessWidget {
  const TurnoPagoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turno Pago',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Color(0xFF121212),
      ),
      home: MainMenu(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  MainMenuState createState() => MainMenuState();
}

class MainMenuState extends State<MainMenu> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    GastosScreen(),
    RelatoriosScreen(),
    ConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF1F1F1F),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Turno'),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config.'),
        ],
      ),
    );
  }
}
