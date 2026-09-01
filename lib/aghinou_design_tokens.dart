import 'package:flutter/material.dart';

class AghinouDesign {
  static const primary = Color(0xFF6C3FE8);
  static const primaryLight = Color(0xFF9A6CFF);
  static const teal = Color(0xFF00A896);
  static const orange = Color(0xFFFF9F43);
  static const pink = Color(0xFFD84F9B);
  static const blue = Color(0xFF3F7CFF);
  static const red = Color(0xFFE45757);
  static const background = Color(0xFFF7F5FF);
  static const text = Color(0xFF24213A);

  static Color categoryColor(String category) {
    switch (category) {
      case 'خودرو': return red;
      case 'املاک': return blue;
      case 'موبایل': return teal;
      case 'لوازم خانه': return orange;
      case 'کالای دیجیتال': return primary;
      case 'پوشاک': return pink;
      case 'خدمات': return const Color(0xFF00897B);
      default: return primary;
    }
  }

  static IconData categoryIcon(String category) {
    switch (category) {
      case 'خودرو': return Icons.directions_car_rounded;
      case 'املاک': return Icons.home_work_rounded;
      case 'موبایل': return Icons.smartphone_rounded;
      case 'لوازم خانه': return Icons.chair_rounded;
      case 'کالای دیجیتال': return Icons.devices_rounded;
      case 'پوشاک': return Icons.checkroom_rounded;
      case 'خدمات': return Icons.handyman_rounded;
      default: return Icons.grid_view_rounded;
    }
  }
}
