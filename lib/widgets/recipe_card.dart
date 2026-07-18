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
  Box? cookbookBox;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    openCookbookBox();
  }

  @override
  void didUpdateWidget(covariant RecipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cookbookName != widget.cookbookName ||
        oldWidget.recipeName != widget.recipeName) {
      openCookbookBox();
    }
  }

  Future<void> openCookbookBox() async {
    final String? cookbookName = widget.cookbookName;

    if (cookbookName == null || cookbookName.trim().isEmpty) {
      if (!mounted) return;

      setState(() {
        cookbookBox = null;
        isLoading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final Box box = Hive.isBoxOpen(cookbookName)
        ? Hive.box(cookbookName)
        : await Hive.openBox(cookbookName);

    if (!mounted) return;

    setState(() {
      cookbookBox = box;
      isLoading = false;
    });
  }

  Map<String, dynamic>? convertRecipe(dynamic savedRecipe) {
    if (savedRecipe is Map) {
      return Map<String, dynamic>.from(savedRecipe);
    }

    return null;
  }

  Uint8List? getRecipePhoto(Map<String, dynamic>? recipe) {
    final dynamic savedPhoto = recipe?['photo'];

    if (savedPhoto is Uint8List) {
      return savedPhoto;
    }

    if (savedPhoto is List<int>) {
      return Uint8List.fromList(savedPhoto);
    }

    if (savedPhoto is List) {
      try {
        return Uint8List.fromList(
          savedPhoto.map((dynamic value) => value as int).toList(),
        );
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  List<String> getTags(Map<String, dynamic>? recipe) {
    final dynamic savedTags = recipe?['tags'];

    if (savedTags is List) {
      return savedTags
          .map((dynamic tag) => tag.toString().trim())
          .where((String tag) => tag.isNotEmpty)
          .toList();
    }

    return [];
  }

  String getTimeText(Map<String, dynamic>? recipe) {
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
    if (isLoading) {
      return _RecipeLoadingCard(
        recipeName: widget.recipeName,
      );
    }

    final Box? box = cookbookBox;

    if (box == null) {
      return _RecipeCardContent(
        recipeName: widget.recipeName,
        recipe: null,
        onTap: widget.onTap,
        getRecipePhoto: getRecipePhoto,
        getTags: getTags,
        getTimeText: getTimeText,
      );
    }

    return ValueListenableBuilder<Box>(
      valueListenable: box.listenable(
        keys: <dynamic>[widget.recipeName],
      ),
      builder: (
        BuildContext context,
        Box updatedBox,
        Widget? child,
      ) {
        final Map<String, dynamic>? recipe = convertRecipe(
          updatedBox.get(widget.recipeName),
        );

        return _RecipeCardContent(
          recipeName: widget.recipeName,
          recipe: recipe,
          onTap: widget.onTap,
          getRecipePhoto: getRecipePhoto,
          getTags: getTags,
          getTimeText: getTimeText,
        );
      },
    );
  }
}

class _RecipeCardContent extends StatelessWidget {
  final String recipeName;
  final Map<String, dynamic>? recipe;
  final VoidCallback onTap;

  final Uint8List? Function(Map<String, dynamic>? recipe)
      getRecipePhoto;

  final List<String> Function(Map<String, dynamic>? recipe)
      getTags;

  final String Function(Map<String, dynamic>? recipe)
      getTimeText;

  const _RecipeCardContent({
    required this.recipeName,
    required this.recipe,
    required this.onTap,
    required this.getRecipePhoto,
    required this.getTags,
    required this.getTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? recipePhoto = getRecipePhoto(recipe);
    final List<String> tags = getTags(recipe);
    final String time = getTimeText(recipe);

    final String servings =
        recipe?['servings']?.toString().trim() ?? '';

    final String pageNumber =
        recipe?['pageNumber']?.toString().trim() ?? '';

    final bool favourite = recipe?['favourite'] == true;
    final bool wouldMakeAgain =
        recipe?['wouldMakeAgain'] == true;

    final int rating =
        int.tryParse(recipe?['rating']?.toString() ?? '') ?? 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecipeThumbnail(
                recipePhoto: recipePhoto,
                favourite: favourite,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    if (rating > 0 || wouldMakeAgain) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          if (rating > 0)
                            _CompactRating(rating: rating),
                          if (wouldMakeAgain)
                            const _WouldMakeAgainBadge(),
                        ],
                      ),
                    ],
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _RecipeInformation(
                        icon: Icons.schedule_outlined,
                        text: time,
                      ),
                    ],
                    if (servings.isNotEmpty ||
                        pageNumber.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 5,
                        children: [
                          if (servings.isNotEmpty)
                            _CompactInformation(
                              icon: Icons.people_outline,
                              text: 'Serves $servings',
                            ),
                          if (pageNumber.isNotEmpty)
                            _CompactInformation(
                              icon: Icons.menu_book_outlined,
                              text: 'Page $pageNumber',
                            ),
                        ],
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      _TagPreview(tags: tags),
                    ],
                    if (rating == 0 &&
                        !wouldMakeAgain &&
                        time.isEmpty &&
                        servings.isEmpty &&
                        pageNumber.isEmpty &&
                        tags.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
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
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8A817C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeThumbnail extends StatelessWidget {
  final Uint8List? recipePhoto;
  final bool favourite;

  const _RecipeThumbnail({
    required this.recipePhoto,
    required this.favourite,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            width: 94,
            height: 110,
            child: recipePhoto == null
                ? Container(
                    color: const Color(0xFFFFE3D5),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 38,
                      color: Color(0xFFD96C3F),
                    ),
                  )
                : Image.memory(
                    recipePhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Container(
                        color: const Color(0xFFFFE3D5),
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 38,
                          color: Color(0xFFD96C3F),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (favourite)
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 5,
                    color: Color(0x33000000),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                size: 18,
                color: Color(0xFFBF5151),
              ),
            ),
          ),
      ],
    );
  }
}

class _CompactRating extends StatelessWidget {
  final int rating;

  const _CompactRating({
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final int safeRating = rating.clamp(0, 5);

    return Semantics(
      label: '$safeRating out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          5,
          (int index) {
            return Icon(
              index < safeRating
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 17,
              color: index < safeRating
                  ? const Color(0xFFE2A329)
                  : const Color(0xFFAAA19C),
            );
          },
        ),
      ),
    );
  }
}

class _WouldMakeAgainBadge extends StatelessWidget {
  const _WouldMakeAgainBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3D5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.thumb_up_alt_rounded,
            size: 14,
            color: Color(0xFFD96C3F),
          ),
          SizedBox(width: 5),
          Text(
            'Make again',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9E482A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPreview extends StatelessWidget {
  final List<String> tags;

  const _TagPreview({
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    const int maximumVisibleTags = 2;

    final List<String> visibleTags =
        tags.take(maximumVisibleTags).toList();

    final int hiddenTagCount =
        tags.length - visibleTags.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visibleTags.map(
          (String tag) {
            return Container(
              constraints: const BoxConstraints(
                maxWidth: 115,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECE8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF655D59),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
        if (hiddenTagCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1ECE8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$hiddenTagCount',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF655D59),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
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
          size: 16,
          color: const Color(0xFF7C7470),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
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

class _CompactInformation extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CompactInformation({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFF7C7470),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7C7470),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RecipeLoadingCard extends StatelessWidget {
  final String recipeName;

  const _RecipeLoadingCard({
    required this.recipeName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 94,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3D5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 38,
                color: Color(0xFFD96C3F),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}