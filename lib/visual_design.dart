import 'package:flutter/material.dart';

const aghPrimary = Color(0xFF6C3FE8);
const aghBg = Color(0xFFF7F5FF);
const aghInk = Color(0xFF24213A);

ThemeData aghinouTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: aghPrimary),
    scaffoldBackgroundColor: aghBg,
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: aghBg, foregroundColor: aghInk),
    cardTheme: CardThemeData(elevation: 2, color: Colors.white, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: aghPrimary, width: 1.5)),
    ),
    navigationBarTheme: NavigationBarThemeData(height: 74, backgroundColor: Colors.white, indicatorColor: aghPrimary.withValues(alpha: .13)),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: aghPrimary, foregroundColor: Colors.white),
  );
}

class AghGradient extends StatelessWidget {
  final Widget child;
  const AghGradient({super.key, required this.child});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [aghPrimary, Color(0xFF9A6CFF)], begin: Alignment.topRight, end: Alignment.bottomLeft),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x226C3FE8), blurRadius: 20, offset: Offset(0, 9))],
    ),
    child: child,
  );
}
