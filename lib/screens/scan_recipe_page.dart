import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../services/recipe_parser.dart';
import 'recipe_page.dart';
import 'select_cookbook_page.dart';

class ScanRecipePage extends StatefulWidget {
  const ScanRecipePage({super.key});

  @override
  State<ScanRecipePage> createState() => _ScanRecipePageState();
}

class _ScanRecipePageState extends State<ScanRecipePage> {
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController recognisedTextController =
      TextEditingController();

  Uint8List? selectedImageBytes;

  bool isReadingImage = false;

  @override
  void initState() {
    super.initState();

    recognisedTextController.addListener(
      refreshPage,
    );
  }

  void refreshPage() {
    if (!mounted) return;

    setState(() {});
  }

  bool get supportsAutomaticOcr {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform ==
            TargetPlatform.iOS ||
        defaultTargetPlatform ==
            TargetPlatform.android;
  }

  Future<void> chooseImage(
    ImageSource source,
  ) async {
    try {
      final XFile? pickedImage =
          await imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedImage == null) return;

      final Uint8List imageBytes =
          await pickedImage.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImageBytes = imageBytes;
        recognisedTextController.clear();
      });

      if (supportsAutomaticOcr) {
        await recogniseText(
          pickedImage.path,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Automatic page reading is available '
              'on iPhone and Android. You can type or '
              'paste the recipe text below while '
              'testing on Windows or Chrome.',
            ),
          ),
        );
      }
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

  Future<void> recogniseText(
    String imagePath,
  ) async {
    setState(() {
      isReadingImage = true;
    });

    final TextRecognizer recogniser =
        TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final InputImage image =
          InputImage.fromFilePath(imagePath);

      final RecognizedText recognisedText =
          await recogniser.processImage(image);

      if (!mounted) return;

      recognisedTextController.text =
          recognisedText.text.trim();

      if (recognisedText.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No text was found. Try taking a '
              'clearer, brighter photo.',
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
      await recogniser.close();

      if (mounted) {
        setState(() {
          isReadingImage = false;
        });
      }
    }
  }

  void showImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (
        BuildContext bottomSheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose recipe page',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  tileColor:
                      const Color(0xFFFFE3D5),
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFD96C3F),
                  ),
                  title:
                      const Text('Take a photo'),
                  subtitle: const Text(
                    'Photograph a cookbook page',
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    chooseImage(
                      ImageSource.camera,
                    );
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  tileColor: Colors.white,
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFD96C3F),
                  ),
                  title: const Text(
                    'Choose from gallery',
                  ),
                  subtitle: const Text(
                    'Use an existing recipe photo',
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );

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
      selectedImageBytes = null;
      recognisedTextController.clear();
    });
  }

  void turnTextIntoRecipe() {
    final String text =
        recognisedTextController.text.trim();

    if (text.isEmpty) return;

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
      backgroundColor:
          const Color(0xFFF8F5F2),
      builder: (
        BuildContext bottomSheetContext,
      ) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.94,
          minChildSize: 0.65,
          maxChildSize: 0.98,
          builder: (
            BuildContext context,
            ScrollController scrollController,
          ) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    10,
                    8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recipe preview',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Check the details before saving.',
                              style: TextStyle(
                                color:
                                    Color(0xFF7C7470),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () {
                          Navigator.pop(
                            bottomSheetContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      30,
                    ),
                    children: [
                      _PreviewSection(
                        title: 'Recipe',
                        icon:
                            Icons.restaurant_menu,
                        child: TextField(
                          controller:
                              nameController,
                          textCapitalization:
                              TextCapitalization
                                  .words,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Recipe name',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                                  prepController,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Prep time',
                                hintText: '20 mins',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller:
                                  cookController,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Cook time',
                                hintText: '35 mins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller:
                            servingsController,
                        decoration:
                            const InputDecoration(
                          labelText: 'Servings',
                          hintText: '4',
                          prefixIcon:
                              Icon(Icons.people_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PreviewSection(
                        title: 'Ingredients',
                        icon: Icons
                            .shopping_basket_outlined,
                        child: TextField(
                          controller:
                              ingredientsController,
                          minLines: 7,
                          maxLines: 14,
                          decoration:
                              const InputDecoration(
                            hintText:
                                'One ingredient per line',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PreviewSection(
                        title: 'Method',
                        icon:
                            Icons.format_list_numbered,
                        child: TextField(
                          controller:
                              methodController,
                          minLines: 9,
                          maxLines: 18,
                          decoration:
                              const InputDecoration(
                            hintText:
                                'Cooking instructions',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
  height: 54,
  child: FilledButton.icon(
    onPressed: () async {
      final String recipeName =
          nameController.text.trim();

      if (recipeName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a recipe name.',
            ),
          ),
        );

        return;
      }

      final String? cookbook =
    await Navigator.push<String>(
  context,
  MaterialPageRoute(
    builder: (_) =>
        const SelectCookbookPage(),
  ),
);

if (!context.mounted ||
    cookbook == null) {
  return;
}

      final bool? saved =
          await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RecipePage(
            cookbookName: cookbook,
            recipeName: recipeName,
            initialPrepTime:
                prepController.text.trim(),
            initialCookTime:
                cookController.text.trim(),
            initialServings:
                servingsController.text.trim(),
            initialIngredients:
                ingredientsController.text.trim(),
            initialMethod:
                methodController.text.trim(),
            initialPhoto:
                selectedImageBytes,
          ),
        ),
      );

      if (!mounted ||
          !bottomSheetContext.mounted) {
        return;
      }

      if (saved == true) {
        Navigator.pop(
          bottomSheetContext,
        );

        clearScan();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$recipeName added to $cookbook',
            ),
          ),
        );
      }
    },
    icon: const Icon(
      Icons.menu_book_outlined,
    ),
    label: const Text(
      'Choose Cookbook and Save',
    ),
  ),
),
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
      refreshPage,
    );

    recognisedTextController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText =
        recognisedTextController.text
            .trim()
            .isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Scan Recipe'),
        actions: [
          if (selectedImageBytes != null || hasText)
            IconButton(
              tooltip: 'Clear scan',
              onPressed:
                  isReadingImage ? null : clearScan,
              icon: const Icon(
                Icons.delete_outline,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          30,
        ),
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 270,
                  child: selectedImageBytes == null
                      ? Container(
                          color: const Color(
                            0xFFFFE3D5,
                          ),
                          child: const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons
                                    .document_scanner_outlined,
                                size: 70,
                                color:
                                    Color(0xFFD96C3F),
                              ),
                              SizedBox(height: 15),
                              Text(
                                'Scan a cookbook page',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 7),
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(
                                  horizontal: 34,
                                ),
                                child: Text(
                                  'Keep the page flat, clear '
                                  'and well lit.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color: Color(
                                      0xFF7C7470,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Image.memory(
                          selectedImageBytes!,
                          fit: BoxFit.cover,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.tonalIcon(
                      onPressed: isReadingImage
                          ? null
                          : showImageOptions,
                      icon: const Icon(
                        Icons.add_a_photo_outlined,
                      ),
                      label: Text(
                        selectedImageBytes == null
                            ? 'Choose Recipe Page'
                            : 'Choose Another Page',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFE3D5,
                          ),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.text_snippet_outlined,
                          color: Color(0xFFD96C3F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recognised text',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Correct anything that was '
                              'not read properly.',
                              style: TextStyle(
                                color:
                                    Color(0xFF7C7470),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isReadingImage)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        ),
                    ],
                  ),
                  if (!supportsAutomaticOcr) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFFF4D8,
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'While testing on Windows or '
                        'Chrome, paste or type the recipe '
                        'text below. Automatic OCR will '
                        'work on the iPhone version.',
                        style: TextStyle(
                          color: Color(0xFF75622E),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller:
                        recognisedTextController,
                    minLines: 12,
                    maxLines: 24,
                    readOnly: isReadingImage,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'The recipe text will appear here.',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  !hasText || isReadingImage
                      ? null
                      : turnTextIntoRecipe,
              icon: const Icon(
                Icons.auto_awesome,
              ),
              label: const Text(
                'Turn Text Into Recipe',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _PreviewSection({
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFFD96C3F),
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}