import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'recipe_page.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() =>
      _FavouritesPageState();
}

class _FavouritesPageState
    extends State<FavouritesPage> {
  List<Map<String, dynamic>> favouriteRecipes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavourites();
  }

  Future<void> loadFavourites() async {
    final Box cookbookBox =
        Hive.isBoxOpen('cookbooks')
            ? Hive.box('cookbooks')
            : await Hive.openBox('cookbooks');

    final List<Map<String, dynamic>> loaded = [];

    for (final cookbookName
        in cookbookBox.values.cast<String>()) {
      final Box recipes =
          Hive.isBoxOpen(cookbookName)
              ? Hive.box(cookbookName)
              : await Hive.openBox(cookbookName);

      for (final key in recipes.keys) {
        final value = recipes.get(key);

        if (value is Map &&
            value['favourite'] == true) {
          final recipe =
              Map<String, dynamic>.from(value);

          recipe['cookbookName'] = cookbookName;

          loaded.add(recipe);
        }
      }
    }

    loaded.sort(
      (a, b) => (a['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo(
            (b['name'] ?? '')
                .toString()
                .toLowerCase(),
          ),
    );

    if (!mounted) return;

    setState(() {
      favouriteRecipes = loaded;
      isLoading = false;
    });
  }

  Future<void> openRecipe(
    Map<String, dynamic> recipe,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          cookbookName:
              recipe['cookbookName'],
          recipeName: recipe['name'],
        ),
      ),
    );

    await loadFavourites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title:
            const Text('Favourite Recipes'),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : favouriteRecipes.isEmpty
              ? const Center(
                  child: Text(
                    'No favourite recipes yet.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadFavourites,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        favouriteRecipes.length,
                    itemBuilder:
                        (context, index) {
                      final recipe =
                          favouriteRecipes[
                              index];

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          ),
                          title: Text(
                            recipe['name'],
                          ),
                          subtitle: Text(
                            recipe[
                                'cookbookName'],
                          ),
                          trailing:
                              const Icon(
                            Icons
                                .chevron_right,
                          ),
                          onTap: () =>
                              openRecipe(
                            recipe,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}