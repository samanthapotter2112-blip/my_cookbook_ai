import 'dart:typed_data';

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

      for (final dynamic recipeKey in cookbookBox.keys) {
        final dynamic savedRecipe =
            cookbookBox.get(recipeKey);

        if (savedRecipe is Map &&
            savedRecipe['favourite'] == true) {
          final Map<String, dynamic> recipe =
              Map<String, dynamic>.from(
            savedRecipe,
          );

          recipe['name'] =
              recipe['name']?.toString() ??
                  recipeKey.toString();

          recipe['cookbookName'] = cookbookName;

          loadedRecipes.add(recipe);
        }
      }
    }

    loadedRecipes.sort(
      (
        Map<String, dynamic> first,
        Map<String, dynamic> second,
      ) {
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

        return firstName.compareTo(secondName);
      },
    );

    if (!mounted) return;

    setState(() {
      favouriteRecipes = loadedRecipes;
      isLoading = false;
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
      return Uint8List.fromList(savedPhoto);
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
        recipe['cookbookName']?.toString() ?? '';

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

    await loadFavourites();
  }

  Future<void> removeFavourite(
    Map<String, dynamic> recipe,
  ) async {
    final String recipeName =
        recipe['name']?.toString() ?? '';

    final String cookbookName =
        recipe['cookbookName']?.toString() ?? '';

    if (recipeName.isEmpty ||
        cookbookName.isEmpty) {
      return;
    }

    final Box cookbookBox =
        Hive.isBoxOpen(cookbookName)
            ? Hive.box(cookbookName)
            : await Hive.openBox(cookbookName);

    final dynamic savedRecipe =
        cookbookBox.get(recipeName);

    if (savedRecipe is! Map) return;

    final Map<String, dynamic> updatedRecipe =
        Map<String, dynamic>.from(
      savedRecipe,
    );

    updatedRecipe['favourite'] = false;

    await cookbookBox.put(
      recipeName,
      updatedRecipe,
    );

    if (!mounted) return;

    await loadFavourites();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$recipeName removed from favourites',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Favourite Recipes'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : favouriteRecipes.isEmpty
              ? const _EmptyFavourites()
              : RefreshIndicator(
                  onRefresh: loadFavourites,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      30,
                    ),
                    itemCount:
                        favouriteRecipes.length,
                    itemBuilder: (
                      BuildContext context,
                      int index,
                    ) {
                      final Map<String, dynamic>
                          recipe =
                          favouriteRecipes[index];

                      final Uint8List? photo =
                          getRecipePhoto(recipe);

                      final String recipeName =
                          recipe['name']?.toString() ??
                              'Unnamed recipe';

                      final String cookbookName =
                          recipe['cookbookName']
                                  ?.toString() ??
                              '';

                      final String prepTime =
                          recipe['prepTime']
                                  ?.toString()
                                  .trim() ??
                              '';

                      final String cookTime =
                          recipe['cookTime']
                                  ?.toString()
                                  .trim() ??
                              '';

                      final String servings =
                          recipe['servings']
                                  ?.toString()
                                  .trim() ??
                              '';

                      return _FavouriteRecipeCard(
                        recipeName: recipeName,
                        cookbookName: cookbookName,
                        photo: photo,
                        prepTime: prepTime,
                        cookTime: cookTime,
                        servings: servings,
                        onTap: () {
                          openRecipe(recipe);
                        },
                        onRemove: () {
                          removeFavourite(recipe);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _FavouriteRecipeCard extends StatelessWidget {
  final String recipeName;
  final String cookbookName;
  final Uint8List? photo;
  final String prepTime;
  final String cookTime;
  final String servings;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavouriteRecipeCard({
    required this.recipeName,
    required this.cookbookName,
    required this.photo,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: photo == null
                      ? Container(
                          color: const Color(
                            0xFFFFE3D5,
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 38,
                            color: Color(
                              0xFFD96C3F,
                            ),
                          ),
                        )
                      : Image.memory(
                          photo!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipeName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 16,
                          color: Color(0xFF7C7470),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cookbookName,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                                  Color(0xFF7C7470),
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (prepTime.isNotEmpty ||
                        cookTime.isNotEmpty ||
                        servings.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 7,
                        children: [
                          if (prepTime.isNotEmpty)
                            _RecipeChip(
                              icon: Icons.schedule,
                              label: prepTime,
                            ),
                          if (cookTime.isNotEmpty)
                            _RecipeChip(
                              icon: Icons
                                  .local_fire_department_outlined,
                              label: cookTime,
                            ),
                          if (servings.isNotEmpty)
                            _RecipeChip(
                              icon:
                                  Icons.people_outline,
                              label: 'Serves $servings',
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from favourites',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.favorite,
                  color: Color(0xFFB94747),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RecipeChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFFD96C3F),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF695F5A),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavourites extends StatelessWidget {
  const _EmptyFavourites();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 76,
              color: Color(0xFFAAA19C),
            ),
            SizedBox(height: 18),
            Text(
              'No favourite recipes yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Open a recipe and tap the heart '
              'to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7C7470),
              ),
            ),
          ],
        ),
      ),
    );
  }
}