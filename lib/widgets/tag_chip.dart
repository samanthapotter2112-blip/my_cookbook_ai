import 'package:flutter/material.dart';
import '../models/recipe_tag.dart';

class TagChip extends StatelessWidget {
  final RecipeTag tag;
  final bool selected;
  final VoidCallback onTap;

  const TagChip({
    super.key,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        tag.icon,
        size: 18,
        color: selected
            ? Colors.white
            : tag.color,
      ),
      label: Text(tag.name),
      selectedColor: tag.color,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}