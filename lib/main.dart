import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/borrower_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/undo_provider.dart';
import 'screens/borrower_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BorrowerProvider()..loadBorrowers()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UndoProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Moneylender Pro',
            theme: themeProvider.currentTheme,
            home: const BorrowerListScreen(),
          );
        },
      ),
    );
  }
}
