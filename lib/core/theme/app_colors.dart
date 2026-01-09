import 'package:flutter/material.dart';

/// Application color palette
/// Inspired by ChatGPT's clean and modern design
class AppColors {
  AppColors._();

  // Light Theme Colors
  static const Color primaryLight = Color(0xFF10A37F); // Green accent
  static const Color secondaryLight = Color(0xFF6E6E80);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F7F8);
  static const Color textPrimaryLight = Color(0xFF202123);
  static const Color textSecondaryLight = Color(0xFF6E6E80);
  static const Color dividerLight = Color(0xFFECECF1);

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF10A37F); // Same green accent
  static const Color secondaryDark = Color(0xFFACACAC);
  static const Color backgroundDark = Color(0xFF343541);
  static const Color surfaceDark = Color(0xFF444654);
  static const Color textPrimaryDark = Color(0xFFECECF1);
  static const Color textSecondaryDark = Color(0xFFACACAC);
  static const Color dividerDark = Color(0xFF565869);

  // Common Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10A37F);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Message Bubble Colors
  static const Color userMessageLight = Color(0xFFF7F7F8);
  static const Color aiMessageLight = Color(0xFFFFFFFF);
  static const Color userMessageDark = Color(0xFF343541);
  static const Color aiMessageDark = Color(0xFF444654);

  // Gradient Colors (for loading states, etc.)
  static const LinearGradient shimmerGradientLight = LinearGradient(
    colors: [
      Color(0xFFEBEBF4),
      Color(0xFFF4F4F4),
      Color(0xFFEBEBF4),
    ],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  static const LinearGradient shimmerGradientDark = LinearGradient(
    colors: [
      Color(0xFF2A2B32),
      Color(0xFF3E3F4B),
      Color(0xFF2A2B32),
    ],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
}

