// lib/dica_arrastar.dart (ou lib/widgets/dica_arrastar.dart)

import 'package:flutter/material.dart';

class DicaArrastar extends StatelessWidget {
  const DicaArrastar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swipe_left_outlined, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Text(
              'Arraste um item para a esquerda para excluir',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}