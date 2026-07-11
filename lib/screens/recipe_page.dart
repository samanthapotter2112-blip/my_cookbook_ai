import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  Uint8List? recipePhoto;

  final ingredientsController = TextEditingController();
  final methodController = TextEditingController();
  final notesController = TextEditingController();
  final pageController = TextEditingController();

  bool favourite = false;

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

  @override
  void dispose() {
    ingredientsController.dispose();
    methodController.dispose();
    notesController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: pickRecipePhoto,
              child: recipePhoto == null
                  ? CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.deepOrange,
                      ),
                    )
                  : CircleAvatar(
                      radius: 60,
                      backgroundImage: MemoryImage(recipePhoto!),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              "Tap to add a recipe photo",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 25),

          TextField(
            controller: pageController,
            decoration: const InputDecoration(
              labelText: "Book page",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: ingredientsController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: "Ingredients",
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: methodController,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: "Method",
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: notesController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: "Notes",
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            value: favourite,
            onChanged: (value) {
              setState(() {
                favourite = value;
              });
            },
            title: const Text("Favourite"),
            secondary: Icon(
              favourite ? Icons.favorite : Icons.favorite_border,
            ),
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Save function coming next"),
                ),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text("Save Recipe"),
          ),
        ],
      ),
    );
  }
}