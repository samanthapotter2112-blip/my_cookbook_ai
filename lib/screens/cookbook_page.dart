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

  late Box recipeBox;

  List<String> recipes = [];
  Uint8List? selectedImage;
  String extractedText = "";

  @override
  void initState() {
    super.initState();
    openRecipeBox();
  }

  Future<void> openRecipeBox() async {
    recipeBox = await Hive.openBox(widget.cookbookName);

    if (!mounted) return;

    setState(() {
      recipes = recipeBox.values.cast<String>().toList();
    });
  }

  Future<void> scanPage() async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      selectedImage = result.files.first.bytes;

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

  void addRecipe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Recipe"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Recipe name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final recipe = controller.text.trim();

              if (recipe.isNotEmpty) {
                recipeBox.add(recipe);

                setState(() {
                  recipes = recipeBox.values.cast<String>().toList();
                });
              }

              controller.clear();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
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
        onPressed: addRecipe,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: scanPage,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Scan Cookbook Page"),
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
              "Recipes",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            if (recipes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    "No recipes yet.\nTap + to add one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              )
            else
              ...recipes.map(
                (recipe) => RecipeCard(
                  recipeName: recipe,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipePage(
                          recipeName: recipe,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}