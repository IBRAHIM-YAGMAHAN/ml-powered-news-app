import 'package:flutter/material.dart';

class News {
  final String header;
  final String url;
  final String? pngUrl;
  String category;
  Color color;

  News({
    required this.header,
    required this.url,
    this.pngUrl,
    this.category = "Analyzing...",
    this.color = Colors.grey,
  });

  /// Returns the display color for a given category name.
  static Color colorForCategory(String category) {
    switch (category) {
      case "World":
        return const Color(0xFF1565C0); // dark blue
      case "Sports":
        return const Color(0xFF2E7D32); // dark green
      case "Business":
        return const Color(0xFFE65100); // deep orange
      case "Sci/Tech":
        return const Color(0xFF6A1B9A); // deep purple
      default:
        return Colors.grey.shade600;
    }
  }

  /// Returns the icon for a given category.
  static IconData iconForCategory(String category) {
    switch (category) {
      case "World":
        return Icons.public;
      case "Sports":
        return Icons.sports_soccer;
      case "Business":
        return Icons.trending_up;
      case "Sci/Tech":
        return Icons.memory;
      default:
        return Icons.article;
    }
  }
}