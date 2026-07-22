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
      title: 'Ledger App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F4F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6DFF),
          background: const Color(0xFFF5F4F0),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1C1C1E),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1C1C1E)),
          shape: Border(bottom: BorderSide(color: Color(0xFFE8E8E4))),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFFE0DED8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0DED8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0DED8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1A6DFF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCC3300)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF1A6DFF),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A6DFF),
            side: const BorderSide(color: Color(0xFF1A6DFF)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFEEECE8),
          space: 1,
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minVerticalPadding: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
          backgroundColor: Color(0xFF1A6DFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1C1C1E),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFEEECE8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}