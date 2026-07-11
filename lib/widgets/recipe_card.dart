import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String recipeName;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(
          Icons.restaurant_menu,
          color: Colors.deepOrange,
        ),
        title: Text(
          recipeName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}