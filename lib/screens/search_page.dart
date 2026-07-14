import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'recipe_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController =
      TextEditingController();

  List<Map<String, dynamic>> allRecipes = [];
  List<Map<String, dynamic>> filteredRecipes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    searchController.addListener(refreshSearchField);
    loadRecipes();
  }

  void refreshSearchField() {
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

      for (final dynamic recipeKey in cookbookBox.keys) {
        final dynamic savedRecipe =
            cookbookBox.get(recipeKey);

        if (savedRecipe is Map) {
          final Map<String, dynamic> recipe =
              Map<String, dynamic>.from(savedRecipe);

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
            first['name']?.toString().toLowerCase() ?? '';

        final String secondName =
            second['name']?.toString().toLowerCase() ?? '';

        return firstName.compareTo(secondName);
      },
    );

    if (!mounted) return;

    setState(() {
      allRecipes = loadedRecipes;
      isLoading = false;
    });

    searchRecipes(searchController.text);
  }

  void searchRecipes(String query) {
    final List<String> searchTerms = query
        .toLowerCase()
        .split(RegExp(r'[\s,]+'))
        .where(
          (String term) => term.isNotEmpty,
        )
        .toList();

    setState(() {
      if (searchTerms.isEmpty) {
        filteredRecipes =
            List<Map<String, dynamic>>.from(allRecipes);

        return;
      }

      filteredRecipes = allRecipes.where(
        (Map<String, dynamic> recipe) {
          final String searchableText = [
            recipe['name'],
            recipe['cookbookName'],
            recipe['ingredients'],
            recipe['method'],
            recipe['notes'],
          ]
              .whereType<Object>()
              .join(' ')
              .toLowerCase();

          return searchTerms.every(
            searchableText.contains,
          );
        },
      ).toList();
    });
  }

  void clearSearch() {
    searchController.clear();
    searchRecipes('');
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

    await loadRecipes();
  }

  @override
  void dispose() {
    searchController.removeListener(
      refreshSearchField,
    );

    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Search Recipes'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                0,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: searchRecipes,
                    decoration: InputDecoration(
                      hintText:
                          'Search recipes or ingredients',
                      prefixIcon:
                          const Icon(Icons.search),
                      suffixIcon:
                          searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: clearSearch,
                                  tooltip: 'Clear search',
                                  icon: const Icon(
                                    Icons.clear,
                                  ),
                                ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${filteredRecipes.length} '
                          '${filteredRecipes.length == 1 ? 'recipe' : 'recipes'} found',
                          style: const TextStyle(
                            color: Color(0xFF7C7470),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (searchController.text.isNotEmpty)
                        TextButton(
                          onPressed: clearSearch,
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: allRecipes.isEmpty
                        ? const _EmptySearch(
                            title:
                                'No saved recipes yet',
                            message:
                                'Add a recipe to a cookbook '
                                'or use the Scan tab.',
                            icon: Icons.search_off,
                          )
                        : filteredRecipes.isEmpty
                            ? const _EmptySearch(
                                title:
                                    'No matching recipes',
                                message:
                                    'Try another recipe name '
                                    'or ingredient.',
                                icon:
                                    Icons.manage_search,
                              )
                            : RefreshIndicator(
                                onRefresh: loadRecipes,
                                child: ListView.builder(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 30,
                                  ),
                                  itemCount:
                                      filteredRecipes.length,
                                  itemBuilder: (
                                    BuildContext context,
                                    int index,
                                  ) {
                                    final Map<String,
                                            dynamic>
                                        recipe =
                                        filteredRecipes[
                                            index];

                                    return _SearchRecipeCard(
                                      recipeName:
                                          recipe['name']
                                                  ?.toString() ??
                                              'Unnamed recipe',
                                      cookbookName:
                                          recipe['cookbookName']
                                                  ?.toString() ??
                                              '',
                                      ingredients:
                                          recipe['ingredients']
                                                  ?.toString()
                                                  .trim() ??
                                              '',
                                      prepTime:
                                          recipe['prepTime']
                                                  ?.toString()
                                                  .trim() ??
                                              '',
                                      cookTime:
                                          recipe['cookTime']
                                                  ?.toString()
                                                  .trim() ??
                                              '',
                                      servings:
                                          recipe['servings']
                                                  ?.toString()
                                                  .trim() ??
                                              '',
                                      favourite:
                                          recipe['favourite'] ==
                                              true,
                                      photo:
                                          getRecipePhoto(
                                        recipe,
                                      ),
                                      onTap: () {
                                        openRecipe(recipe);
                                      },
                                    );
                                  },
                                ),
                              ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SearchRecipeCard extends StatelessWidget {
  final String recipeName;
  final String cookbookName;
  final String ingredients;
  final String prepTime;
  final String cookTime;
  final String servings;
  final bool favourite;
  final Uint8List? photo;
  final VoidCallback onTap;

  const _SearchRecipeCard({
    required this.recipeName,
    required this.cookbookName,
    required this.ingredients,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.favourite,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            recipeName,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (favourite)
                          const Padding(
                            padding:
                                EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.favorite,
                              color: Color(0xFFB94747),
                              size: 20,
                            ),
                          ),
                      ],
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
                    if (ingredients.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        ingredients,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6F6864),
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (prepTime.isNotEmpty ||
                        cookTime.isNotEmpty ||
                        servings.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          if (prepTime.isNotEmpty)
                            _SearchChip(
                              icon: Icons.schedule,
                              label: prepTime,
                            ),
                          if (cookTime.isNotEmpty)
                            _SearchChip(
                              icon: Icons
                                  .local_fire_department_outlined,
                              label: cookTime,
                            ),
                          if (servings.isNotEmpty)
                            _SearchChip(
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
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8A817C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SearchChip({
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

class _EmptySearch extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _EmptySearch({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 76,
              color: const Color(0xFFAAA19C),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
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