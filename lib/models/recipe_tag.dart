import 'package:flutter/material.dart';

class RecipeTag {
  final String name;
  final IconData icon;
  final Color color;

  const RecipeTag({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<RecipeTag> recipeTags = [
  RecipeTag(
    name: 'Chicken',
    icon: Icons.set_meal,
    color: Color(0xFFFFD8B5),
  ),
  RecipeTag(
    name: 'Beef',
    icon: Icons.lunch_dining,
    color: Color(0xFFFFC7C7),
  ),
  RecipeTag(
    name: 'Vegetarian',
    icon: Icons.eco,
    color: Color(0xFFCFEFD2),
  ),
  RecipeTag(
    name: 'Dessert',
    icon: Icons.cake,
    color: Color(0xFFFFE5C7),
  ),
  RecipeTag(
    name: 'Healthy',
    icon: Icons.favorite,
    color: Color(0xFFD8F4E0),
  ),
  RecipeTag(
    name: 'Pasta',
    icon: Icons.ramen_dining,
    color: Color(0xFFFFEBC8),
  ),
  RecipeTag(
    name: 'Curry',
    icon: Icons.local_fire_department,
    color: Color(0xFFFFD6C2),
  ),
  RecipeTag(
    name: 'Breakfast',
    icon: Icons.free_breakfast,
    color: Color(0xFFFFF0C2),
  ),
  RecipeTag(
    name: 'Baking',
    icon: Icons.bakery_dining,
    color: Color(0xFFFFE3D5),
  ),
  RecipeTag(
    name: 'Quick',
    icon: Icons.bolt,
    color: Color(0xFFDDEBFF),
  ),
];