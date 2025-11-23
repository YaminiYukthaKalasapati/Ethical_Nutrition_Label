import 'package:flutter/material.dart';

class AppColors {
  // User Theme (Teal)
  static const Color primaryTeal = Color(0xFF00BFA5);
  static const Color darkTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DD0E1);

  // Admin Theme (Purple)
  static const Color primaryPurple = Color(0xFF7E57C2);
  static const Color darkPurple = Color(0xFF5E35B1);
  static const Color lightPurple = Color(0xFF9575CD);

  // Gradients
  static const LinearGradient userGradient = LinearGradient(
    colors: [darkTeal, primaryTeal, lightTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [darkPurple, primaryPurple, lightPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
