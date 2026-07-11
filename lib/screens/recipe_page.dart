import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecipePage extends StatefulWidget {
  final String recipeName;

  const RecipePage({
    super.key,
    required this.recipeName,
  });

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final TextEditingController pageController = TextEditingController();
  final TextEditingController prepTimeController = TextEditingController();
  final TextEditingController cookTimeController = TextEditingController();
  final TextEditingController servingsController = TextEditingController();
  final TextEditingController ingredientsController =
      TextEditingController();
  final TextEditingController methodController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  Box? recipeDetailsBox;

  Uint8List? recipePhoto;
  bool favourite = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    openRecipeDetailsBox();
  }

  Future<void> openRecipeDetailsBox() async {
    final box = await Hive.openBox('recipe_details');

    recipeDetailsBox = box;

    final savedData = box.get(widget.recipeName);

    if (savedData is Map) {
      pageController.text = savedData['pageNumber']?.toString() ?? '';
      prepTimeController.text = savedData['prepTime']?.toString() ?? '';
      cookTimeController.text = savedData['cookTime']?.toString() ?? '';
      servingsController.text = savedData['servings']?.toString() ?? '';
      ingredientsController.text =
          savedData['ingredients']?.toString() ?? '';
      methodController.text = savedData['method']?.toString() ?? '';
      notesController.text = savedData['notes']?.toString() ?? '';

      favourite = savedData['favourite'] == true;

      final savedPhoto = savedData['photo'];

      if (savedPhoto is Uint8List) {
        recipePhoto = savedPhoto;
      } else if (savedPhoto is List<int>) {
        recipePhoto = Uint8List.fromList(savedPhoto);
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> pickRecipePhoto() async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final Uint8List? imageBytes = result.files.first.bytes;

    if (imageBytes == null) return;

    setState(() {
      recipePhoto = imageBytes;
    });
  }

  Future<void> saveRecipe() async {
    final box = recipeDetailsBox;

    if (box == null) {
      return;
    }

    final recipeData = <String, dynamic>{
      'name': widget.recipeName,
      'pageNumber': pageController.text.trim(),
      'prepTime': prepTimeController.text.trim(),
      'cookTime': cookTimeController.text.trim(),
      'servings': servingsController.text.trim(),
      'ingredients': ingredientsController.text.trim(),
      'method': methodController.text.trim(),
      'notes': notesController.text.trim(),
      'favourite': favourite,
      'photo': recipePhoto,
    };

    await box.put(widget.recipeName, recipeData);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe saved'),
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    prepTimeController.dispose();
    cookTimeController.dispose();
    servingsController.dispose();
    ingredientsController.dispose();
    methodController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.recipeName),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeName),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                favourite = !favourite;
              });
            },
            icon: Icon(
              favourite ? Icons.favorite : Icons.favorite_border,
            ),
            tooltip: favourite
                ? 'Remove from favourites'
                : 'Add to favourites',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: pickRecipePhoto,
              child: recipePhoto == null
                  ? CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 42,
                        color: Colors.deepOrange,
                      ),
                    )
                  : CircleAvatar(
                      radius: 65,
                      backgroundImage: MemoryImage(recipePhoto!),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Tap to add or change photo',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: pageController,
            decoration: const InputDecoration(
              labelText: 'Cookbook page number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.menu_book),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: prepTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Prep time',
                    hintText: '20 mins',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: cookTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Cook time',
                    hintText: '35 mins',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: servingsController,
            decoration: const InputDecoration(
              labelText: 'Servings',
              hintText: '4',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: ingredientsController,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Ingredients',
              hintText: 'Enter one ingredient per line',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: methodController,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: 'Method',
              hintText: 'Enter the cooking instructions',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: notesController,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: saveRecipe,
              icon: const Icon(Icons.save),
              label: const Text('Save Recipe'),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}