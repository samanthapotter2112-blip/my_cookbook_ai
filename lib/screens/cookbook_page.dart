import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  final TextEditingController controller = TextEditingController();

  Box? recipeBox;

  List<dynamic> recipeKeys = [];
  List<String> recipes = [];

  Uint8List? selectedImage;
  String extractedText = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    openRecipeBox();
  }

  Future<void> openRecipeBox() async {
    final box = await Hive.openBox(widget.cookbookName);

    recipeBox = box;

    if (!mounted) return;

    setState(() {
      loadRecipes();
      isLoading = false;
    });
  }

  void loadRecipes() {
    final box = recipeBox;

    if (box == null) return;

    recipeKeys = box.keys.toList();
    recipes = box.values.map((value) => value.toString()).toList();
  }

  Future<void> scanPage() async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final Uint8List? imageBytes = result.files.first.bytes;

    if (imageBytes == null) return;

    setState(() {
      selectedImage = imageBytes;

      // Temporary text until OCR is connected.
      extractedText = '''
Chocolate Cake

Ingredients
• 2 cups flour
• 1 cup sugar
• 2 eggs
• 150g butter

Method

1. Mix all ingredients.
2. Pour into a cake tin.
3. Bake for 35 minutes.
''';
    });
  }

  void showAddRecipeDialog() {
    controller.clear();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Recipe'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Recipe name',
            ),
            onSubmitted: (_) {
              saveNewRecipe(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                saveNewRecipe(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveNewRecipe(BuildContext dialogContext) async {
    final box = recipeBox;
    final recipeName = controller.text.trim();

    if (box == null || recipeName.isEmpty) return;

    await box.add(recipeName);

    if (!mounted) return;

    setState(loadRecipes);

    controller.clear();

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
  }

  Future<void> confirmDeleteRecipe({
    required dynamic recipeKey,
    required String recipeName,
  }) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete recipe?'),
          content: Text(
            'Are you sure you want to delete "$recipeName"?',
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

    await deleteRecipe(
      recipeKey: recipeKey,
      recipeName: recipeName,
    );
  }

  Future<void> deleteRecipe({
    required dynamic recipeKey,
    required String recipeName,
  }) async {
    final box = recipeBox;

    if (box == null) return;

    await box.delete(recipeKey);

    // Also remove the recipe-detail record saved by RecipePage.
    if (Hive.isBoxOpen('recipe_details')) {
      final detailsBox = Hive.box('recipe_details');
      await detailsBox.delete(recipeName);
    } else {
      final detailsBox = await Hive.openBox('recipe_details');
      await detailsBox.delete(recipeName);
    }

    if (!mounted) return;

    setState(loadRecipes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$recipeName deleted'),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cookbookName),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : showAddRecipeDialog,
        tooltip: 'Add recipe',
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: scanPage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Scan Cookbook Page'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (selectedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        selectedImage!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (selectedImage != null)
                    const SizedBox(height: 20),
                  if (extractedText.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          extractedText,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  const SizedBox(height: 25),
                  const Text(
                    'Recipes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (recipes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'No recipes yet.\nTap + to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      recipes.length,
                      (index) {
                        final recipeName = recipes[index];
                        final recipeKey = recipeKeys[index];

                        return Dismissible(
                          key: ValueKey(recipeKey),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await confirmDeleteRecipe(
                              recipeKey: recipeKey,
                              recipeName: recipeName,
                            );

                            // The list is updated manually after deletion.
                            return false;
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.only(right: 24),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
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
                                  recipeName: recipeName,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RecipePage(
                                          recipeName: recipeName,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete recipe',
                                onPressed: () {
                                  confirmDeleteRecipe(
                                    recipeKey: recipeKey,
                                    recipeName: recipeName,
                                  );
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}