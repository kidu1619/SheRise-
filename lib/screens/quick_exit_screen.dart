import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets.dart';

/// A neutral screen shown by "Quick exit". Long-press the title to go back.
class QuickExitScreen extends StatelessWidget {
  const QuickExitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: GestureDetector(
          onLongPress: () => context.go('/home'),
          child: const Tx('Notes'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Tx('Shopping list'), subtitle: Tx('Bread, rice, onions, tea')),
          ListTile(title: Tx('Study plan'), subtitle: Tx('Read chapter 4 on Thursday')),
          ListTile(title: Tx('Ideas'), subtitle: Tx('Plant herbs on the balcony')),
        ],
      ),
    );
  }
}
