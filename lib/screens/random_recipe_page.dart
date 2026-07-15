import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'recipe_page.dart';

class RandomRecipePage extends StatefulWidget {
  const RandomRecipePage({super.key});

  @override
  State<RandomRecipePage> createState() =>
      _RandomRecipePageState();
}

class _RandomRecipePageState
    extends State<RandomRecipePage> {
  bool loading = true;

  Map<String, dynamic>? recipe;

  @override
  void initState() {
    super.initState();
    pickRecipe();
  }

  Future<void> pickRecipe() async {
    final cookbookList =
        Hive.box('cookbooks');

    final List<Map<String, dynamic>>
        recipes = [];

    for (final cookbook
        in cookbookList.values) {
      final box =
          Hive.isBoxOpen(cookbook)
              ? Hive.box(cookbook)
              : await Hive.openBox(
                  cookbook,
                );

      for (final key in box.keys) {
        final data = box.get(key);

        if (data is! Map) continue;

        recipes.add({
          'cookbook': cookbook,
          'recipe': key.toString(),
        });
      }
    }

    if (recipes.isEmpty) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      return;
    }

    recipe =
        recipes[Random().nextInt(recipes.length)];

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> openRecipe() async {
    if (recipe == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          cookbookName: recipe!['cookbook'],
          recipeName: recipe!['recipe'],
        ),
      ),
    );

    if (!mounted) return;

    pickRecipe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text(
          'Surprise Me',
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : recipe == null
              ? const Center(
                  child: Text(
                    'No recipes saved yet.',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                )
              : Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(28),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                                28),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.casino,
                              size: 70,
                              color: Color(
                                0xFFD96C3F,
                              ),
                            ),
                            const SizedBox(
                                height: 24),
                            Text(
                              recipe!['recipe'],
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                fontSize: 26,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                                height: 8),
                            Text(
                              recipe!['cookbook'],
                              style:
                                  const TextStyle(
                                color: Color(
                                  0xFF777777,
                                ),
                              ),
                            ),
                            const SizedBox(
                                height: 30),
                            FilledButton.icon(
                              onPressed:
                                  openRecipe,
                              icon: const Icon(
                                  Icons
                                      .restaurant_menu),
                              label:
                                  const Text(
                                'Cook this!',
                              ),
                            ),
                            const SizedBox(
                                height: 12),
                            OutlinedButton.icon(
                              onPressed:
                                  pickRecipe,
                              icon: const Icon(
                                  Icons.refresh),
                              label:
                                  const Text(
                                'Pick another',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}