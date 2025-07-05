import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'carro_screen.dart';
import 'manutencao_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  final _consumoUrbanoController = TextEditingController();
  final _consumoRodoviarioController = TextEditingController();
  final _tipoCombustivelController = TextEditingController();
  final _valorPneusController = TextEditingController();
  final _metaDiariaController = TextEditingController();

  Future<void> _salvarConfiguracoes() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('consumo_urbano', double.parse(_consumoUrbanoController.text));
      await prefs.setDouble('consumo_rodoviario', double.parse(_consumoRodoviarioController.text));
      await prefs.setString('tipo_combustivel', _tipoCombustivelController.text);
      await prefs.setDouble('valor_pneus', double.parse(_valorPneusController.text));
      await prefs.setDouble('meta_diaria', double.parse(_metaDiariaController.text));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configurações Iniciais')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _consumoUrbanoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Consumo urbano (km/l)'),
                validator: (value) => value!.isEmpty ? 'Informe o consumo urbano' : null,
              ),
              TextFormField(
                controller: _consumoRodoviarioController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Consumo rodoviário (km/l)'),
                validator: (value) => value!.isEmpty ? 'Informe o consumo rodoviário' : null,
              ),
              TextFormField(
                controller: _tipoCombustivelController,
                decoration: InputDecoration(labelText: 'Tipo de combustível'),
                validator: (value) => value!.isEmpty ? 'Informe o tipo de combustível' : null,
              ),
              TextFormField(
                controller: _valorPneusController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Valor total dos pneus (R\$)'),
                validator: (value) => value!.isEmpty ? 'Informe o valor dos pneus' : null,
              ),
              TextFormField(
                controller: _metaDiariaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Meta diária de lucro (R\$)'),
                validator: (value) => value!.isEmpty ? 'Informe sua meta diária' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarConfiguracoes,
                child: Text('Salvar Configurações'),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.directions_car),
                label: Text('Planejar Troca de Carro'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CarroScreen()),
                  );
                }
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.build),
                label: Text('Manutenção detalhada'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManutencaoScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
