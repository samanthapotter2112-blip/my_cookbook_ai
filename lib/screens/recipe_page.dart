import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecipePage extends StatefulWidget {
  final String cookbookName;
  final String recipeName;

  final String initialPageNumber;
  final String initialPrepTime;
  final String initialCookTime;
  final String initialServings;
  final String initialIngredients;
  final String initialMethod;
  final String initialNotes;
  final Uint8List? initialPhoto;

  const RecipePage({
    super.key,
    required this.cookbookName,
    required this.recipeName,
    this.initialPageNumber = '',
    this.initialPrepTime = '',
    this.initialCookTime = '',
    this.initialServings = '',
    this.initialIngredients = '',
    this.initialMethod = '',
    this.initialNotes = '',
    this.initialPhoto,
  });

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final TextEditingController pageController =
      TextEditingController();

  final TextEditingController prepTimeController =
      TextEditingController();

  final TextEditingController cookTimeController =
      TextEditingController();

  final TextEditingController servingsController =
      TextEditingController();

  final TextEditingController ingredientsController =
      TextEditingController();

  final TextEditingController methodController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  Box? cookbookBox;

  Uint8List? recipePhoto;

  bool favourite = false;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    loadInitialValues();
    openCookbook();
  }

  void loadInitialValues() {
    pageController.text = widget.initialPageNumber;
    prepTimeController.text = widget.initialPrepTime;
    cookTimeController.text = widget.initialCookTime;
    servingsController.text = widget.initialServings;
    ingredientsController.text = widget.initialIngredients;
    methodController.text = widget.initialMethod;
    notesController.text = widget.initialNotes;
    recipePhoto = widget.initialPhoto;
  }

  Future<void> openCookbook() async {
    final Box box = Hive.isBoxOpen(widget.cookbookName)
        ? Hive.box(widget.cookbookName)
        : await Hive.openBox(widget.cookbookName);

    cookbookBox = box;

    final dynamic savedRecipe = box.get(widget.recipeName);

    if (savedRecipe is Map) {
      pageController.text =
          savedRecipe['pageNumber']?.toString() ?? '';

      prepTimeController.text =
          savedRecipe['prepTime']?.toString() ?? '';

      cookTimeController.text =
          savedRecipe['cookTime']?.toString() ?? '';

      servingsController.text =
          savedRecipe['servings']?.toString() ?? '';

      ingredientsController.text =
          savedRecipe['ingredients']?.toString() ?? '';

      methodController.text =
          savedRecipe['method']?.toString() ?? '';

      notesController.text =
          savedRecipe['notes']?.toString() ?? '';

      favourite = savedRecipe['favourite'] == true;

      final dynamic savedPhoto = savedRecipe['photo'];

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

  Future<void> toggleFavourite() async {
    setState(() {
      favourite = !favourite;
    });

    final Box? box = cookbookBox;

    if (box == null) return;

    final dynamic savedRecipe = box.get(widget.recipeName);

    if (savedRecipe is Map) {
      final Map<String, dynamic> updatedRecipe =
          Map<String, dynamic>.from(savedRecipe);

      updatedRecipe['favourite'] = favourite;

      await box.put(
        widget.recipeName,
        updatedRecipe,
      );
    }
  }

  Future<void> saveRecipe() async {
    if (isSaving) return;

    final Box? box = cookbookBox;

    if (box == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cookbook storage is not ready.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final Map<String, dynamic> recipeData = {
        'name': widget.recipeName.trim(),
        'cookbookName': widget.cookbookName,
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

      await box.put(
        widget.recipeName.trim(),
        recipeData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe saved'),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save recipe: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
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
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(widget.recipeName),
        actions: [
          IconButton(
            onPressed: isSaving ? null : toggleFavourite,
            tooltip: favourite
                ? 'Remove from favourites'
                : 'Add to favourites',
            icon: Icon(
              favourite
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.cookbookName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: isSaving ? null : pickRecipePhoto,
              child: recipePhoto == null
                  ? CircleAvatar(
                      radius: 65,
                      backgroundColor:
                          Colors.orange.shade100,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 42,
                        color: Colors.deepOrange,
                      ),
                    )
                  : CircleAvatar(
                      radius: 65,
                      backgroundImage:
                          MemoryImage(recipePhoto!),
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
              onPressed: isSaving ? null : saveRecipe,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                isSaving
                    ? 'Saving...'
                    : 'Save Recipe',
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}