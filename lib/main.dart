import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PartyLedgerApp());
}

class PartyLedgerApp extends StatelessWidget {
  const PartyLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Party Ledger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}