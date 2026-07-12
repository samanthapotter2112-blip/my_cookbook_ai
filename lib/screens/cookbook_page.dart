import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../widgets/recipe_card.dart';
import 'recipe_page.dart';

class CookbookPage extends StatefulWidget {
  final String cookbookName;

  const CookbookPage({
    super.key,
    required this.cookbookName,
  });

  @override
  State<CookbookPage> createState() => _CookbookPageState();
}

class _CookbookPageState extends State<CookbookPage> {
  final TextEditingController recipeNameController =
      TextEditingController();

  Box? recipeBox;

  List<String> recipeNames = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    openRecipeBox();
  }

  Future<void> openRecipeBox() async {
    final Box box = Hive.isBoxOpen(widget.cookbookName)
        ? Hive.box(widget.cookbookName)
        : await Hive.openBox(widget.cookbookName);

    recipeBox = box;

    loadRecipes();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  void loadRecipes() {
    final Box? box = recipeBox;

    if (box == null) {
      recipeNames = [];
      return;
    }

    recipeNames = box.keys
        .map((dynamic key) => key.toString())
        .toList();

    recipeNames.sort(
      (String first, String second) =>
          first.toLowerCase().compareTo(
                second.toLowerCase(),
              ),
    );
  }

  void showAddRecipeDialog() {
    recipeNameController.clear();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Recipe'),
          content: TextField(
            controller: recipeNameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Recipe name',
              hintText: 'For example: Vegetable Lasagne',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              createRecipe(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                createRecipe(dialogContext);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> createRecipe(
    BuildContext dialogContext,
  ) async {
    final Box? box = recipeBox;

    if (box == null) return;

    final String recipeName =
        recipeNameController.text.trim();

    if (recipeName.isEmpty) return;

    final bool alreadyExists = box.keys.any(
      (dynamic key) =>
          key.toString().trim().toLowerCase() ==
          recipeName.toLowerCase(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"$recipeName" already exists in this cookbook.',
          ),
        ),
      );

      return;
    }

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }

    final bool? saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          cookbookName: widget.cookbookName,
          recipeName: recipeName,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      setState(loadRecipes);
    }
  }

  Future<void> openRecipe(
    String recipeName,
  ) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          cookbookName: widget.cookbookName,
          recipeName: recipeName,
        ),
      ),
    );

    if (!mounted) return;

    setState(loadRecipes);
  }

  Future<void> confirmDeleteRecipe(
    String recipeName,
  ) async {
    final bool? shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete recipe?'),
          content: Text(
            'Are you sure you want to delete '
            '"$recipeName"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await deleteRecipe(recipeName);
  }

  Future<void> deleteRecipe(
    String recipeName,
  ) async {
    final Box? box = recipeBox;

    if (box == null) return;

    await box.delete(recipeName);

    if (!mounted) return;

    setState(loadRecipes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$recipeName deleted',
        ),
      ),
    );
  }

  @override
  void dispose() {
    recipeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(widget.cookbookName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            isLoading ? null : showAddRecipeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : recipeNames.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'No recipes yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tap Add Recipe to create one, '
                          'or use the Scan tab.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    100,
                  ),
                  itemCount: recipeNames.length,
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    final String recipeName =
                        recipeNames[index];

                    return Dismissible(
                      key: ValueKey(
                        '${widget.cookbookName}-$recipeName',
                      ),
                      direction:
                          DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await confirmDeleteRecipe(
                          recipeName,
                        );

                        return false;
                      },
                      background: Container(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        padding: const EdgeInsets.only(
                          right: 24,
                        ),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RecipeCard(
                              cookbookName: widget.cookbookName,
                              recipeName: recipeName,
                              onTap: () {
                                openRecipe(recipeName);
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete recipe',
                            onPressed: () {
                              confirmDeleteRecipe(
                                recipeName,
                              );
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}