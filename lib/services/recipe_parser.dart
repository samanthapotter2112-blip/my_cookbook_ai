class ParsedRecipe {
  String name = '';
  String prepTime = '';
  String cookTime = '';
  String servings = '';
  String ingredients = '';
  String method = '';
}

class RecipeParser {
  static ParsedRecipe parse(String text) {
    final recipe = ParsedRecipe();

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return recipe;
    }

    recipe.name = lines.first;

    bool readingIngredients = false;
    bool readingMethod = false;

    final ingredients = <String>[];
    final method = <String>[];

    for (final line in lines.skip(1)) {
      final lower = line.toLowerCase();

      if (lower.contains('prep')) {
        recipe.prepTime = line;
      }

      if (lower.contains('cook')) {
        recipe.cookTime = line;
      }

      if (lower.contains('serves') ||
          lower.contains('servings') ||
          lower.contains('makes')) {
        recipe.servings = line;
      }

      if (lower == 'ingredients' ||
          lower.startsWith('ingredients')) {
        readingIngredients = true;
        readingMethod = false;
        continue;
      }

      if (lower == 'method' ||
          lower == 'directions' ||
          lower == 'instructions') {
        readingMethod = true;
        readingIngredients = false;
        continue;
      }

      if (readingIngredients) {
        ingredients.add(line);
      }

      if (readingMethod) {
        method.add(line);
      }
    }

    recipe.ingredients = ingredients.join('\n');
    recipe.method = method.join('\n');

    return recipe;
  }
}