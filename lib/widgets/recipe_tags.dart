import 'package:flutter/material.dart';

class RecipeTags extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  const RecipeTags({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    this.enabled = true,
  });

  static const List<_RecipeTagOption> _options = [
    _RecipeTagOption(
      name: 'Vegetarian',
      icon: Icons.eco_outlined,
    ),
    _RecipeTagOption(
      name: 'Vegan',
      icon: Icons.spa_outlined,
    ),
    _RecipeTagOption(
      name: 'Chicken',
      icon: Icons.restaurant_outlined,
    ),
    _RecipeTagOption(
      name: 'Beef',
      icon: Icons.restaurant_outlined,
    ),
    _RecipeTagOption(
      name: 'Fish',
      icon: Icons.set_meal_outlined,
    ),
    _RecipeTagOption(
      name: 'Pasta',
      icon: Icons.ramen_dining_outlined,
    ),
    _RecipeTagOption(
      name: 'Curry',
      icon: Icons.rice_bowl_outlined,
    ),
    _RecipeTagOption(
      name: 'Soup',
      icon: Icons.soup_kitchen_outlined,
    ),
    _RecipeTagOption(
      name: 'Dessert',
      icon: Icons.cake_outlined,
    ),
    _RecipeTagOption(
      name: 'Baking',
      icon: Icons.bakery_dining_outlined,
    ),
    _RecipeTagOption(
      name: 'Breakfast',
      icon: Icons.free_breakfast_outlined,
    ),
    _RecipeTagOption(
      name: 'Lunch',
      icon: Icons.lunch_dining_outlined,
    ),
    _RecipeTagOption(
      name: 'Dinner',
      icon: Icons.dinner_dining_outlined,
    ),
    _RecipeTagOption(
      name: 'Quick',
      icon: Icons.bolt_outlined,
    ),
    _RecipeTagOption(
      name: 'Freezer Friendly',
      icon: Icons.ac_unit_outlined,
    ),
    _RecipeTagOption(
      name: 'Meal Prep',
      icon: Icons.inventory_2_outlined,
    ),
    _RecipeTagOption(
      name: 'Air Fryer',
      icon: Icons.air_outlined,
    ),
    _RecipeTagOption(
      name: 'Slow Cooker',
      icon: Icons.hourglass_bottom_outlined,
    ),
  ];

  void toggleTag(String tagName) {
    if (!enabled) return;

    final List<String> updatedTags =
        List<String>.from(selectedTags);

    if (updatedTags.contains(tagName)) {
      updatedTags.remove(tagName);
    } else {
      updatedTags.add(tagName);
    }

    onChanged(updatedTags);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: _options.map(
        (_RecipeTagOption option) {
          final bool isSelected =
              selectedTags.contains(option.name);

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              option.icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFFD96C3F)
                  : const Color(0xFF7C7470),
            ),
            label: Text(option.name),
            onSelected: enabled
                ? (_) {
                    toggleTag(option.name);
                  }
                : null,
            selectedColor:
                const Color(0xFFFFE3D5),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFD96C3F)
                  : const Color(0xFFE0D8D3),
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? const Color(0xFF9D4528)
                  : const Color(0xFF5F5854),
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),
          );
        },
      ).toList(),
    );
  }
}

class _RecipeTagOption {
  final String name;
  final IconData icon;

  const _RecipeTagOption({
    required this.name,
    required this.icon,
  });
}