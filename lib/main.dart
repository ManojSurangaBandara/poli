import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/borrower_provider.dart';
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
      ],
      child: MaterialApp(
        title: 'Moneylender App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const BorrowerListScreen(),
      ),
    );
  }
}
