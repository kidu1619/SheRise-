import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          child: const Text('Notes'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(title: Text('Shopping list'), subtitle: Text('Bread, rice, onions, tea')),
          ListTile(title: Text('Study plan'), subtitle: Text('Read chapter 4 on Thursday')),
          ListTile(title: Text('Ideas'), subtitle: Text('Plant herbs on the balcony')),
        ],
      ),
    );
  }
}
