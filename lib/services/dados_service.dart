import 'package:shared_preferences/shared_preferences.dart';

class DadosService {
  static Future<void> salvarDouble(String chave, double valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(chave, valor);
  }

  static Future<double> lerDouble(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(chave) ?? 0.0;
  }

  static Future<void> salvarString(String chave, String valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, valor);
  }

  static Future<String> lerString(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(chave) ?? '';
  }

  static Future<void> salvarInt(String chave, int valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(chave, valor);
  }

  static Future<int> lerInt(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(chave) ?? 0;
  }

  static Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
