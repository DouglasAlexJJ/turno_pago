// lib/screens/selecionar_tipo_veiculo_screen.dart

import 'package:flutter/material.dart';
import 'package:turno_pago/screens/primeiro_acesso_screen.dart';
import 'package:turno_pago/screens/config_veiculo_alugado_screen.dart'; // Tela que criaremos a seguir

class SelecionarTipoVeiculoScreen extends StatelessWidget {
  const SelecionarTipoVeiculoScreen({super.key});

  void _onSelecionarTipo(BuildContext context, bool isProprio) {
    if (isProprio) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PrimeiroAcessoScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ConfigVeiculoAlugadoScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Como você trabalha?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione o tipo de veículo que você utiliza para calcularmos seus custos da forma correta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),
                _buildOptionCard(
                  context: context,
                  icon: Icons.directions_car,
                  title: 'Veículo Próprio',
                  subtitle: 'Calcule depreciação, manutenção e custos fixos.',
                  onTap: () => _onSelecionarTipo(context, true),
                ),
                const SizedBox(height: 20),
                _buildOptionCard(
                  context: context,
                  icon: Icons.key,
                  title: 'Veículo Alugado',
                  subtitle: 'Insira os custos do aluguel (diário ou por KM).',
                  onTap: () => _onSelecionarTipo(context, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}