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
    final ParsedRecipe recipe = ParsedRecipe();

    final List<String> lines = _cleanText(text);

    if (lines.isEmpty) {
      return recipe;
    }

    recipe.name = _findRecipeName(lines);
    recipe.prepTime = _findPrepTime(lines);
    recipe.cookTime = _findCookTime(lines);
    recipe.servings = _findServings(lines);

    final int ingredientsHeadingIndex = _findHeadingIndex(
      lines,
      _isIngredientsHeading,
    );

    final int methodHeadingIndex = _findHeadingIndex(
      lines,
      _isMethodHeading,
    );

    final List<String> ingredients = <String>[];
    final List<String> method = <String>[];

    if (ingredientsHeadingIndex != -1 || methodHeadingIndex != -1) {
      _parseUsingHeadings(
        lines: lines,
        ingredientsHeadingIndex: ingredientsHeadingIndex,
        methodHeadingIndex: methodHeadingIndex,
        ingredients: ingredients,
        method: method,
      );
    }

    if (ingredients.isEmpty || method.isEmpty) {
      _parseUsingLinePatterns(
        lines: lines,
        recipeName: recipe.name,
        existingIngredients: ingredients,
        existingMethod: method,
      );
    }

    recipe.ingredients = _cleanIngredients(ingredients).join('\n');
    recipe.method = _cleanMethod(method).join('\n');

    return recipe;
  }

  static List<String> _cleanText(String text) {
    String cleanedText = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00A0', ' ')
        .replaceAll('•', '\n• ')
        .replaceAll('●', '\n• ')
        .replaceAll('▪', '\n• ')
        .replaceAll('–', '-')
        .replaceAll('—', '-');

    final List<String> rawLines = cleanedText.split('\n');

    final List<String> cleanedLines = <String>[];

    for (String line in rawLines) {
      line = line
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r'^\s*[|¦]+\s*'), '')
          .replaceAll(RegExp(r'\s*[|¦]+\s*$'), '')
          .trim();

      if (line.isEmpty) {
        continue;
      }

      line = _correctCommonOcrErrors(line);

      if (line.isNotEmpty) {
        cleanedLines.add(line);
      }
    }

    return cleanedLines;
  }

  static String _correctCommonOcrErrors(String line) {
    String corrected = line;

    final Map<RegExp, String> replacements = <RegExp, String>{
      RegExp(r'\bingredlents\b', caseSensitive: false): 'Ingredients',
      RegExp(r'\bingredlents\b', caseSensitive: false): 'Ingredients',
      RegExp(r'\bingred1ents\b', caseSensitive: false): 'Ingredients',
      RegExp(r'\bingredienfs\b', caseSensitive: false): 'Ingredients',
      RegExp(r'\bmeth0d\b', caseSensitive: false): 'Method',
      RegExp(r'\bmethed\b', caseSensitive: false): 'Method',
      RegExp(r'\bdirectlons\b', caseSensitive: false): 'Directions',
      RegExp(r'\binstructlons\b', caseSensitive: false): 'Instructions',
      RegExp(r'\bpreparatlon\b', caseSensitive: false): 'Preparation',
      RegExp(r'\bcooklng\b', caseSensitive: false): 'Cooking',
      RegExp(r'\bservlngs\b', caseSensitive: false): 'Servings',
      RegExp(r'\bserves(\d+)\b', caseSensitive: false): 'Serves \$1',
      RegExp(r'\bservings(\d+)\b', caseSensitive: false): 'Servings \$1',
      RegExp(r'\bmakes(\d+)\b', caseSensitive: false): 'Makes \$1',
      RegExp(r'(?<=\d)[oO](?=\s*(?:g|ml|cm)\b)'): '0',
    };

    for (final MapEntry<RegExp, String> replacement
        in replacements.entries) {
      corrected = corrected.replaceAll(
        replacement.key,
        replacement.value,
      );
    }

    return corrected.trim();
  }

  static String _findRecipeName(List<String> lines) {
    for (int index = 0; index < lines.length && index < 8; index++) {
      final String line = lines[index];

      if (_shouldIgnoreForRecipeName(line)) {
        continue;
      }

      if (line.length < 3 || line.length > 100) {
        continue;
      }

      return _toTitleCaseIfNeeded(line);
    }

    return lines.first;
  }

  static bool _shouldIgnoreForRecipeName(String line) {
    final String lower = line.toLowerCase();

    return _isIngredientsHeading(line) ||
        _isMethodHeading(line) ||
        _looksLikeTimingLine(lower) ||
        _looksLikeServingsLine(lower) ||
        _looksLikeIngredient(line) ||
        _looksLikeMethod(line) ||
        lower.startsWith('recipe') ||
        lower.startsWith('page ');
  }

  static String _findPrepTime(List<String> lines) {
    for (final String line in lines) {
      final String lower = line.toLowerCase();

      if (lower.contains('prep time') ||
          lower.contains('preparation time') ||
          lower.startsWith('prep:') ||
          lower.startsWith('preparation:')) {
        return _extractValueAfterLabel(
          line,
          <String>[
            'preparation time',
            'prep time',
            'preparation',
            'prep',
          ],
        );
      }
    }

    return '';
  }

  static String _findCookTime(List<String> lines) {
    for (final String line in lines) {
      final String lower = line.toLowerCase();

      if (lower.contains('cook time') ||
          lower.contains('cooking time') ||
          lower.startsWith('cook:') ||
          lower.startsWith('cooking:') ||
          lower.contains('baking time')) {
        return _extractValueAfterLabel(
          line,
          <String>[
            'cooking time',
            'baking time',
            'cook time',
            'cooking',
            'cook',
          ],
        );
      }
    }

    return '';
  }

  static String _findServings(List<String> lines) {
    final RegExp servingsPattern = RegExp(
      r'\b(?:serves|servings|makes|yield|portions?)\s*[:\-]?\s*([0-9]+(?:\s*[-–]\s*[0-9]+)?)',
      caseSensitive: false,
    );

    for (final String line in lines) {
      final RegExpMatch? match = servingsPattern.firstMatch(line);

      if (match != null) {
        return match.group(1)?.trim() ?? line;
      }
    }

    return '';
  }

  static String _extractValueAfterLabel(
    String line,
    List<String> labels,
  ) {
    String result = line;

    for (final String label in labels) {
      result = result.replaceFirst(
        RegExp(
          '^${RegExp.escape(label)}\\s*[:\\-]?\\s*',
          caseSensitive: false,
        ),
        '',
      );

      if (result != line) {
        break;
      }
    }

    result = result.trim();

    return result.isEmpty ? line.trim() : result;
  }

  static int _findHeadingIndex(
    List<String> lines,
    bool Function(String line) matcher,
  ) {
    for (int index = 0; index < lines.length; index++) {
      if (matcher(lines[index])) {
        return index;
      }
    }

    return -1;
  }

  static bool _isIngredientsHeading(String line) {
    final String normalised = _normaliseHeading(line);

    return normalised == 'ingredient' ||
        normalised == 'ingredients' ||
        normalised == 'you will need' ||
        normalised == 'what you need' ||
        normalised == 'for the recipe' ||
        normalised.startsWith('ingredients for');
  }

  static bool _isMethodHeading(String line) {
    final String normalised = _normaliseHeading(line);

    return normalised == 'method' ||
        normalised == 'directions' ||
        normalised == 'instructions' ||
        normalised == 'preparation' ||
        normalised == 'how to make' ||
        normalised == 'how to cook' ||
        normalised == 'steps';
  }

  static String _normaliseHeading(String line) {
    return line
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static void _parseUsingHeadings({
    required List<String> lines,
    required int ingredientsHeadingIndex,
    required int methodHeadingIndex,
    required List<String> ingredients,
    required List<String> method,
  }) {
    if (ingredientsHeadingIndex != -1) {
      final int ingredientsEnd =
          methodHeadingIndex > ingredientsHeadingIndex
              ? methodHeadingIndex
              : lines.length;

      for (
        int index = ingredientsHeadingIndex + 1;
        index < ingredientsEnd;
        index++
      ) {
        final String line = lines[index];

        if (_isMetadataLine(line)) {
          continue;
        }

        ingredients.add(line);
      }
    }

    if (methodHeadingIndex != -1) {
      for (
        int index = methodHeadingIndex + 1;
        index < lines.length;
        index++
      ) {
        final String line = lines[index];

        if (_isIngredientsHeading(line)) {
          break;
        }

        if (_isMetadataLine(line)) {
          continue;
        }

        method.add(line);
      }
    }
  }

  static void _parseUsingLinePatterns({
    required List<String> lines,
    required String recipeName,
    required List<String> existingIngredients,
    required List<String> existingMethod,
  }) {
    final List<String> detectedIngredients = <String>[];
    final List<String> detectedMethod = <String>[];

    bool methodHasStarted = false;

    for (final String line in lines) {
      if (line == recipeName ||
          _isIngredientsHeading(line) ||
          _isMethodHeading(line) ||
          _isMetadataLine(line)) {
        continue;
      }

      if (_looksLikeMethod(line)) {
        methodHasStarted = true;
        detectedMethod.add(line);
        continue;
      }

      if (!methodHasStarted && _looksLikeIngredient(line)) {
        detectedIngredients.add(line);
        continue;
      }

      if (methodHasStarted && line.length > 20) {
        detectedMethod.add(line);
      }
    }

    if (existingIngredients.isEmpty) {
      existingIngredients.addAll(detectedIngredients);
    }

    if (existingMethod.isEmpty) {
      existingMethod.addAll(detectedMethod);
    }
  }

  static bool _looksLikeIngredient(String line) {
    final String lower = line.toLowerCase().trim();

    final RegExp quantityPattern = RegExp(
      r'^(?:[-•*]\s*)?'
      r'(?:'
      r'\d+(?:[.,]\d+)?'
      r'|\d+\s*/\s*\d+'
      r'|[¼½¾⅓⅔⅛⅜⅝⅞]'
      r'|one|two|three|four|five|six'
      r')'
      r'\s*'
      r'(?:'
      r'kg|g|mg|lb|lbs|oz|ml|l|cl|'
      r'tsp|teaspoons?|tbsp|tablespoons?|'
      r'cups?|pinches?|handfuls?|cloves?|'
      r'slices?|pieces?|cans?|tins?|packets?|'
      r'sprigs?|bunches?'
      r')?\b',
      caseSensitive: false,
    );

    final RegExp descriptiveIngredientPattern = RegExp(
      r'^(?:[-•*]\s*)?'
      r'(?:a|an|some|few|half|quarter|pinch|dash|handful)\b',
      caseSensitive: false,
    );

    if (quantityPattern.hasMatch(lower) ||
        descriptiveIngredientPattern.hasMatch(lower)) {
      return true;
    }

    return lower.startsWith('salt') ||
        lower.startsWith('pepper') ||
        lower.startsWith('oil for') ||
        lower.startsWith('butter for') ||
        lower.startsWith('to serve') ||
        lower.startsWith('for serving') ||
        lower.startsWith('optional:');
  }

  static bool _looksLikeMethod(String line) {
    final String lower = line.toLowerCase().trim();

    if (RegExp(r'^\d+\s*[.)\-:]\s*').hasMatch(lower)) {
      return true;
    }

    final List<String> methodStarters = <String>[
      'add ',
      'arrange ',
      'bake ',
      'beat ',
      'blend ',
      'boil ',
      'brush ',
      'chill ',
      'combine ',
      'cook ',
      'cover ',
      'drain ',
      'fold ',
      'fry ',
      'grill ',
      'heat ',
      'knead ',
      'leave ',
      'mix ',
      'place ',
      'pour ',
      'preheat ',
      'reduce ',
      'remove ',
      'roast ',
      'season ',
      'serve ',
      'simmer ',
      'slice ',
      'spread ',
      'sprinkle ',
      'stir ',
      'transfer ',
      'whisk ',
    ];

    return methodStarters.any(lower.startsWith);
  }

  static bool _isMetadataLine(String line) {
    final String lower = line.toLowerCase();

    return _looksLikeTimingLine(lower) ||
        _looksLikeServingsLine(lower) ||
        lower.startsWith('difficulty') ||
        lower.startsWith('nutrition') ||
        lower.startsWith('calories') ||
        lower.startsWith('kcal') ||
        lower.startsWith('page ');
  }

  static bool _looksLikeTimingLine(String lower) {
    return lower.contains('prep time') ||
        lower.contains('preparation time') ||
        lower.contains('cook time') ||
        lower.contains('cooking time') ||
        lower.contains('baking time') ||
        lower.contains('total time') ||
        lower.startsWith('prep:') ||
        lower.startsWith('cook:');
  }

  static bool _looksLikeServingsLine(String lower) {
    return RegExp(
      r'\b(serves|servings|makes|yield|portions?)\b',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  static List<String> _cleanIngredients(List<String> ingredients) {
    final List<String> cleaned = <String>[];

    for (String ingredient in ingredients) {
      ingredient = ingredient
          .replaceFirst(RegExp(r'^[-•*]\s*'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (ingredient.isEmpty ||
          _isIngredientsHeading(ingredient) ||
          _isMethodHeading(ingredient) ||
          _isMetadataLine(ingredient)) {
        continue;
      }

      if (!cleaned.contains(ingredient)) {
        cleaned.add(ingredient);
      }
    }

    return cleaned;
  }

  static List<String> _cleanMethod(List<String> methodLines) {
    final List<String> cleaned = <String>[];

    for (String step in methodLines) {
      step = step
          .replaceFirst(RegExp(r'^[-•*]\s*'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (step.isEmpty ||
          _isIngredientsHeading(step) ||
          _isMethodHeading(step) ||
          _isMetadataLine(step)) {
        continue;
      }

      if (!cleaned.contains(step)) {
        cleaned.add(step);
      }
    }

    return cleaned;
  }

  static String _toTitleCaseIfNeeded(String text) {
    if (text != text.toUpperCase()) {
      return text;
    }

    return text
        .toLowerCase()
        .split(' ')
        .map((String word) {
          if (word.isEmpty) {
            return word;
          }

          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}