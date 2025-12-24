import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2E7D32), // 先用绿色系，后续可替换品牌色
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
