import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const QCartApp());
}

class QCartApp extends StatelessWidget {
  const QCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q Cart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
