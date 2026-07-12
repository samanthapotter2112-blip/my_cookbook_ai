import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'cookbook_page.dart';
import 'favourites_page.dart';
import 'scan_recipe_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController cookbookNameController =
      TextEditingController();

  late Box cookbookListBox;
  Box? cookbookCoversBox;

  List<_CookbookEntry> cookbooks = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    cookbookListBox = Hive.box('cookbooks');
    initialisePage();
  }

  Future<void> initialisePage() async {
    cookbookCoversBox = Hive.isBoxOpen('cookbook_covers')
        ? Hive.box('cookbook_covers')
        : await Hive.openBox('cookbook_covers');

    loadCookbooks();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  void loadCookbooks() {
    final List<_CookbookEntry> loadedCookbooks = [];

    for (final dynamic key in cookbookListBox.keys) {
      final dynamic value = cookbookListBox.get(key);

      if (value == null) continue;

      final String cookbookName = value.toString().trim();

      if (cookbookName.isEmpty) continue;

      loadedCookbooks.add(
        _CookbookEntry(
          key: key,
          name: cookbookName,
        ),
      );
    }

    loadedCookbooks.sort(
      (_CookbookEntry first, _CookbookEntry second) {
        return first.name.toLowerCase().compareTo(
              second.name.toLowerCase(),
            );
      },
    );

    cookbooks = loadedCookbooks;
  }

  Uint8List? getCookbookCover(String cookbookName) {
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

  Future<void> chooseCookbookCover(
    String cookbookName,
  ) async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final Uint8List? imageBytes =
        result.files.first.bytes;

    if (imageBytes == null) return;

    await cookbookCoversBox?.put(
      cookbookName,
      imageBytes,
    );

    if (!mounted) return;

    setState(() {});
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

  Future<int> getFavouriteCount(
    String cookbookName,
  ) async {
    final Box cookbookBox =
        Hive.isBoxOpen(cookbookName)
            ? Hive.box(cookbookName)
            : await Hive.openBox(cookbookName);

    int favouriteCount = 0;

    for (final dynamic value in cookbookBox.values) {
      if (value is Map &&
          value['favourite'] == true) {
        favouriteCount++;
      }
    }

    return favouriteCount;
  }

  Future<int> getTotalRecipeCount() async {
    int total = 0;

    for (final _CookbookEntry cookbook in cookbooks) {
      final Box cookbookBox =
          Hive.isBoxOpen(cookbook.name)
              ? Hive.box(cookbook.name)
              : await Hive.openBox(cookbook.name);

      total += cookbookBox.length;
    }

    return total;
  }

  void showAddCookbookDialog() {
    cookbookNameController.clear();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Cookbook'),
          content: TextField(
            controller: cookbookNameController,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Cookbook name',
              hintText: 'For example: Italian Recipes',
              prefixIcon:
                  Icon(Icons.menu_book_outlined),
            ),
            onSubmitted: (_) {
              saveCookbook(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                saveCookbook(dialogContext);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveCookbook(
    BuildContext dialogContext,
  ) async {
    final String cookbookName =
        cookbookNameController.text.trim();

    if (cookbookName.isEmpty) return;

    final bool alreadyExists =
        cookbookListBox.values.any(
      (dynamic value) =>
          value.toString().trim().toLowerCase() ==
          cookbookName.toLowerCase(),
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"$cookbookName" already exists.',
          ),
        ),
      );

      return;
    }

    await cookbookListBox.add(cookbookName);

    if (!mounted) return;

    setState(loadCookbooks);

    cookbookNameController.clear();

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
  }

  Future<void> openCookbook(
    String cookbookName,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookbookPage(
          cookbookName: cookbookName,
        ),
      ),
    );

    if (!mounted) return;

    setState(loadCookbooks);
  }

  Future<void> openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchPage(),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> openFavourites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FavouritesPage(),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanRecipePage(),
      ),
    );

    if (!mounted) return;

    setState(loadCookbooks);
  }

  Future<void> confirmDeleteCookbook({
    required dynamic cookbookKey,
    required String cookbookName,
  }) async {
    final bool? shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete cookbook?'),
          content: Text(
            'Delete "$cookbookName" and every recipe '
            'inside it? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await deleteCookbook(
      cookbookKey: cookbookKey,
      cookbookName: cookbookName,
    );
  }

  Future<void> deleteCookbook({
    required dynamic cookbookKey,
    required String cookbookName,
  }) async {
    if (Hive.isBoxOpen(cookbookName)) {
      final Box cookbookBox =
          Hive.box(cookbookName);

      await cookbookBox.close();
    }

    if (await Hive.boxExists(cookbookName)) {
      await Hive.deleteBoxFromDisk(cookbookName);
    }

    await cookbookCoversBox?.delete(cookbookName);
    await cookbookListBox.delete(cookbookKey);

    if (!mounted) return;

    setState(loadCookbooks);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$cookbookName deleted',
        ),
      ),
    );
  }

  String getGreeting() {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 18) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  @override
  void dispose() {
    cookbookNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            isLoading ? null : showAddCookbookDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Cookbook'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      0,
                    ),
                    sliver: SliverList(
                      delegate:
                          SliverChildListDelegate(
                        [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      '${getGreeting()}, Sam',
                                      style:
                                          const TextStyle(
                                        fontSize: 29,
                                        fontWeight:
                                            FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'What are you cooking today?',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color:
                                            Color(0xFF706A66),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFE3D5,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    18,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.restaurant_menu,
                                  color: Color(0xFFD96C3F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          InkWell(
                            borderRadius:
                                BorderRadius.circular(18),
                            onTap: openSearch,
                            child: IgnorePointer(
                              child: TextField(
                                decoration:
                                    InputDecoration(
                                  hintText:
                                      'Search recipes or ingredients',
                                  prefixIcon:
                                      const Icon(
                                    Icons.search,
                                  ),
                                  suffixIcon:
                                      const Icon(
                                    Icons.tune,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                    borderSide:
                                        BorderSide.none,
                                  ),
                                  enabledBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                    borderSide:
                                        BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  title: 'Scan Recipe',
                                  subtitle:
                                      'Add from a page',
                                  icon: Icons
                                      .document_scanner_outlined,
                                  backgroundColor:
                                      const Color(
                                    0xFFD96C3F,
                                  ),
                                  foregroundColor:
                                      Colors.white,
                                  onTap: openScanner,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickActionCard(
                                  title: 'Favourites',
                                  subtitle:
                                      'Recipes you love',
                                  icon:
                                      Icons.favorite_outline,
                                  backgroundColor:
                                      const Color(
                                    0xFFFFE8E5,
                                  ),
                                  foregroundColor:
                                      const Color(
                                    0xFFB94747,
                                  ),
                                  onTap: openFavourites,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'My Cookbooks',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              FutureBuilder<int>(
                                future:
                                    getTotalRecipeCount(),
                                builder: (
                                  BuildContext context,
                                  AsyncSnapshot<int>
                                      snapshot,
                                ) {
                                  final int total =
                                      snapshot.data ?? 0;

                                  return Text(
                                    '$total '
                                    '${total == 1 ? 'recipe' : 'recipes'}',
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(0xFF7C7470),
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap a cover to add or change its photo.',
                            style: TextStyle(
                              color: Color(0xFF7C7470),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (cookbooks.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          30,
                          20,
                          30,
                          100,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons
                                  .library_books_outlined,
                              size: 76,
                              color: Color(0xFFAAA19C),
                            ),
                            SizedBox(height: 18),
                            Text(
                              'Your cookbook shelf is empty',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Create your first cookbook, '
                              'then add recipes manually or '
                              'scan them from a page.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    Color(0xFF7C7470),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        110,
                      ),
                      sliver: SliverList.builder(
                        itemCount: cookbooks.length,
                        itemBuilder: (
                          BuildContext context,
                          int index,
                        ) {
                          final _CookbookEntry cookbook =
                              cookbooks[index];

                          final Uint8List? cover =
                              getCookbookCover(
                            cookbook.name,
                          );

                          return Dismissible(
                            key: ValueKey(
                              cookbook.key,
                            ),
                            direction:
                                DismissDirection
                                    .endToStart,
                            confirmDismiss: (_) async {
                              await confirmDeleteCookbook(
                                cookbookKey:
                                    cookbook.key,
                                cookbookName:
                                    cookbook.name,
                              );

                              return false;
                            },
                            background: Container(
                              margin:
                                  const EdgeInsets.only(
                                bottom: 16,
                              ),
                              padding:
                                  const EdgeInsets.only(
                                right: 26,
                              ),
                              alignment:
                                  Alignment.centerRight,
                              decoration: BoxDecoration(
                                color:
                                    Colors.red.shade400,
                                borderRadius:
                                    BorderRadius.circular(
                                  24,
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            child: _CookbookCard(
                              cookbookName:
                                  cookbook.name,
                              cover: cover,
                              recipeCountFuture:
                                  getRecipeCount(
                                cookbook.name,
                              ),
                              favouriteCountFuture:
                                  getFavouriteCount(
                                cookbook.name,
                              ),
                              onOpen: () {
                                openCookbook(
                                  cookbook.name,
                                );
                              },
                              onChangeCover: () {
                                chooseCookbookCover(
                                  cookbook.name,
                                );
                              },
                              onDelete: () {
                                confirmDeleteCookbook(
                                  cookbookKey:
                                      cookbook.key,
                                  cookbookName:
                                      cookbook.name,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _CookbookEntry {
  final dynamic key;
  final String name;

  const _CookbookEntry({
    required this.key,
    required this.name,
  });
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: foregroundColor.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: foregroundColor.withValues(
                    alpha: 0.78,
                  ),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CookbookCard extends StatelessWidget {
  final String cookbookName;
  final Uint8List? cover;
  final Future<int> recipeCountFuture;
  final Future<int> favouriteCountFuture;
  final VoidCallback onOpen;
  final VoidCallback onChangeCover;
  final VoidCallback onDelete;

  const _CookbookCard({
    required this.cookbookName,
    required this.cover,
    required this.recipeCountFuture,
    required this.favouriteCountFuture,
    required this.onOpen,
    required this.onChangeCover,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          height: 155,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onChangeCover,
                child: SizedBox(
                  width: 125,
                  height: 155,
                  child: cover == null
                      ? Container(
                          color: const Color(0xFFFFE3D5),
                          child: const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 38,
                                color: Color(0xFFD96C3F),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add cover',
                                style: TextStyle(
                                  color: Color(0xFFD96C3F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Image.memory(
                          cover!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    8,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        cookbookName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      FutureBuilder<int>(
                        future: recipeCountFuture,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<int> snapshot,
                        ) {
                          final int count =
                              snapshot.data ?? 0;

                          return _BookStat(
                            icon: Icons.restaurant_menu,
                            label:
                                '$count ${count == 1 ? 'recipe' : 'recipes'}',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<int>(
                        future: favouriteCountFuture,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<int> snapshot,
                        ) {
                          final int count =
                              snapshot.data ?? 0;

                          return _BookStat(
                            icon: Icons.favorite_border,
                            label:
                                '$count ${count == 1 ? 'favourite' : 'favourites'}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Cookbook options',
                onSelected: (String value) {
                  if (value == 'cover') {
                    onChangeCover();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (
                  BuildContext context,
                ) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'cover',
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: Icon(
                          Icons.photo_outlined,
                        ),
                        title: Text(
                          'Change cover',
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Delete cookbook',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BookStat({
    required this.icon,
    required this.label,
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
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7C7470),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}