import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../services/ai_recipe_service.dart';
import '../services/recipe_parser.dart';
import 'recipe_page.dart';
import 'select_cookbook_page.dart';

enum _ImportMethod { none, scan, paste, website, pdf }

class ScanRecipePage extends StatefulWidget {
  const ScanRecipePage({super.key});

  @override
  State<ScanRecipePage> createState() => _ScanRecipePageState();
}

class _ScanRecipePageState extends State<ScanRecipePage> {
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController recognisedTextController =
      TextEditingController();

  final TextEditingController websiteUrlController =
      TextEditingController();

  Uint8List? selectedImageBytes;

  final List<RecipeImageUpload> selectedImages =
      <RecipeImageUpload>[];

  bool isReadingImage = false;
  bool isReadingPdf = false;

  String? selectedPdfName;

  _ImportMethod selectedMethod = _ImportMethod.none;

  bool get isBusy => isReadingImage || isReadingPdf;

  bool get hasText =>
      recognisedTextController.text.trim().isNotEmpty;

  bool get hasWebsiteUrl =>
      websiteUrlController.text.trim().isNotEmpty;

  bool get hasSelectedImages => selectedImages.isNotEmpty;

  @override
  void initState() {
    super.initState();

    recognisedTextController.addListener(refreshPage);
    websiteUrlController.addListener(refreshPage);
  }

  void refreshPage() {
    if (!mounted) return;

    setState(() {});
  }

  void selectMethod(_ImportMethod method) {
    setState(() {
      selectedMethod = method;
    });

    if (method == _ImportMethod.scan) {
      if (selectedImages.isEmpty) {
        showImageOptions();
      }
    } else if (method == _ImportMethod.pdf) {
      choosePdf();
    }
  }

  Future<void> chooseImage(ImageSource source) async {
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

      final RecipeImageUpload newImage =
          RecipeImageUpload(
        imageBytes: imageBytes,
        mimeType:
            pickedImage.mimeType ?? 'image/jpeg',
      );

      setState(() {
        selectedMethod = _ImportMethod.scan;

        selectedImages.add(newImage);

        // Display the most recently added image
        // in the larger preview area.
        selectedImageBytes = imageBytes;

        selectedPdfName = null;
        recognisedTextController.clear();
      });
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

  Future<void> extractSelectedImages() async {
    if (selectedImages.isEmpty || isReadingImage) {
      return;
    }

    if (selectedImages.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can scan a maximum of four pages '
            'for one recipe.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isReadingImage = true;
    });

    try {
      final ParsedRecipe recipe =
          await AiRecipeService.extractRecipeFromImages(
        images: List<RecipeImageUpload>.from(
          selectedImages,
        ),
      );

      if (!mounted) return;

      setState(() {
        isReadingImage = false;
      });

      await showRecipePreview(recipe);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isReadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  void selectImagePreview(int index) {
    if (index < 0 ||
        index >= selectedImages.length) {
      return;
    }

    setState(() {
      selectedImageBytes =
          selectedImages[index].imageBytes;
    });
  }

  void removeSelectedImage(int index) {
    if (index < 0 ||
        index >= selectedImages.length ||
        isReadingImage) {
      return;
    }

    setState(() {
      final Uint8List removedImage =
          selectedImages[index].imageBytes;

      selectedImages.removeAt(index);

      if (selectedImages.isEmpty) {
        selectedImageBytes = null;
      } else if (identical(
        selectedImageBytes,
        removedImage,
      )) {
        selectedImageBytes =
            selectedImages.last.imageBytes;
      }
    });
  }

  Future<void> choosePdf() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
        withData: true,
      );

      if (result == null) return;

      final PlatformFile pickedFile = result.files.single;
      final Uint8List? pdfBytes = pickedFile.bytes;

      if (pdfBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The PDF could not be loaded. Please choose it again.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        selectedMethod = _ImportMethod.pdf;
        selectedPdfName = pickedFile.name;
        selectedImageBytes = null;
        selectedImages.clear();
        recognisedTextController.clear();
        isReadingPdf = true;
      });

