import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'recipe_page.dart';

class IngredientFinderPage extends StatefulWidget {
  const IngredientFinderPage({super.key});

  @override
  State<IngredientFinderPage> createState() => _IngredientFinderPageState();
}

class _IngredientFinderPageState extends State<IngredientFinderPage> {
  final TextEditingController ingredientsController = TextEditingController();

  List<Map<String, dynamic>> allRecipes = [];
  List<_IngredientMatch> matchingRecipes = [];

  bool isLoading = true;
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();

    loadRecipes();
  }

  Future<void> loadRecipes() async {
    final Box cookbookListBox = Hive.isBoxOpen('cookbooks')
        ? Hive.box('cookbooks')
        : await Hive.openBox('cookbooks');

    final List<Map<String, dynamic>> loadedRecipes = [];

    for (final dynamic cookbookValue in cookbookListBox.values) {
      final String cookbookName = cookbookValue.toString().trim();

      if (cookbookName.isEmpty) {
        continue;
      }

      final Box cookbookBox = Hive.isBoxOpen(cookbookName)
          ? Hive.box(cookbookName)
          : await Hive.openBox(cookbookName);

      for (final dynamic recipeKey in cookbookBox.keys) {
        final dynamic savedRecipe = cookbookBox.get(recipeKey);

        if (savedRecipe is! Map) {
          continue;
        }

        final Map<String, dynamic> recipe = Map<String, dynamic>.from(
          savedRecipe,
        );

        recipe['name'] = recipe['name']?.toString() ?? recipeKey.toString();

        recipe['cookbookName'] = cookbookName;

        loadedRecipes.add(recipe);
      }
    }

    loadedRecipes.sort((
      Map<String, dynamic> first,
      Map<String, dynamic> second,
    ) {
      final String firstName = first['name']?.toString().toLowerCase() ?? '';

      final String secondName = second['name']?.toString().toLowerCase() ?? '';

      return firstName.compareTo(secondName);
    });

    if (!mounted) return;

    setState(() {
      allRecipes = loadedRecipes;
      isLoading = false;
    });
  }

  Future<void> loadFromPantry() async {
    final Box pantryBox = Hive.isBoxOpen('pantry')
        ? Hive.box('pantry')
        : await Hive.openBox('pantry');

    final List<String> inStockIngredients =
        pantryBox.keys
            .where((dynamic key) => pantryBox.get(key) == true)
            .map((dynamic key) => key.toString().trim())
            .where((String ingredient) => ingredient.isNotEmpty)
            .toList()
          ..sort((String first, String second) {
            return first.toLowerCase().compareTo(second.toLowerCase());
          });

    if (!mounted) return;

    if (inStockIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No in-stock pantry ingredients found.')),
      );

      return;
    }

    ingredientsController.text = inStockIngredients.join(', ');

    searchRecipes();
  }

  void searchRecipes() {
    final List<String> availableIngredients = _parseEnteredIngredients(
      ingredientsController.text,
    );

    if (availableIngredients.isEmpty) {
      setState(() {
        matchingRecipes = [];
        hasSearched = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one ingredient.')),
      );

      return;
    }

    final List<_IngredientMatch> results = [];

    for (final Map<String, dynamic> recipe in allRecipes) {
      final String ingredientsText =
          recipe['ingredients']?.toString().trim() ?? '';

      if (ingredientsText.isEmpty) {
        continue;
      }

      final List<String> recipeIngredients = _parseRecipeIngredients(
        ingredientsText,
      );

      if (recipeIngredients.isEmpty) {
        continue;
      }

      final List<String> matchedIngredients = [];
      final List<String> missingIngredients = [];

      for (final String recipeIngredient in recipeIngredients) {
        final bool isAvailable = availableIngredients.any((
          String availableIngredient,
        ) {
          return _ingredientsMatch(recipeIngredient, availableIngredient);
        });

        if (isAvailable) {
          matchedIngredients.add(recipeIngredient);
        } else {
          missingIngredients.add(recipeIngredient);
        }
      }

      if (matchedIngredients.isEmpty) {
        continue;
      }

      final double matchPercentage =
          matchedIngredients.length / recipeIngredients.length;

      results.add(
        _IngredientMatch(
          recipe: recipe,
          matchedIngredients: matchedIngredients,
          missingIngredients: missingIngredients,
          matchPercentage: matchPercentage,
        ),
      );
    }

    results.sort((_IngredientMatch first, _IngredientMatch second) {
      final int percentageComparison = second.matchPercentage.compareTo(
        first.matchPercentage,
      );

      if (percentageComparison != 0) {
        return percentageComparison;
      }

      final int missingComparison = first.missingIngredients.length.compareTo(
        second.missingIngredients.length,
      );

      if (missingComparison != 0) {
        return missingComparison;
      }

      return first.recipeName.toLowerCase().compareTo(
        second.recipeName.toLowerCase(),
      );
    });

    setState(() {
      matchingRecipes = results;
      hasSearched = true;
    });
  }

  List<String> _parseEnteredIngredients(String value) {
    return value
        .split(RegExp(r'[,\n;]+'))
        .map(_normaliseIngredient)
        .where((String ingredient) => ingredient.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> _parseRecipeIngredients(String value) {
    return value
        .split('\n')
        .map((String ingredient) => ingredient.trim())
        .where((String ingredient) => ingredient.isNotEmpty)
        .toList();
  }

  String _normaliseIngredient(String value) {
    String normalised = value
        .toLowerCase()
        .replaceAll(RegExp(r'[\(\)\[\]\{\}]'), ' ')
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    normalised = normalised.replaceFirst(RegExp(r'^\d+([\/.]\d+)?\s*'), '');

    const List<String> measurements = [
      'g',
      'kg',
      'ml',
      'l',
      'tsp',
      'tbsp',
      'teaspoon',
      'teaspoons',
      'tablespoon',
      'tablespoons',
      'cup',
      'cups',
      'oz',
      'lb',
      'lbs',
      'pinch',
      'handful',
      'slice',
      'slices',
      'clove',
      'cloves',
      'tin',
      'tins',
      'can',
      'cans',
      'packet',
      'packets',
    ];

    final List<String> words = normalised.split(' ');

    while (words.isNotEmpty && measurements.contains(words.first)) {
      words.removeAt(0);
    }

    return words.join(' ').trim();
  }

  bool _ingredientsMatch(String recipeIngredient, String availableIngredient) {
    final String normalisedRecipe = _normaliseIngredient(recipeIngredient);

    final String normalisedAvailable = _normaliseIngredient(
      availableIngredient,
    );

    if (normalisedRecipe.isEmpty || normalisedAvailable.isEmpty) {
      return false;
    }

    if (normalisedRecipe == normalisedAvailable) {
      return true;
    }

    if (normalisedRecipe.contains(normalisedAvailable) ||
        normalisedAvailable.contains(normalisedRecipe)) {
      return true;
    }

    final Set<String> recipeWords = normalisedRecipe
        .split(' ')
        .where((String word) => word.length > 2)
        .toSet();

    final Set<String> availableWords = normalisedAvailable
        .split(' ')
        .where((String word) => word.length > 2)
        .toSet();

    return recipeWords.intersection(availableWords).isNotEmpty;
  }

  void clearIngredients() {
    ingredientsController.clear();

    setState(() {
      matchingRecipes = [];
      hasSearched = false;
    });
  }

  Future<void> openRecipe(_IngredientMatch match) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          cookbookName: match.cookbookName,
          recipeName: match.recipeName,
        ),
      ),
    );

    if (!mounted) return;

    await loadRecipes();

    if (ingredientsController.text.trim().isNotEmpty) {
      searchRecipes();
    }
  }

  Uint8List? getRecipePhoto(Map<String, dynamic> recipe) {
    final dynamic savedPhoto = recipe['photo'];

    if (savedPhoto is Uint8List) {
      return savedPhoto;
    }

    if (savedPhoto is List<int>) {
      return Uint8List.fromList(savedPhoto);
    }

    return null;
  }

  @override
  void dispose() {
    ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(title: const Text('What Can I Make?')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              children: [
                const _IngredientFinderHeader(),
                const SizedBox(height: 18),
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available ingredients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter ingredients separated by commas or put each one on a new line.',
                          style: TextStyle(
                            color: Color(0xFF7C7470),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: loadFromPantry,
                            icon: const Icon(Icons.kitchen_outlined),
                            label: const Text('Use My Pantry'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: ingredientsController,
                          minLines: 4,
                          maxLines: 8,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Chicken, onion, garlic, rice',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 72),
                              child: Icon(Icons.shopping_basket_outlined),
                            ),
                            suffixIcon: ingredientsController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    onPressed: clearIngredients,
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                          onSubmitted: (_) {
                            searchRecipes();
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: searchRecipes,
                            icon: const Icon(Icons.search),
                            label: const Text('Find Recipes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (!hasSearched)
                  const _IngredientFinderEmptyState(
                    icon: Icons.restaurant_menu,
                    title: 'Find recipes from your cookbooks',
                    message:
                        'Enter what you have available or load the ingredients currently marked in stock in your pantry.',
                  )
                else if (matchingRecipes.isEmpty)
                  const _IngredientFinderEmptyState(
                    icon: Icons.search_off,
                    title: 'No matching recipes',
                    message:
                        'Try adding more ingredients or using broader names such as chicken, pasta or cheese.',
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${matchingRecipes.length} '
                          '${matchingRecipes.length == 1 ? 'recipe' : 'recipes'} found',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final _IngredientMatch match in matchingRecipes)
                    _IngredientMatchCard(
                      match: match,
                      photo: getRecipePhoto(match.recipe),
                      onTap: () {
                        openRecipe(match);
                      },
                    ),
                ],
              ],
            ),
    );
  }
}

