import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'recipe_page.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() =>
      _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final TextEditingController collectionNameController =
      TextEditingController();

  Box? collectionsBox;

  List<String> collectionNames = [];
  List<Map<String, dynamic>> allRecipes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initialiseCollections();
  }

  Future<void> initialiseCollections() async {
    collectionsBox = Hive.isBoxOpen('collections')
        ? Hive.box('collections')
        : await Hive.openBox('collections');

    await loadRecipes();
    loadCollections();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
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
            Map<String, dynamic>.from(savedRecipe);

        recipe['name'] =
            recipe['name']?.toString() ??
                recipeKey.toString();

        recipe['cookbookName'] = cookbookName;

        loadedRecipes.add(recipe);
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

    allRecipes = loadedRecipes;
  }

  void loadCollections() {
    final Box? box = collectionsBox;

    if (box == null) {
      collectionNames = [];
      return;
    }

    collectionNames = box.keys
        .map(
          (dynamic key) => key.toString(),
        )
        .where(
          (String name) => name.trim().isNotEmpty,
        )
        .toList();

    collectionNames.sort(
      (String first, String second) {
        return first.toLowerCase().compareTo(
              second.toLowerCase(),
            );
      },
    );
  }

  List<Map<String, dynamic>> getCollectionRecipes(
    String collectionName,
  ) {
    final dynamic savedValue =
        collectionsBox?.get(collectionName);

    if (savedValue is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>>
        collectionRecipes = [];

    for (final dynamic item in savedValue) {
      if (item is! Map) continue;

      final String recipeName =
          item['recipeName']?.toString() ?? '';

      final String cookbookName =
          item['cookbookName']?.toString() ?? '';

      for (final Map<String, dynamic> recipe
          in allRecipes) {
        if (recipe['name']?.toString() ==
                recipeName &&
            recipe['cookbookName']?.toString() ==
                cookbookName) {
          collectionRecipes.add(recipe);
          break;
        }
      }
    }

    return collectionRecipes;
  }

  void showAddCollectionDialog() {
    collectionNameController.clear();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('New Collection'),
          content: TextField(
            controller: collectionNameController,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Collection name',
              hintText: 'For example: Weeknight Meals',
              prefixIcon:
                  Icon(Icons.collections_bookmark_outlined),
            ),
            onSubmitted: (_) {
              createCollection(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                createCollection(dialogContext);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> createCollection(
    BuildContext dialogContext,
  ) async {
    final Box? box = collectionsBox;

    if (box == null) return;

    final String collectionName =
        collectionNameController.text.trim();

    if (collectionName.isEmpty) return;

    final bool alreadyExists =
        collectionNames.any(
      (String existingName) {
        return existingName.toLowerCase() ==
            collectionName.toLowerCase();
      },
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"$collectionName" already exists.',
          ),
        ),
      );
      return;
    }

    await box.put(
      collectionName,
      <Map<String, dynamic>>[],
    );

    if (!mounted) return;

    setState(loadCollections);

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
  }

  Future<void> deleteCollection(
    String collectionName,
  ) async {
    final bool? shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete collection?'),
          content: Text(
            'Delete "$collectionName"? '
            'The recipes themselves will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await collectionsBox?.delete(collectionName);

    if (!mounted) return;

    setState(loadCollections);
  }

  Future<void> openCollection(
    String collectionName,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionDetailPage(
          collectionName: collectionName,
          collectionsBox: collectionsBox!,
          allRecipes: allRecipes,
        ),
      ),
    );

    if (!mounted) return;

    await loadRecipes();

    setState(() {});
  }

  @override
  void dispose() {
    collectionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Collections'),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            isLoading ? null : showAddCollectionDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Collection'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : collectionNames.isEmpty
              ? const _EmptyCollections()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    100,
                  ),
                  itemCount: collectionNames.length,
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    final String collectionName =
                        collectionNames[index];

                    final List<Map<String, dynamic>>
                        recipes =
                        getCollectionRecipes(
                      collectionName,
                    );

                    return Card(
                      elevation: 2,
                      margin:
                          const EdgeInsets.only(bottom: 14),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.all(16),
                        leading: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE9E7F4),
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons
                                .collections_bookmark_outlined,
                            color: Color(0xFF625F85),
                          ),
                        ),
                        title: Text(
                          collectionName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${recipes.length} '
                          '${recipes.length == 1 ? 'recipe' : 'recipes'}',
                        ),
                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (String value) {
                            if (value == 'delete') {
                              deleteCollection(
                                collectionName,
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Delete collection',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          openCollection(
                            collectionName,
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class CollectionDetailPage
    extends StatefulWidget {
  final String collectionName;
  final Box collectionsBox;
  final List<Map<String, dynamic>> allRecipes;

  const CollectionDetailPage({
    super.key,
    required this.collectionName,
    required this.collectionsBox,
    required this.allRecipes,
  });

  @override
  State<CollectionDetailPage> createState() =>
      _CollectionDetailPageState();
}

class _CollectionDetailPageState
    extends State<CollectionDetailPage> {
  List<Map<String, dynamic>> recipes = [];

  @override
  void initState() {
    super.initState();
    loadCollection();
  }

  void loadCollection() {
    final dynamic savedValue =
        widget.collectionsBox.get(
      widget.collectionName,
    );

    final List<Map<String, dynamic>>
        loadedRecipes = [];

    if (savedValue is List) {
      for (final dynamic item in savedValue) {
        if (item is! Map) continue;

        final String recipeName =
            item['recipeName']?.toString() ?? '';

        final String cookbookName =
            item['cookbookName']?.toString() ?? '';

        for (final Map<String, dynamic> recipe
            in widget.allRecipes) {
          if (recipe['name']?.toString() ==
                  recipeName &&
              recipe['cookbookName']?.toString() ==
                  cookbookName) {
            loadedRecipes.add(recipe);
            break;
          }
        }
      }
    }

    recipes = loadedRecipes;
  }

  Future<void> addRecipe() async {
    final Map<String, dynamic>? selectedRecipe =
        await showModalBottomSheet<
            Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          const Color(0xFFF8F5F2),
      builder: (_) {
        return _CollectionRecipePicker(
          recipes: widget.allRecipes,
        );
      },
    );

    if (selectedRecipe == null) return;

    final List<dynamic> savedEntries =
        List<dynamic>.from(
      widget.collectionsBox.get(
            widget.collectionName,
            defaultValue: <dynamic>[],
          ) ??
          <dynamic>[],
    );

    final String recipeName =
        selectedRecipe['name']?.toString() ?? '';

    final String cookbookName =
        selectedRecipe['cookbookName']
                ?.toString() ??
            '';

    final bool alreadyAdded = savedEntries.any(
      (dynamic entry) {
        return entry is Map &&
            entry['recipeName']?.toString() ==
                recipeName &&
            entry['cookbookName']?.toString() ==
                cookbookName;
      },
    );

    if (alreadyAdded) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That recipe is already in this collection.',
          ),
        ),
      );
      return;
    }

    savedEntries.add(
      <String, dynamic>{
        'recipeName': recipeName,
        'cookbookName': cookbookName,
      },
    );

    await widget.collectionsBox.put(
      widget.collectionName,
      savedEntries,
    );

    if (!mounted) return;

    setState(loadCollection);
  }

  Future<void> removeRecipe(
    Map<String, dynamic> recipe,
  ) async {
    final List<dynamic> savedEntries =
        List<dynamic>.from(
      widget.collectionsBox.get(
            widget.collectionName,
            defaultValue: <dynamic>[],
          ) ??
          <dynamic>[],
    );

    savedEntries.removeWhere(
      (dynamic entry) {
        return entry is Map &&
            entry['recipeName']?.toString() ==
                recipe['name']?.toString() &&
            entry['cookbookName']?.toString() ==
                recipe['cookbookName']?.toString();
      },
    );

    await widget.collectionsBox.put(
      widget.collectionName,
      savedEntries,
    );

    if (!mounted) return;

    setState(loadCollection);
  }

  Future<void> openRecipe(
    Map<String, dynamic> recipe,
  ) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          cookbookName:
              recipe['cookbookName']?.toString() ??
                  '',
          recipeName:
              recipe['name']?.toString() ??
                  'Unnamed recipe',
        ),
      ),
    );

    if (!mounted) return;

    setState(loadCollection);
  }

  Uint8List? getPhoto(
    Map<String, dynamic> recipe,
  ) {
    final dynamic photo = recipe['photo'];

    if (photo is Uint8List) {
      return photo;
    }

    if (photo is List<int>) {
      return Uint8List.fromList(photo);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(widget.collectionName),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addRecipe,
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
      ),
      body: recipes.isEmpty
          ? const Center(
              child: Text(
                'No recipes in this collection yet.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                100,
              ),
              itemCount: recipes.length,
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
                final Map<String, dynamic> recipe =
                    recipes[index];

                final Uint8List? photo =
                    getPhoto(recipe);

                return Card(
                  margin:
                      const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: SizedBox(
                        width: 58,
                        height: 58,
                        child: photo == null
                            ? Container(
                                color:
                                    const Color(0xFFFFE3D5),
                                child: const Icon(
                                  Icons.restaurant_menu,
                                  color:
                                      Color(0xFFD96C3F),
                                ),
                              )
                            : Image.memory(
                                photo,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    title: Text(
                      recipe['name']?.toString() ??
                          'Unnamed recipe',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      recipe['cookbookName']
                              ?.toString() ??
                          '',
                    ),
                    trailing:
                        PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'remove') {
                          removeRecipe(recipe);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'remove',
                          child: Text(
                            'Remove from collection',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      openRecipe(recipe);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _CollectionRecipePicker
    extends StatefulWidget {
  final List<Map<String, dynamic>> recipes;

  const _CollectionRecipePicker({
    required this.recipes,
  });

  @override
  State<_CollectionRecipePicker> createState() =>
      _CollectionRecipePickerState();
}

class _CollectionRecipePickerState
    extends State<_CollectionRecipePicker> {
  final TextEditingController searchController =
      TextEditingController();

  late List<Map<String, dynamic>> filteredRecipes;

  @override
  void initState() {
    super.initState();

    filteredRecipes =
        List<Map<String, dynamic>>.from(
      widget.recipes,
    );
  }

  void searchRecipes(String query) {
    final String searchText =
        query.toLowerCase().trim();

    setState(() {
      filteredRecipes = widget.recipes.where(
        (Map<String, dynamic> recipe) {
          final String value = [
            recipe['name'],
            recipe['cookbookName'],
            recipe['tags'],
          ].join(' ').toLowerCase();

          return value.contains(searchText);
        },
      ).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (
        BuildContext context,
        ScrollController scrollController,
      ) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: TextField(
                controller: searchController,
                onChanged: searchRecipes,
                decoration: const InputDecoration(
                  hintText: 'Search recipes',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: filteredRecipes.length,
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final Map<String, dynamic> recipe =
                      filteredRecipes[index];

                  return Card(
                    child: ListTile(
                      title: Text(
                        recipe['name']?.toString() ??
                            'Unnamed recipe',
                      ),
                      subtitle: Text(
                        recipe['cookbookName']
                                ?.toString() ??
                            '',
                      ),
                      trailing: const Icon(
                        Icons.add_circle_outline,
                      ),
                      onTap: () {
                        Navigator.pop(
                          context,
                          recipe,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyCollections extends StatelessWidget {
  const _EmptyCollections();

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
              Icons.collections_bookmark_outlined,
              size: 76,
              color: Color(0xFFAAA19C),
            ),
            SizedBox(height: 18),
            Text(
              'No collections yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Create collections for occasions, '
              'meal types, favourites or anything else.',
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