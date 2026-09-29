import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  // Brand Colors - Premium USA Fresh Grocery Theme
  static const Color emeraldPrimary = Color(0xFF0F5132); // Deep Organic Emerald
  static const Color sageLight = Color(0xFFE8F5E9);     // Soft Sage Tint
  static const Color coralAccent = Color(0xFFFF6B35);   // Warm Coral Accent
  static const Color slateDark = Color(0xFF0F172A);     // Slate Charcoal Text
  static const Color slateMuted = Color(0xFF64748B);    // Slate Muted Text
  static const Color bgLight = Color(0xFFF8FAFC);       // Soft Clean Background
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color applePayBlack = Color(0xFF000000); // iOS Apple Pay Accent

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      primaryColor: emeraldPrimary,
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: emeraldPrimary,
        scaffoldBackgroundColor: bgLight,
        barBackgroundColor: cardWhite,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: emeraldPrimary,
        secondary: coralAccent,
        surface: cardWhite,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: slateDark),
        titleTextStyle: TextStyle(
          color: slateDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: emeraldPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: const TextStyle(color: slateMuted, fontSize: 14),
        hintStyle: const TextStyle(color: slateMuted, fontSize: 14),
        prefixIconColor: slateMuted,
        suffixIconColor: slateMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldPrimary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: emeraldPrimary.withAlpha(76),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
