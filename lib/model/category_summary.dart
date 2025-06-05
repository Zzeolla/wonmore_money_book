import 'package:flutter/material.dart';
import 'package:wonmore_money_book/util/analysis_category_color.dart';

class CategorySummary {
  final String name;
  final double amount;
  final Color color;

  CategorySummary({
    required this.name,
    required this.amount,
    Color? color,
  }) : color = color ?? getColorForCategory(name);
}
