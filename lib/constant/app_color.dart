import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation 
  AppColors._(); 

  // Static constants for global colors
  static const Color primary = Color(0xFF181823);
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
  static const Color error = Color(0xFFD32F2F);
  static const Color primaryBlue = Color(0xFF2563EB);


  // Dynamic colors that adapt to Dark/Light mode
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1E1E1E);
  }
}