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
      (String first, String second) {
        return first.toLowerCase().compareTo(
              second.toLowerCase(),
            );
      },
    );
  }

  int getFavouriteCount() {
    final Box? box = recipeBox;

    if (box == null) return 0;

    int count = 0;

    for (final dynamic value in box.values) {
      if (value is Map &&
          value['favourite'] == true) {
        count++;
      }
    }

    return count;
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
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Recipe name',
              hintText:
                  'For example: Vegetable Lasagne',
              prefixIcon:
                  Icon(Icons.restaurant_menu),
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
            FilledButton.icon(
              onPressed: () {
                createRecipe(dialogContext);
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
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

    final bool? saved =
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
            'Delete "$recipeName"? '
            'This cannot be undone.',
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
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon:
                  const Icon(Icons.delete_outline),
              label: const Text('Delete'),
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
    final int favouriteCount =
        getFavouriteCount();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(widget.cookbookName),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            isLoading ? null : showAddRecipeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFE3D5,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),
                              child: const Icon(
                                Icons.menu_book_outlined,
                                size: 30,
                                color:
                                    Color(0xFFD96C3F),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    widget.cookbookName,
                                    style:
                                        const TextStyle(
                                      fontSize: 23,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${recipeNames.length} '
                                    '${recipeNames.length == 1 ? 'recipe' : 'recipes'}'
                                    '  •  '
                                    '$favouriteCount '
                                    '${favouriteCount == 1 ? 'favourite' : 'favourites'}',
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(0xFF7C7470),
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Recipes',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (recipeNames.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        30,
                        10,
                        30,
                        100,
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .restaurant_menu_outlined,
                            size: 76,
                            color: Color(0xFFAAA19C),
                          ),
                          SizedBox(height: 18),
                          Text(
                            'No recipes yet',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Tap Add Recipe to create one, '
                            'or use the Scan tab.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Color(0xFF7C7470),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      100,
                    ),
                    sliver: SliverList.builder(
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
                              DismissDirection
                                  .endToStart,
                          confirmDismiss: (_) async {
                            await confirmDeleteRecipe(
                              recipeName,
                            );

                            return false;
                          },
                          background: Container(
                            margin:
                                const EdgeInsets.only(
                              bottom: 14,
                            ),
                            padding:
                                const EdgeInsets.only(
                              right: 26,
                            ),
                            alignment:
                                Alignment.centerRight,
                            decoration: BoxDecoration(
                              color:
                                  Colors.red.shade400,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RecipeCard(
                                  cookbookName:
                                      widget
                                          .cookbookName,
                                  recipeName:
                                      recipeName,
                                  onTap: () {
                                    openRecipe(
                                      recipeName,
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                tooltip:
                                    'Delete recipe',
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
                  ),
              ],
            ),
    );
  }
}