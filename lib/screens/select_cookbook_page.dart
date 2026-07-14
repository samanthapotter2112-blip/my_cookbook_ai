import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SelectCookbookPage extends StatefulWidget {
  const SelectCookbookPage({super.key});

  @override
  State<SelectCookbookPage> createState() =>
      _SelectCookbookPageState();
}

class _SelectCookbookPageState
    extends State<SelectCookbookPage> {
  Box? cookbookListBox;
  Box? cookbookCoversBox;

  List<String> cookbooks = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCookbooks();
  }

  Future<void> loadCookbooks() async {
    cookbookListBox = Hive.isBoxOpen('cookbooks')
        ? Hive.box('cookbooks')
        : await Hive.openBox('cookbooks');

    cookbookCoversBox = Hive.isBoxOpen('cookbook_covers')
        ? Hive.box('cookbook_covers')
        : await Hive.openBox('cookbook_covers');

    final List<String> loadedCookbooks =
        cookbookListBox!.values
            .map(
              (dynamic value) =>
                  value.toString().trim(),
            )
            .where(
              (String name) => name.isNotEmpty,
            )
            .toList();

    loadedCookbooks.sort(
      (String first, String second) {
        return first.toLowerCase().compareTo(
              second.toLowerCase(),
            );
      },
    );

    if (!mounted) return;

    setState(() {
      cookbooks = loadedCookbooks;
      isLoading = false;
    });
  }

  Uint8List? getCookbookCover(
    String cookbookName,
  ) {
    final dynamic savedCover =
        cookbookCoversBox?.get(cookbookName);

    if (savedCover is Uint8List) {
      return savedCover;
    }

    if (savedCover is List<int>) {
      return Uint8List.fromList(savedCover);
    }

    return null;
  }

  Future<int> getRecipeCount(
    String cookbookName,
  ) async {
    final Box cookbookBox =
        Hive.isBoxOpen(cookbookName)
            ? Hive.box(cookbookName)
            : await Hive.openBox(cookbookName);

    return cookbookBox.length;
  }

  void chooseCookbook(
    String cookbookName,
  ) {
    Navigator.pop(
      context,
      cookbookName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Choose Cookbook'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : cookbooks.isEmpty
              ? const _EmptyCookbooks()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    30,
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        4,
                        0,
                        4,
                        16,
                      ),
                      child: Text(
                        'Where would you like to save this recipe?',
                        style: TextStyle(
                          fontSize: 17,
                          color: Color(0xFF7C7470),
                        ),
                      ),
                    ),
                    ...cookbooks.map(
                      (String cookbookName) {
                        return _CookbookChoiceCard(
                          cookbookName:
                              cookbookName,
                          cover: getCookbookCover(
                            cookbookName,
                          ),
                          recipeCountFuture:
                              getRecipeCount(
                            cookbookName,
                          ),
                          onTap: () {
                            chooseCookbook(
                              cookbookName,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}

class _CookbookChoiceCard extends StatelessWidget {
  final String cookbookName;
  final Uint8List? cover;
  final Future<int> recipeCountFuture;
  final VoidCallback onTap;

  const _CookbookChoiceCard({
    required this.cookbookName,
    required this.cover,
    required this.recipeCountFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              SizedBox(
                width: 92,
                height: 112,
                child: cover == null
                    ? Container(
                        color: const Color(
                          0xFFFFE3D5,
                        ),
                        child: const Icon(
                          Icons.menu_book_outlined,
                          size: 38,
                          color: Color(
                            0xFFD96C3F,
                          ),
                        ),
                      )
                    : Image.memory(
                        cover!,
                        fit: BoxFit.cover,
                      ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    14,
                    10,
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        cookbookName,
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
                      const SizedBox(height: 8),
                      FutureBuilder<int>(
                        future:
                            recipeCountFuture,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<int>
                              snapshot,
                        ) {
                          final int count =
                              snapshot.data ?? 0;

                          return Row(
                            children: [
                              const Icon(
                                Icons
                                    .restaurant_menu,
                                size: 16,
                                color: Color(
                                  0xFF7C7470,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$count '
                                '${count == 1 ? 'recipe' : 'recipes'}',
                                style:
                                    const TextStyle(
                                  color: Color(
                                    0xFF7C7470,
                                  ),
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(
                  right: 14,
                ),
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

class _EmptyCookbooks extends StatelessWidget {
  const _EmptyCookbooks();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 76,
              color: Color(0xFFAAA19C),
            ),
            SizedBox(height: 18),
            Text(
              'No cookbooks available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Create a cookbook from the Home page, '
              'then return to save this recipe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF7C7470),
              ),
            ),
          ],
        ),
      ),
    );
  }
}