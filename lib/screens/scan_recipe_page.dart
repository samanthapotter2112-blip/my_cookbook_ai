import 'package:hive_flutter/hive_flutter.dart';

import 'recipe_page.dart';
import 'select_cookbook_page.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../services/recipe_parser.dart';

class ScanRecipePage extends StatefulWidget {
  const ScanRecipePage({super.key});

  @override
  State<ScanRecipePage> createState() => _ScanRecipePageState();
}

class _ScanRecipePageState extends State<ScanRecipePage> {
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController recognisedTextController =
      TextEditingController();

  File? selectedImage;

  bool isReadingImage = false;

  @override
  void initState() {
    super.initState();

    recognisedTextController.addListener(
      refreshButtonState,
    );
  }

  void refreshButtonState() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> chooseImage(ImageSource source) async {
    try {
      final XFile? pickedImage = await imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedImage == null) {
        return;
      }

      setState(() {
        selectedImage = File(pickedImage.path);
        recognisedTextController.clear();
      });

      await recogniseText(pickedImage.path);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not select the image: $error',
          ),
        ),
      );
    }
  }

  Future<void> recogniseText(String imagePath) async {
    setState(() {
      isReadingImage = true;
    });

    final InputImage inputImage =
        InputImage.fromFilePath(imagePath);

    final TextRecognizer textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final RecognizedText recognisedText =
          await textRecognizer.processImage(inputImage);

      if (!mounted) return;

      recognisedTextController.text =
          recognisedText.text.trim();

      if (recognisedText.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No text was found. Try taking a clearer photo.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The page could not be read: $error',
          ),
        ),
      );
    } finally {
      await textRecognizer.close();

      if (!mounted) return;

      setState(() {
        isReadingImage = false;
      });
    }
  }

  void showImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);

                    chooseImage(
                      ImageSource.camera,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);

                    chooseImage(
                      ImageSource.gallery,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void clearScan() {
    setState(() {
      selectedImage = null;
      recognisedTextController.clear();
    });
  }

  void turnTextIntoRecipe() {
    final String text =
        recognisedTextController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final ParsedRecipe recipe =
        RecipeParser.parse(text);

    showRecipePreview(recipe);
  }

  Future<void> showRecipePreview(
    ParsedRecipe recipe,
  ) async {
    final TextEditingController nameController =
        TextEditingController(
      text: recipe.name,
    );

    final TextEditingController prepController =
        TextEditingController(
      text: recipe.prepTime,
    );

    final TextEditingController cookController =
        TextEditingController(
      text: recipe.cookTime,
    );

    final TextEditingController servingsController =
        TextEditingController(
      text: recipe.servings,
    );

    final TextEditingController ingredientsController =
        TextEditingController(
      text: recipe.ingredients,
    );

    final TextEditingController methodController =
        TextEditingController(
      text: recipe.method,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.55,
          maxChildSize: 0.96,
          builder: (
            context,
            scrollController,
          ) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    14,
                    12,
                    8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recipe Preview',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () {
                          Navigator.pop(
                            bottomSheetContext,
                          );
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Check the details and correct anything '
                        'that was not recognised properly.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration:
                            const InputDecoration(
                          labelText: 'Recipe name',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.restaurant_menu),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                                  prepController,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Prep time',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller:
                                  cookController,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Cook time',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller:
                            servingsController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Servings',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.people_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller:
                            ingredientsController,
                        minLines: 6,
                        maxLines: 12,
                        decoration:
                            const InputDecoration(
                          labelText: 'Ingredients',
                          hintText:
                              'Enter one ingredient per line',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: methodController,
                        minLines: 8,
                        maxLines: 16,
                        decoration:
                            const InputDecoration(
                          labelText: 'Method',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final cookbook = await Navigator.push<String>(
                            context,
    MaterialPageRoute(
      builder: (_) => const SelectCookbookPage(),
    ),
  );

  if (cookbook == null) return;

  final recipeBox = Hive.isBoxOpen(cookbook)
      ? Hive.box(cookbook)
      : await Hive.openBox(cookbook);

  if (!recipeBox.values.contains(
    nameController.text.trim(),
  )) {
    await recipeBox.add(
      nameController.text.trim(),
    );
  }

  if (!mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RecipePage(
        cookbookName: cookbook,
        recipeName: nameController.text.trim(),
        initialPrepTime: prepController.text,
        initialCookTime: cookController.text,
        initialServings: servingsController.text,
        initialIngredients:
            ingredientsController.text,
        initialMethod: methodController.text,
      ),
    ),
  );
},
                          icon: const Icon(
                            Icons.arrow_forward,
                          ),
                          label: const Text(
                            'Continue to Save Recipe',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    prepController.dispose();
    cookController.dispose();
    servingsController.dispose();
    ingredientsController.dispose();
    methodController.dispose();
  }

  @override
  void dispose() {
    recognisedTextController.removeListener(
      refreshButtonState,
    );

    recognisedTextController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRecognisedText =
        recognisedTextController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Scan Recipe'),
        actions: [
          if (selectedImage != null ||
              hasRecognisedText)
            IconButton(
              onPressed:
                  isReadingImage ? null : clearScan,
              tooltip: 'Clear scan',
              icon: const Icon(
                Icons.delete_outline,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 260,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.orange.shade200,
              ),
            ),
            child: selectedImage == null
                ? const Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner_outlined,
                        size: 70,
                        color: Colors.deepOrange,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Photograph a cookbook page',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        child: Text(
                          'Make sure the page is flat, '
                          'clear and well lit.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : Image.file(
                    selectedImage!,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  isReadingImage ? null : showImageOptions,
              icon: const Icon(Icons.add_a_photo),
              label: Text(
                selectedImage == null
                    ? 'Choose Recipe Page'
                    : 'Choose Another Page',
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recognised text',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isReadingImage)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'You can correct any words that were not '
            'read properly.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: recognisedTextController,
            minLines: 12,
            maxLines: 24,
            readOnly: isReadingImage,
            decoration: InputDecoration(
              hintText:
                  'The text from your cookbook page '
                  'will appear here.',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  !hasRecognisedText || isReadingImage
                      ? null
                      : turnTextIntoRecipe,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Turn Text Into Recipe',
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}