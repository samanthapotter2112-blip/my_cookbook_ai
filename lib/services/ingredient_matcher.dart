class IngredientMatcher {
  static const Map<String, String> _aliases = {
    'cherry tomato': 'tomato',
    'cherry tomatoes': 'tomato',
    'plum tomato': 'tomato',
    'plum tomatoes': 'tomato',
    'tinned tomato': 'tomato',
    'tinned tomatoes': 'tomato',
    'canned tomato': 'tomato',
    'canned tomatoes': 'tomato',

    'red onion': 'onion',
    'red onions': 'onion',
    'white onion': 'onion',
    'white onions': 'onion',
    'spring onion': 'onion',
    'spring onions': 'onion',

    'chicken breast': 'chicken',
    'chicken breasts': 'chicken',
    'chicken thigh': 'chicken',
    'chicken thighs': 'chicken',

    'caster sugar': 'sugar',
    'granulated sugar': 'sugar',
    'brown sugar': 'sugar',
    'icing sugar': 'sugar',

    'olive oil': 'oil',
    'vegetable oil': 'oil',
    'sunflower oil': 'oil',

    'red pepper': 'pepper',
    'red peppers': 'pepper',
    'green pepper': 'pepper',
    'green peppers': 'pepper',
    'yellow pepper': 'pepper',
    'yellow peppers': 'pepper',
    'bell pepper': 'pepper',
    'bell peppers': 'pepper',

    'self raising flour': 'flour',
    'self-raising flour': 'flour',
    'plain flour': 'flour',
    'strong flour': 'flour',

    'double cream': 'cream',
    'single cream': 'cream',
    'heavy cream': 'cream',

    'parmesan cheese': 'parmesan',
    'cheddar cheese': 'cheddar',
    'mozzarella cheese': 'mozzarella',
  };

  static String normalise(String value) {
    String ingredient = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    ingredient = _removeQuantityAndMeasurements(
      ingredient,
    );

    if (_aliases.containsKey(ingredient)) {
      return _aliases[ingredient]!;
    }

    for (final MapEntry<String, String> alias
        in _aliases.entries) {
      if (ingredient.contains(alias.key)) {
        return alias.value;
      }
    }

    return _makeSingular(ingredient);
  }

  static String _removeQuantityAndMeasurements(
    String value,
  ) {
    final RegExp measurementPattern = RegExp(
      r'^\s*'
      r'(\d+([./]\d+)?|\d+\s+\d+/\d+)?\s*'
      r'(g|kg|mg|ml|l|tsp|tbsp|teaspoon|teaspoons|'
      r'tablespoon|tablespoons|cup|cups|oz|lb|lbs)?\s*',
    );

    return value
        .replaceFirst(measurementPattern, '')
        .trim();
  }

  static String _makeSingular(String value) {
    if (value.endsWith('ies') && value.length > 3) {
      return '${value.substring(0, value.length - 3)}y';
    }

    if (value.endsWith('oes') && value.length > 3) {
      return value.substring(0, value.length - 2);
    }

    if (value.endsWith('ses') && value.length > 3) {
      return value.substring(0, value.length - 2);
    }

    if (value.endsWith('s') &&
        !value.endsWith('ss') &&
        value.length > 2) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }

  static bool matches({
    required String enteredIngredient,
    required String recipeIngredients,
  }) {
    final String entered =
        normalise(enteredIngredient);

    if (entered.isEmpty) return false;

    final List<String> recipeLines =
        recipeIngredients
            .split('\n')
            .map(normalise)
            .where(
              (String item) => item.isNotEmpty,
            )
            .toList();

    return recipeLines.any(
      (String recipeIngredient) {
        return recipeIngredient.contains(entered) ||
            entered.contains(recipeIngredient);
      },
    );
  }
}