class _IngredientMatch {
  final Map<String, dynamic> recipe;
  final List<String> matchedIngredients;
  final List<String> missingIngredients;
  final double matchPercentage;

  const _IngredientMatch({
    required this.recipe,
    required this.matchedIngredients,
    required this.missingIngredients,
    required this.matchPercentage,
  });

  String get recipeName {
    return recipe['name']?.toString() ?? 'Unnamed recipe';
  }

  String get cookbookName {
    return recipe['cookbookName']?.toString() ?? '';
  }

  int get percentage {
    return (matchPercentage * 100).round();
  }
}

class _IngredientFinderHeader extends StatelessWidget {
  const _IngredientFinderHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EFE5),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                color: Color(0xFF56715A),
                size: 29,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cook with what you have',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Recipes are ranked by how many of their ingredients match what you have available.',
                    style: TextStyle(color: Color(0xFF7C7470), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientMatchCard extends StatelessWidget {
  final _IngredientMatch match;
  final Uint8List? photo;
  final VoidCallback onTap;

  const _IngredientMatchCard({
    required this.match,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color matchColor = match.percentage >= 80
        ? const Color(0xFF56715A)
        : match.percentage >= 50
        ? const Color(0xFF9A6824)
        : const Color(0xFFD96C3F);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: photo == null
                      ? Container(
                          color: const Color(0xFFFFE3D5),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Color(0xFFD96C3F),
                            size: 34,
                          ),
                        )
                      : Image.memory(photo!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            match.recipeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: matchColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${match.percentage}%',
                            style: TextStyle(
                              color: matchColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      match.cookbookName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7C7470),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${match.matchedIngredients.length} ingredients matched',
                      style: TextStyle(
                        color: matchColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (match.missingIngredients.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        'Missing: ${match.missingIngredients.take(3).join(', ')}'
                        '${match.missingIngredients.length > 3 ? '…' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF7C7470)),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8A817C)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientFinderEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _IngredientFinderEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      child: Column(
        children: [
          Icon(icon, size: 70, color: const Color(0xFFAAA19C)),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: Color(0xFF7C7470),
            ),
          ),
        ],
      ),
    );
  }
}
