import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecipeCard extends StatefulWidget {
  final String recipeName;
  final String? cookbookName;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipeName,
    required this.onTap,
    this.cookbookName,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  Map<String, dynamic>? recipe;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRecipe();
  }

  Future<void> loadRecipe() async {
    final String? cookbookName = widget.cookbookName;

    if (cookbookName == null || cookbookName.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    final Box cookbookBox = Hive.isBoxOpen(cookbookName)
        ? Hive.box(cookbookName)
        : await Hive.openBox(cookbookName);

    final dynamic savedRecipe =
        cookbookBox.get(widget.recipeName);

    if (!mounted) return;

    setState(() {
      if (savedRecipe is Map) {
        recipe = Map<String, dynamic>.from(
          savedRecipe,
        );
      }

      isLoading = false;
    });
  }

  Uint8List? getRecipePhoto() {
    final dynamic savedPhoto = recipe?['photo'];

    if (savedPhoto is Uint8List) {
      return savedPhoto;
    }

    if (savedPhoto is List<int>) {
      return Uint8List.fromList(savedPhoto);
    }

    return null;
  }

  String getTotalTime() {
    final String prepTime =
        recipe?['prepTime']?.toString().trim() ?? '';

    final String cookTime =
        recipe?['cookTime']?.toString().trim() ?? '';

    if (prepTime.isNotEmpty && cookTime.isNotEmpty) {
      return '$prepTime prep · $cookTime cook';
    }

    if (prepTime.isNotEmpty) {
      return '$prepTime prep';
    }

    if (cookTime.isNotEmpty) {
      return '$cookTime cook';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? recipePhoto = getRecipePhoto();

    final String time = getTotalTime();

    final String servings =
        recipe?['servings']?.toString().trim() ?? '';

    final String pageNumber =
        recipe?['pageNumber']?.toString().trim() ?? '';

    final bool favourite =
        recipe?['favourite'] == true;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: recipePhoto == null
                      ? Container(
                          color: const Color(0xFFFFE3D5),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 36,
                            color: Color(0xFFD96C3F),
                          ),
                        )
                      : Image.memory(
                          recipePhoto,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: isLoading
                    ? const LinearProgressIndicator()
                    : Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.recipeName,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.bold,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              if (favourite)
                                const Padding(
                                  padding:
                                      EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.favorite,
                                    color: Color(0xFFBF5151),
                                    size: 21,
                                  ),
                                ),
                            ],
                          ),
                          if (time.isNotEmpty) ...[
                            const SizedBox(height: 9),
                            _RecipeInformation(
                              icon: Icons.schedule,
                              text: time,
                            ),
                          ],
                          if (servings.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _RecipeInformation(
                              icon: Icons.people_outline,
                              text: 'Serves $servings',
                            ),
                          ],
                          if (pageNumber.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _RecipeInformation(
                              icon: Icons.menu_book_outlined,
                              text: 'Page $pageNumber',
                            ),
                          ],
                          if (time.isEmpty &&
                              servings.isEmpty &&
                              pageNumber.isEmpty)
                            const Padding(
                              padding:
                                  EdgeInsets.only(top: 8),
                              child: Text(
                                'Tap to view recipe',
                                style: TextStyle(
                                  color: Color(0xFF7C7470),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF8A817C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeInformation extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecipeInformation({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF7C7470),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C7470),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}