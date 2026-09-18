import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SavingGoalUIHelper {
  static const Map<String, IconData> iconMap = {
    'savings': Icons.savings_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'phone': Icons.phone_iphone_rounded,
    'car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'school': Icons.school_rounded,
    'fitness': Icons.fitness_center_rounded,
    'health': Icons.favorite_rounded,
    'vacation': Icons.beach_access_rounded,
    'celebration': Icons.celebration_rounded,
  };

  static const List<String> availableColors = [
    '#CCFF00', // Lime
    '#14B8A6', // Teal
    '#38BDF8', // Sky Blue
    '#F97316', // Orange
    '#F43F5E', // Rose
    '#A855F7', // Purple
  ];

  static IconData getIconData(String? iconKey) {
    if (iconKey == null) return Icons.savings_rounded;
    return iconMap[iconKey] ?? Icons.savings_rounded;
  }

  static Color parseColor(String? hex, [Color fallback = AppColors.primary]) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static Color getContrastColor(Color color, BuildContext context) {
    return AppColors.ensureContrast(color, context);
  }
}
