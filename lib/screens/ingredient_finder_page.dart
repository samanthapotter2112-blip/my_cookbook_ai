import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/ingredient_matcher.dart';
import 'recipe_page.dart';

class IngredientFinderPage extends StatefulWidget {
  const IngredientFinderPage({super.key});

  @override
  State<IngredientFinderPage> createState() =>
      _IngredientFinderPageState();
}

class _IngredientFinderPageState
    extends State<IngredientFinderPage> {
  final TextEditingController ingredientsController =
      TextEditingController();

  List<Map<String, dynamic>> allRecipes = [];
  List<Map<String, dynamic>> matchingRecipes = [];

  bool isLoading = true;
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();

    ingredientsController.addListener(
      refreshPage,
    );

    loadRecipes();
  }

  void refreshPage() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> loadRecipes() async {
    final Box cookbookListBox =
        Hive.isBoxOpen('cookbooks')
            ? Hive.box('cookbooks')
            : await Hive.openBox('cookbooks');

    final List<Map<String, dynamic>> loadedRecipes = [];

    for (final dynamic cookbookValue
        in cookbookListBox.values) {
      final String cookbookName =
          cookbookValue.toString().trim();

      if (cookbookName.isEmpty) continue;

      final Box cookbookBox =
          Hive.isBoxOpen(cookbookName)
              ? Hive.box(cookbookName)
              : await Hive.openBox(cookbookName);

      for (final dynamic recipeKey
          in cookbookBox.keys) {
        final dynamic savedRecipe =
            cookbookBox.get(recipeKey);

        if (savedRecipe is! Map) continue;

        final Map<String, dynamic> recipe =
            Map<String, dynamic>.from(
          savedRecipe,
        );

        recipe['name'] =
            recipe['name']?.toString() ??
                recipeKey.toString();

        recipe['cookbookName'] =
            cookbookName;

        loadedRecipes.add(recipe);
      }
    }

    if (!mounted) return;

    setState(() {
      allRecipes = loadedRecipes;
      isLoading = false;
    });
  }

  List<String> getEnteredIngredients() {
    return ingredientsController.text
        .split(RegExp(r'[\n,]+'))
        .map(
          (String ingredient) =>
              ingredient.trim(),
        )
        .where(
          (String ingredient) =>
              ingredient.isNotEmpty,
        )
        .toSet()
        .toList();
  }

  List<String> getRecipeIngredientLines(
    String ingredients,
  ) {
    return ingredients
        .split('\n')
        .map(
          (String ingredient) =>
              ingredient.trim(),
        )
        .where(
          (String ingredient) =>
              ingredient.isNotEmpty,
        )
        .toList();
  }

  void findRecipes() {
    final List<String> enteredIngredients =
        getEnteredIngredients();

    if (enteredIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter at least one ingredient.',
          ),
        ),
      );

      return;
    }

    final List<Map<String, dynamic>> results = [];

    for (final Map<String, dynamic> recipe
        in allRecipes) {
      final String recipeIngredients =
          recipe['ingredients']
                  ?.toString()
                  .trim() ??
              '';

      if (recipeIngredients.isEmpty) continue;

      final List<String> matchedIngredients = [];
      final List<String> missingIngredients = [];

      for (final String enteredIngredient
          in enteredIngredients) {
        final bool matches =
            IngredientMatcher.matches(
          enteredIngredient:
              enteredIngredient,
          recipeIngredients:
              recipeIngredients,
        );

        if (matches) {
          matchedIngredients.add(
            enteredIngredient,
          );
        }
      }

      if (matchedIngredients.isEmpty) continue;

      final List<String> recipeIngredientLines =
          getRecipeIngredientLines(
        recipeIngredients,
      );

      for (final String recipeIngredient
          in recipeIngredientLines) {
        final bool available =
            enteredIngredients.any(
          (String enteredIngredient) {
            return IngredientMatcher.matches(
              enteredIngredient:
                  enteredIngredient,
              recipeIngredients:
                  recipeIngredient,
            );
          },
        );

        if (!available) {
          missingIngredients.add(
            recipeIngredient,
          );
        }
      }

      final double matchPercentage =
          enteredIngredients.isEmpty
              ? 0
              : matchedIngredients.length /
                  enteredIngredients.length;

      final Map<String, dynamic> result =
          Map<String, dynamic>.from(
        recipe,
      );

      result['matchedIngredients'] =
          matchedIngredients;

      result['missingIngredients'] =
          missingIngredients;

      result['matchCount'] =
          matchedIngredients.length;

      result['enteredCount'] =
          enteredIngredients.length;

      result['matchPercentage'] =
          matchPercentage;

      results.add(result);
    }

    results.sort(
      (
        Map<String, dynamic> first,
        Map<String, dynamic> second,
      ) {
        final double firstPercentage =
            first['matchPercentage'] as double;

        final double secondPercentage =
            second['matchPercentage'] as double;

        if (firstPercentage !=
            secondPercentage) {
          return secondPercentage.compareTo(
            firstPercentage,
          );
        }

        final int firstMissing =
            (first['missingIngredients']
                    as List)
                .length;

        final int secondMissing =
            (second['missingIngredients']
                    as List)
                .length;

        if (firstMissing != secondMissing) {
          return firstMissing.compareTo(
            secondMissing,
          );
        }

        final String firstName =
            first['name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final String secondName =
            second['name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return firstName.compareTo(
          secondName,
        );
      },
    );

    setState(() {
      matchingRecipes = results;
      hasSearched = true;
    });
  }

  void clearSearch() {
    ingredientsController.clear();

    setState(() {
      matchingRecipes = [];
      hasSearched = false;
    });
  }

  Uint8List? getRecipePhoto(
    Map<String, dynamic> recipe,
  ) {
    final dynamic savedPhoto = recipe['photo'];

    if (savedPhoto is Uint8List) {
      return savedPhoto;
    }

    if (savedPhoto is List<int>) {
      return Uint8List.fromList(
        savedPhoto,
      );
    }

    return null;
  }

  Future<void> openRecipe(
    Map<String, dynamic> recipe,
  ) async {
    final String recipeName =
        recipe['name']?.toString() ??
            'Unnamed recipe';

    final String cookbookName =
        recipe['cookbookName']
                ?.toString() ??
            '';

    if (cookbookName.isEmpty) return;

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          cookbookName: cookbookName,
          recipeName: recipeName,
        ),
      ),
    );

    if (!mounted) return;

    await loadRecipes();

    if (hasSearched) {
      findRecipes();
    }
  }

  @override
  void dispose() {
    ingredientsController.removeListener(
      refreshPage,
    );

    ingredientsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasIngredients =
        ingredientsController.text
            .trim()
            .isNotEmpty;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text(
          'What Can I Make?',
        ),
        actions: [
          if (hasIngredients)
            IconButton(
              tooltip: 'Clear',
              onPressed: clearSearch,
              icon: const Icon(
                Icons.clear,
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                30,
              ),
              children: [
                _IngredientEntryCard(
                  controller:
                      ingredientsController,
                  onSearch: findRecipes,
                ),
                const SizedBox(height: 22),
                if (!hasSearched)
                  const _IngredientHelp()
                else if (matchingRecipes
                    .isEmpty)
                  const _NoMatches()
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${matchingRecipes.length} '
                          '${matchingRecipes.length == 1 ? 'recipe' : 'recipes'} found',
                          style:
                              const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: clearSearch,
                        child:
                            const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...matchingRecipes.map(
                    (
                      Map<String, dynamic>
                          recipe,
                    ) {
                      return _IngredientResultCard(
                        recipeName:
                            recipe['name']
                                    ?.toString() ??
                                'Unnamed recipe',
                        cookbookName:
                            recipe['cookbookName']
                                    ?.toString() ??
                                '',
                        photo:
                            getRecipePhoto(
                          recipe,
                        ),
                        matchedIngredients:
                            List<String>.from(
                          recipe[
                              'matchedIngredients'],
                        ),
                        missingIngredients:
                            List<String>.from(
                          recipe[
                              'missingIngredients'],
                        ),
                        matchCount:
                            recipe['matchCount']
                                as int,
                        enteredCount:
                            recipe[
                                'enteredCount']
                                as int,
                        onTap: () {
                          openRecipe(recipe);
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }
}

class _IngredientEntryCard
    extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const _IngredientEntryCard({
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFE6EFE5,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .shopping_basket_outlined,
                    color:
                        Color(0xFF56715A),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingredients you have',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Enter one per line or separate them with commas.',
                        style: TextStyle(
                          color:
                              Color(0xFF7C7470),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              minLines: 6,
              maxLines: 12,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration:
                  const InputDecoration(
                hintText:
                    'Chicken\nRice\nPeppers\nCream',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(
                  Icons.auto_awesome,
                ),
                label: const Text(
                  'Find Recipes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientResultCard
    extends StatelessWidget {
  final String recipeName;
  final String cookbookName;
  final Uint8List? photo;
  final List<String> matchedIngredients;
  final List<String> missingIngredients;
  final int matchCount;
  final int enteredCount;
  final VoidCallback onTap;

  const _IngredientResultCard({
    required this.recipeName,
    required this.cookbookName,
    required this.photo,
    required this.matchedIngredients,
    required this.missingIngredients,
    required this.matchCount,
    required this.enteredCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage =
        enteredCount == 0
            ? 0
            : matchCount / enteredCount;

    final bool completeMatch =
        matchCount == enteredCount;

    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(16),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: photo == null
                          ? Container(
                              color:
                                  const Color(
                                0xFFE6EFE5,
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .restaurant_menu,
                                size: 36,
                                color: Color(
                                  0xFF56715A,
                                ),
                              ),
                            )
                          : Image.memory(
                              photo!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Expanded(
                              child: Text(
                                recipeName,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                            if (completeMatch)
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFE6EFE5,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),
                                ),
                                child:
                                    const Text(
                                  'Best match',
                                  style:
                                      TextStyle(
                                    fontSize: 11,
                                    color: Color(
                                      0xFF56715A,
                                    ),
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          cookbookName,
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF7C7470),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 11),
                        LinearProgressIndicator(
                          value: percentage,
                          minHeight: 7,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '$matchCount of $enteredCount ingredients matched',
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                Color(0xFF6F6864),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color:
                        Color(0xFF8A817C),
                  ),
                ],
              ),
              if (matchedIngredients
                  .isNotEmpty) ...[
                const SizedBox(height: 14),
                _IngredientList(
                  title: 'You have',
                  icon:
                      Icons.check_circle_outline,
                  ingredients:
                      matchedIngredients,
                  backgroundColor:
                      const Color(0xFFE6EFE5),
                  foregroundColor:
                      const Color(0xFF56715A),
                ),
              ],
              if (missingIngredients
                  .isNotEmpty) ...[
                const SizedBox(height: 10),
                _IngredientList(
                  title: 'May still need',
                  icon:
                      Icons.shopping_cart_outlined,
                  ingredients:
                      missingIngredients,
                  backgroundColor:
                      const Color(0xFFFFEEE5),
                  foregroundColor:
                      const Color(0xFFD96C3F),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> ingredients;
  final Color backgroundColor;
  final Color foregroundColor;

  const _IngredientList({
    required this.title,
    required this.icon,
    required this.ingredients,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> visibleIngredients =
        ingredients.take(5).toList();

    final int hiddenCount =
        ingredients.length -
            visibleIngredients.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: foregroundColor,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            visibleIngredients.join(' • '),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor,
              height: 1.35,
            ),
          ),
          if (hiddenCount > 0) ...[
            const SizedBox(height: 5),
            Text(
              '+$hiddenCount more',
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IngredientHelp extends StatelessWidget {
  const _IngredientHelp();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Color(0xFFAAA19C),
          ),
          SizedBox(height: 16),
          Text(
            'Use what you already have',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 9),
          Text(
            'The search understands common variations, '
            'such as chicken breast and chicken, or '
            'cherry tomatoes and tomatoes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7C7470),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Color(0xFFAAA19C),
          ),
          SizedBox(height: 16),
          Text(
            'No matching recipes',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 9),
          Text(
            'Try adding more ingredients or '
            'using simpler names.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7C7470),
            ),
          ),
        ],
      ),
    );
  }
}