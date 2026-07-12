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

    searchController.addListener(
      refreshSearchField,
    );

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

      if (cookbookName.isEmpty) {
        continue;
      }

      final Box cookbookBox =
          Hive.isBoxOpen(cookbookName)
              ? Hive.box(cookbookName)
              : await Hive.openBox(cookbookName);

      for (final dynamic key in cookbookBox.keys) {
        final dynamic value = cookbookBox.get(key);

        if (value is Map) {
          final Map<String, dynamic> recipe =
              Map<String, dynamic>.from(value);

          recipe['name'] =
              recipe['name']?.toString() ??
                  key.toString();

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
            List<Map<String, dynamic>>.from(
          allRecipes,
        );

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

  Future<void> openRecipe(
    Map<String, dynamic> recipe,
  ) async {
    final String recipeName =
        recipe['name']?.toString() ??
            'Unnamed recipe';

    final String cookbookName =
        recipe['cookbookName']?.toString() ?? '';

    if (cookbookName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This recipe is not linked to a cookbook.',
          ),
        ),
      );

      return;
    }

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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: searchRecipes,
                    decoration: InputDecoration(
                      hintText:
                          'Search by recipe or ingredient...',
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
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredRecipes.length} '
                      '${filteredRecipes.length == 1 ? 'recipe' : 'recipes'} found',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: allRecipes.isEmpty
                        ? const Center(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(30),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 70,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 18),
                                  Text(
                                    'No saved recipes yet',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Add a recipe to a cookbook '
                                    'or use the Scan tab.',
                                    textAlign:
                                        TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : filteredRecipes.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching recipes found.',
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: loadRecipes,
                                child:
                                    ListView.builder(
                                  itemCount:
                                      filteredRecipes
                                          .length,
                                  itemBuilder: (
                                    BuildContext context,
                                    int index,
                                  ) {
                                    final Map<String,
                                            dynamic>
                                        recipe =
                                        filteredRecipes[
                                            index];

                                    final String
                                        recipeName =
                                        recipe['name']
                                                ?.toString() ??
                                            'Unnamed recipe';

                                    final String
                                        cookbookName =
                                        recipe['cookbookName']
                                                ?.toString() ??
                                            '';

                                    final String
                                        ingredients =
                                        recipe['ingredients']
                                                ?.toString()
                                                .trim() ??
                                            '';

                                    return Card(
                                      margin:
                                          const EdgeInsets
                                              .only(
                                        bottom: 12,
                                      ),
                                      child: ListTile(
                                        leading:
                                            const CircleAvatar(
                                          child: Icon(
                                            Icons
                                                .restaurant_menu,
                                          ),
                                        ),
                                        title: Text(
                                          recipeName,
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            if (cookbookName
                                                .isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets
                                                        .only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  cookbookName,
                                                  style:
                                                      const TextStyle(
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                  ),
                                                ),
                                              ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                ingredients
                                                        .isEmpty
                                                    ? 'No ingredients saved'
                                                    : ingredients,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing:
                                            const Icon(
                                          Icons.chevron_right,
                                        ),
                                        onTap: () {
                                          openRecipe(
                                            recipe,
                                          );
                                        },
                                      ),
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