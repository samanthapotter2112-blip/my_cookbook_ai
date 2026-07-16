import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../widgets/recipe_tags.dart';
import '../widgets/star_rating.dart';
import 'cooking_mode_page.dart';

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
  final TextEditingController pageController = TextEditingController();

  final TextEditingController prepTimeController = TextEditingController();

  final TextEditingController cookTimeController = TextEditingController();

  final TextEditingController servingsController = TextEditingController();

  final TextEditingController ingredientsController = TextEditingController();

  final TextEditingController methodController = TextEditingController();

  final TextEditingController notesController = TextEditingController();

  Box? cookbookBox;

  Uint8List? recipePhoto;

  bool favourite = false;
  bool wouldMakeAgain = false;
  bool isLoading = true;
  bool isSaving = false;

  int rating = 0;

  List<String> selectedTags = [];

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
      pageController.text = savedRecipe['pageNumber']?.toString() ?? '';

      prepTimeController.text = savedRecipe['prepTime']?.toString() ?? '';

      cookTimeController.text = savedRecipe['cookTime']?.toString() ?? '';

      servingsController.text = savedRecipe['servings']?.toString() ?? '';

      ingredientsController.text = savedRecipe['ingredients']?.toString() ?? '';

      methodController.text = savedRecipe['method']?.toString() ?? '';

      notesController.text = savedRecipe['notes']?.toString() ?? '';

      favourite = savedRecipe['favourite'] == true;

      wouldMakeAgain = savedRecipe['wouldMakeAgain'] == true;

      rating = int.tryParse(savedRecipe['rating']?.toString() ?? '') ?? 0;

      final dynamic savedTags = savedRecipe['tags'];

      if (savedTags is List) {
        selectedTags = savedTags.map((dynamic tag) => tag.toString()).toList();
      }

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
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
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
      final Map<String, dynamic> updatedRecipe = Map<String, dynamic>.from(
        savedRecipe,
      );

      updatedRecipe['favourite'] = favourite;

      await box.put(widget.recipeName, updatedRecipe);
    }
  }

  Future<void> openCookingMode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookingModePage(
          recipeName: widget.recipeName,
          ingredients: ingredientsController.text,
          method: methodController.text,
          prepTime: prepTimeController.text,
          cookTime: cookTimeController.text,
          servings: servingsController.text,
        ),
      ),
    );
  }

  Future<void> saveRecipe() async {
    if (isSaving) return;

    final Box? box = cookbookBox;

    if (box == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cookbook storage is not ready.')),
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
        'rating': rating,
        'wouldMakeAgain': wouldMakeAgain,
        'tags': selectedTags,
        'photo': recipePhoto,
      };

      await box.put(widget.recipeName.trim(), recipeData);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recipe saved')));

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save recipe: $error')));
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
        appBar: AppBar(title: Text(widget.recipeName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(widget.recipeName),
        actions: [
          IconButton(
            onPressed: isSaving ? null : toggleFavourite,
            tooltip: favourite ? 'Remove from favourites' : 'Add to favourites',
            icon: Icon(
              favourite ? Icons.favorite : Icons.favorite_border,
              color: favourite ? const Color(0xFFB94747) : null,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F5F2),
            border: Border(top: BorderSide(color: Color(0xFFE7DFDA))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : openCookingMode,
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text(
                    'Start Cooking',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : saveRecipe,
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isSaving ? 'Saving...' : 'Save Recipe'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          _RecipePhotoHeader(
            recipeName: widget.recipeName,
            cookbookName: widget.cookbookName,
            recipePhoto: recipePhoto,
            onTap: pickRecipePhoto,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryField(
                  controller: prepTimeController,
                  icon: Icons.schedule_outlined,
                  label: 'Prep',
                  hintText: '20 mins',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryField(
                  controller: cookTimeController,
                  icon: Icons.local_fire_department_outlined,
                  label: 'Cook',
                  hintText: '35 mins',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryField(
                  controller: servingsController,
                  icon: Icons.people_outline,
                  label: 'Serves',
                  hintText: '4',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RecipeSectionCard(
            title: 'Your rating',
            icon: Icons.star_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarRating(
                  rating: rating,
                  enabled: !isSaving,
                  onChanged: (int newRating) {
                    setState(() {
                      rating = newRating;
                    });
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: wouldMakeAgain,
                  activeTrackColor: const Color(0xFFD96C3F),
                  title: const Text(
                    'Would make again',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Mark this as a recipe worth repeating.',
                  ),
                  secondary: Icon(
                    wouldMakeAgain ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: wouldMakeAgain
                        ? const Color(0xFFD96C3F)
                        : const Color(0xFF7C7470),
                  ),
                  onChanged: isSaving
                      ? null
                      : (bool value) {
                          setState(() {
                            wouldMakeAgain = value;
                          });
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _RecipeSectionCard(
            title: 'Recipe Tags',
            icon: Icons.sell_outlined,
            child: RecipeTags(
              selectedTags: selectedTags,
              enabled: !isSaving,
              onChanged: (List<String> tags) {
                setState(() {
                  selectedTags = tags;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          _RecipeSectionCard(
            title: 'Cookbook details',
            icon: Icons.menu_book_outlined,
            child: TextField(
              controller: pageController,
              decoration: const InputDecoration(
                labelText: 'Page number',
                hintText: 'For example: 42',
                prefixIcon: Icon(Icons.numbers_outlined),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RecipeSectionCard(
            title: 'Ingredients',
            icon: Icons.shopping_basket_outlined,
            child: TextField(
              controller: ingredientsController,
              minLines: 7,
              maxLines: 14,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Enter one ingredient per line',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RecipeSectionCard(
            title: 'Method',
            icon: Icons.format_list_numbered,
            child: TextField(
              controller: methodController,
              minLines: 9,
              maxLines: 18,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Enter the cooking instructions',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RecipeSectionCard(
            title: 'Notes',
            icon: Icons.sticky_note_2_outlined,
            child: TextField(
              controller: notesController,
              minLines: 4,
              maxLines: 9,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add changes, tips or reminders',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipePhotoHeader extends StatelessWidget {
  final String recipeName;
  final String cookbookName;
  final Uint8List? recipePhoto;
  final VoidCallback onTap;

  const _RecipePhotoHeader({
    required this.recipeName,
    required this.cookbookName,
    required this.recipePhoto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              height: 240,
              child: recipePhoto == null
                  ? Container(
                      color: const Color(0xFFFFE3D5),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 54,
                            color: Color(0xFFD96C3F),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Add recipe photo',
                            style: TextStyle(
                              color: Color(0xFFD96C3F),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to choose an image',
                            style: TextStyle(color: Color(0xFF8B6C5E)),
                          ),
                        ],
                      ),
                    )
                  : Image.memory(recipePhoto!, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipeName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                      color: Color(0xFF7C7470),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        cookbookName,
                        style: const TextStyle(
                          color: Color(0xFF7C7470),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hintText;

  const _SummaryField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 13, 10, 10),
        child: Column(
          children: [
            Icon(icon, size: 22, color: const Color(0xFFD96C3F)),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7C7470),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: hintText,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _RecipeSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3D5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 21, color: const Color(0xFFD96C3F)),
                ),
                const SizedBox(width: 11),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