      PdfDocument? document;

      try {
        document = PdfDocument(inputBytes: pdfBytes);
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        final String extractedText = extractor.extractText().trim();

        if (!mounted) return;
        recognisedTextController.text = extractedText;

        if (extractedText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No selectable text was found in this PDF. '
                'It may contain scanned page images rather than text.',
              ),
            ),
          );
        }
      } finally {
        document?.dispose();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The PDF could not be read: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isReadingPdf = false;
        });
      }
    }
  }

  void showImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose recipe page',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: const Color(0xFFFFE3D5),
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFD96C3F),
                  ),
                  title: const Text('Take a photo'),
                  subtitle: const Text('Photograph a cookbook page'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    chooseImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Colors.white,
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFD96C3F),
                  ),
                  title: const Text('Choose from gallery'),
                  subtitle: const Text('Use an existing recipe photo'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    chooseImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void clearImport() {
  setState(() {
    selectedMethod = _ImportMethod.none;
    selectedImageBytes = null;
    selectedImages.clear();
    selectedPdfName = null;
    recognisedTextController.clear();
    websiteUrlController.clear();
  });
}

  void turnTextIntoRecipe() {
    final String text = recognisedTextController.text.trim();
    if (text.isEmpty) return;

    final ParsedRecipe recipe = RecipeParser.parse(text);
    showRecipePreview(recipe);
  }

  Future<void> showRecipePreview(ParsedRecipe recipe) async {
    final TextEditingController nameController =
        TextEditingController(text: recipe.name);
    final TextEditingController prepController =
        TextEditingController(text: recipe.prepTime);
    final TextEditingController cookController =
        TextEditingController(text: recipe.cookTime);
    final TextEditingController servingsController =
        TextEditingController(text: recipe.servings);
    final TextEditingController ingredientsController =
        TextEditingController(text: recipe.ingredients);
    final TextEditingController methodController =
        TextEditingController(text: recipe.method);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF8F5F2),
      builder: (BuildContext bottomSheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.94,
          minChildSize: 0.65,
          maxChildSize: 0.98,
          builder: (
            BuildContext sheetContext,
            ScrollController scrollController,
          ) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 10, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recipe preview',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Check the details before saving.',
                              style: TextStyle(color: Color(0xFF7C7470)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                    children: [
                      _PreviewSection(
                        title: 'Recipe',
                        icon: Icons.restaurant_menu,
                        child: TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Recipe name',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: prepController,
                              decoration: const InputDecoration(
                                labelText: 'Prep time',
                                hintText: '20 mins',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: cookController,
                              decoration: const InputDecoration(
                                labelText: 'Cook time',
                                hintText: '35 mins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: servingsController,
                        decoration: const InputDecoration(
                          labelText: 'Servings',
                          hintText: '4',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PreviewSection(
                        title: 'Ingredients',
                        icon: Icons.shopping_basket_outlined,
                        child: TextField(
                          controller: ingredientsController,
                          minLines: 7,
                          maxLines: 14,
                          decoration: const InputDecoration(
                            hintText: 'One ingredient per line',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PreviewSection(
                        title: 'Method',
                        icon: Icons.format_list_numbered,
                        child: TextField(
                          controller: methodController,
                          minLines: 9,
                          maxLines: 18,
                          decoration: const InputDecoration(
                            hintText: 'Cooking instructions',
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
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
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
                              sheetContext,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SelectCookbookPage(),
                              ),
                            );

                            if (!sheetContext.mounted || cookbook == null) {
                              return;
                            }

                            final bool? saved =
                                await Navigator.push<bool>(
                              sheetContext,
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
                                  initialPhoto: selectedImageBytes,
                                ),
                              ),
                            );

                            if (!mounted ||
                                !bottomSheetContext.mounted) {
                              return;
                            }

                            if (saved == true) {
                              Navigator.pop(bottomSheetContext);
                              clearImport();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$recipeName added to $cookbook',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Choose Cookbook and Save'),
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

  Widget buildImportMethodGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How would you like to add it?',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ImportMethodCard(
                title: 'Scan Page',
                subtitle: 'Camera or gallery',
                icon: Icons.document_scanner_outlined,
                backgroundColor: const Color(0xFFFFE3D5),
                foregroundColor: const Color(0xFFD96C3F),
                isSelected: selectedMethod == _ImportMethod.scan,
                onTap: () => selectMethod(_ImportMethod.scan),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImportMethodCard(
                title: 'Paste Text',
                subtitle: 'Copy a recipe',
                icon: Icons.content_paste_outlined,
                backgroundColor: const Color(0xFFE8F5E9),
                foregroundColor: const Color(0xFF2E7D32),
                isSelected: selectedMethod == _ImportMethod.paste,
                onTap: () => selectMethod(_ImportMethod.paste),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ImportMethodCard(
                title: 'Website',
                subtitle: 'Paste link and text',
                icon: Icons.language_outlined,
                backgroundColor: const Color(0xFFE8EEF8),
                foregroundColor: const Color(0xFF4F678A),
                isSelected: selectedMethod == _ImportMethod.website,
                onTap: () => selectMethod(_ImportMethod.website),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImportMethodCard(
                title: 'PDF',
                subtitle: 'Extract recipe text',
                icon: Icons.picture_as_pdf_outlined,
                backgroundColor: const Color(0xFFFFE8E5),
                foregroundColor: const Color(0xFFB94747),
                isSelected: selectedMethod == _ImportMethod.pdf,
                onTap: isBusy
                    ? () {}
                    : () => selectMethod(_ImportMethod.pdf),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSelectedImportArea() {
    switch (selectedMethod) {
      case _ImportMethod.scan:
        return buildScanArea();
      case _ImportMethod.paste:
        return buildTextArea(
          title: 'Paste recipe text',
          subtitle:
              'Copy the full recipe, including ingredients and method.',
          icon: Icons.content_paste_outlined,
        );
      case _ImportMethod.website:
        return buildWebsiteArea();
      case _ImportMethod.pdf:
        return buildPdfArea();
      case _ImportMethod.none:
        return const _ImportHelpCard();
    }
  }

  Widget buildScanArea() {
  return Column(
    children: [
      Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 260,
              child: selectedImageBytes == null
                  ? Container(
                      color: const Color(0xFFFFE3D5),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 70,
                            color: Color(0xFFD96C3F),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Scan a cookbook page',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 7),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 34,
                            ),
                            child: Text(
                              'Keep the page flat, clear and well lit.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF7C7470),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedImages.isNotEmpty) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recipe pages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${selectedImages.length}/4',
                          style: const TextStyle(
                            color: Color(0xFF7C7470),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        separatorBuilder: (_, _) => 
                            const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                          final RecipeImageUpload image =
                              selectedImages[index];

                          final bool isSelected =
                              identical(
                                selectedImageBytes,
                                image.imageBytes,
                              );

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    selectImagePreview(index),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 180),
                                  width: 78,
                                  height: 94,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFD96C3F)
                                          : const Color(0xFFE2DDD8),
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: Image.memory(
                                      image.imageBytes,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -7,
                                right: -7,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  child: IconButton(
                                    tooltip:
                                        'Remove page ${index + 1}',
                                    visualDensity:
                                        VisualDensity.compact,
                                    iconSize: 18,
                                    onPressed: isReadingImage
                                        ? null
                                        : () =>
                                            removeSelectedImage(index),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF8A4545),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 6,
                                bottom: 6,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.tonalIcon(
                      onPressed: isReadingImage ||
                              selectedImages.length >= 4
                          ? null
                          : showImageOptions,
                      icon: const Icon(
                        Icons.add_a_photo_outlined,
                      ),
                      label: Text(
                        selectedImages.isEmpty
                            ? 'Choose Recipe Page'
                            : selectedImages.length >= 4
                                ? 'Maximum 4 Pages'
                                : 'Add Another Page',
                      ),
                    ),
                  ),
                  if (selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: isReadingImage
                            ? null
                            : extractSelectedImages,
                        icon: isReadingImage
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          isReadingImage
                              ? 'Extracting Recipe...'
                              : 'Extract Recipe',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget buildWebsiteArea() {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.language_outlined,
                      color: Color(0xFF4F678A),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Recipe website',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: websiteUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Recipe URL',
                    hintText: 'https://example.com/recipe',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Automatic website reading needs a secure server. '
                    'For now, copy the recipe text from the website and '
                    'paste it below.',
                    style: TextStyle(color: Color(0xFF75622E)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        buildTextArea(
          title: 'Website recipe text',
          subtitle: hasWebsiteUrl
              ? 'Paste the recipe from the link above.'
              : 'Add the link, then paste the recipe text.',
          icon: Icons.content_paste_outlined,
        ),
      ],
    );
  }

  Widget buildPdfArea() {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 34,
                    color: Color(0xFFB94747),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  selectedPdfName ?? 'Choose a recipe PDF',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isReadingPdf
                      ? 'Extracting text from the PDF...'
                      : selectedPdfName == null
                          ? 'Text-based PDFs can be imported automatically.'
                          : 'The extracted text is shown below for checking.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF7C7470)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.tonalIcon(
                    onPressed: isReadingPdf ? null : choosePdf,
                    icon: isReadingPdf
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(
                      selectedPdfName == null
                          ? 'Choose PDF'
                          : 'Choose Another PDF',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Image-only scanned PDFs may not contain selectable '
                    'text. Those will need PDF OCR in a later update.',
                    style: TextStyle(color: Color(0xFF75622E)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        buildTextArea(
          title: 'Extracted PDF text',
          subtitle: 'Check and correct the text before creating the recipe.',
          icon: Icons.text_snippet_outlined,
        ),
      ],
    );
  }

  Widget buildTextArea({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3D5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: const Color(0xFFD96C3F)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFF7C7470)),
                      ),
                    ],
                  ),
                ),
                if (isBusy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: recognisedTextController,
              minLines: 12,
              maxLines: 24,
              readOnly: isBusy,
              decoration: const InputDecoration(
                hintText:
                    'Paste the recipe name, ingredients and method here.',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    recognisedTextController.removeListener(refreshPage);
    websiteUrlController.removeListener(refreshPage);
    recognisedTextController.dispose();
    websiteUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Import Recipe'),
        actions: [
          if (selectedMethod != _ImportMethod.none ||
              selectedImageBytes != null ||
              selectedPdfName != null ||
              hasText ||
              hasWebsiteUrl)
            IconButton(
              tooltip: 'Clear import',
              onPressed: isBusy ? null : clearImport,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          const Text(
            'Add recipes from cookbooks, websites, PDFs or copied text.',
            style: TextStyle(fontSize: 16, color: Color(0xFF706A66)),
          ),
          const SizedBox(height: 22),
          buildImportMethodGrid(),
          const SizedBox(height: 22),
          buildSelectedImportArea(),
          if (selectedMethod == _ImportMethod.paste ||
          selectedMethod == _ImportMethod.website ||
          selectedMethod == _ImportMethod.pdf) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: !hasText || isBusy ? null : turnTextIntoRecipe,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Turn Text Into Recipe'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ImportMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? foregroundColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foregroundColor, size: 30),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: foregroundColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportHelpCard extends StatelessWidget {
  const _ImportHelpCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3D5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: 32,
                color: Color(0xFFD96C3F),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Choose an import method',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            const Text(
              'Your recipe will be organised into ingredients, timings '
              'and cooking instructions before you save it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7C7470), height: 1.4),
            ),
          ],
        ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFD96C3F)),
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
