import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../widgets/cookbook_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_title.dart';
import '../widgets/stats_card.dart';
import 'cookbook_page.dart';
import 'favourites_page.dart';
import 'ingredient_finder_page.dart';
import 'meal_planner_page.dart';
import 'scan_recipe_page.dart';
import 'search_page.dart';
import 'shopping_list_page.dart';
import 'collections_page.dart';
import 'random_recipe_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController cookbookNameController = TextEditingController();

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

      loadedCookbooks.add(_CookbookEntry(key: key, name: cookbookName));
    }

    loadedCookbooks.sort((_CookbookEntry first, _CookbookEntry second) {
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    cookbooks = loadedCookbooks;
  }

  Uint8List? getCookbookCover(String cookbookName) {
    final dynamic savedCover = cookbookCoversBox?.get(cookbookName);

    if (savedCover is Uint8List) {
      return savedCover;
    }

    if (savedCover is List<int>) {
      return Uint8List.fromList(savedCover);
    }

    return null;
  }

  Future<void> chooseCookbookCover(String cookbookName) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final Uint8List? imageBytes = result.files.first.bytes;

    if (imageBytes == null) return;

    await cookbookCoversBox?.put(cookbookName, imageBytes);

    if (!mounted) return;

    setState(() {});
  }

  Future<List<int>> loadCookbookCounts(String cookbookName) async {
    final Box cookbookBox = Hive.isBoxOpen(cookbookName)
        ? Hive.box(cookbookName)
        : await Hive.openBox(cookbookName);

    int favouriteCount = 0;

    for (final dynamic value in cookbookBox.values) {
      if (value is Map && value['favourite'] == true) {
        favouriteCount++;
      }
    }

    return <int>[cookbookBox.length, favouriteCount];
  }

  Future<_HomeStats> loadHomeStats() async {
    int recipeCount = 0;
    int favouriteCount = 0;

    for (final _CookbookEntry cookbook in cookbooks) {
      final Box cookbookBox = Hive.isBoxOpen(cookbook.name)
          ? Hive.box(cookbook.name)
          : await Hive.openBox(cookbook.name);

      recipeCount += cookbookBox.length;

      for (final dynamic value in cookbookBox.values) {
        if (value is Map && value['favourite'] == true) {
          favouriteCount++;
        }
      }
    }

    return _HomeStats(recipes: recipeCount, favourites: favouriteCount);
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
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Cookbook name',
              hintText: 'For example: Italian Recipes',
              prefixIcon: Icon(Icons.menu_book_outlined),
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

  Future<void> saveCookbook(BuildContext dialogContext) async {
    final String cookbookName = cookbookNameController.text.trim();

    if (cookbookName.isEmpty) return;

    final bool alreadyExists = cookbookListBox.values.any((dynamic value) {
      return value.toString().trim().toLowerCase() ==
          cookbookName.toLowerCase();
    });

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$cookbookName" already exists.')),
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

  Future<void> openCookbook(String cookbookName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CookbookPage(cookbookName: cookbookName),
      ),
    );

    if (!mounted) return;

    setState(loadCookbooks);
  }

  Future<void> openCollections() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CollectionsPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> openRandomRecipe() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RandomRecipePage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> openFavourites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavouritesPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanRecipePage()),
    );

    if (!mounted) return;

    setState(loadCookbooks);
  }

  Future<void> openIngredientFinder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IngredientFinderPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> openMealPlanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealPlannerPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> openShoppingList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShoppingListPage()),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> confirmDeleteCookbook({
    required dynamic cookbookKey,
    required String cookbookName,
  }) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete cookbook?'),
          content: Text(
            'Delete "$cookbookName" and every '
            'recipe inside it? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await deleteCookbook(cookbookKey: cookbookKey, cookbookName: cookbookName);
  }

  Future<void> deleteCookbook({
    required dynamic cookbookKey,
    required String cookbookName,
  }) async {
    if (Hive.isBoxOpen(cookbookName)) {
      final Box cookbookBox = Hive.box(cookbookName);

      await cookbookBox.close();
    }

    if (await Hive.boxExists(cookbookName)) {
      await Hive.deleteBoxFromDisk(cookbookName);
    }

    await cookbookCoversBox?.delete(cookbookName);

    await cookbookListBox.delete(cookbookKey);

    if (!mounted) return;

    setState(loadCookbooks);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$cookbookName deleted')));
  }

  Widget buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${getGreeting()}, Sam',
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'What are you cooking today?',
                style: TextStyle(fontSize: 17, color: Color(0xFF706A66)),
              ),
            ],
          ),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE3D5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.restaurant_menu, color: Color(0xFFD96C3F)),
        ),
      ],
    );
  }

  Widget buildSearchBar() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: openSearch,
      child: IgnorePointer(
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search recipes or ingredients',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: const Icon(Icons.tune),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'Scan Recipe',
                subtitle: 'Add from a page',
                icon: Icons.document_scanner_outlined,
                backgroundColor: const Color(0xFFD96C3F),
                foregroundColor: Colors.white,
                onTap: openScanner,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                title: 'Favourites',
                subtitle: 'Recipes you love',
                icon: Icons.favorite_outline,
                backgroundColor: const Color(0xFFFFE8E5),
                foregroundColor: const Color(0xFFB94747),
                onTap: openFavourites,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'What Can I Make?',
                subtitle: 'Search ingredients',
                icon: Icons.shopping_basket_outlined,
                backgroundColor: const Color(0xFFE6EFE5),
                foregroundColor: const Color(0xFF56715A),
                onTap: openIngredientFinder,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                title: 'Meal Planner',
                subtitle: 'Plan your week',
                icon: Icons.calendar_month_outlined,
                backgroundColor: const Color(0xFFE9E7F4),
                foregroundColor: const Color(0xFF625F85),
                onTap: openMealPlanner,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'Collections',
                subtitle: 'Group your recipes',
                icon: Icons.collections_bookmark_outlined,
                backgroundColor: const Color(0xFFE8EEF8),
                foregroundColor: const Color(0xFF4F678A),
                onTap: openCollections,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                title: 'Shopping List',
                subtitle: 'From your meal plan',
                icon: Icons.shopping_cart_outlined,
                backgroundColor: const Color(0xFFFFF1DA),
                foregroundColor: const Color(0xFF9A6824),
                onTap: openShoppingList,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: QuickActionCard(
            title: 'Surprise Me',
            subtitle: 'Pick a random recipe',
            icon: Icons.casino_outlined,
            backgroundColor: const Color(0xFFFFE8D9),
            foregroundColor: const Color(0xFFB35B28),
            onTap: openRandomRecipe,
          ),
        ),
      ],
    );
  }

  Widget buildStats(_HomeStats stats) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            icon: Icons.restaurant_menu,
            title: 'Saved recipes',
            value: stats.recipes.toString(),
            color: const Color(0xFFD96C3F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            icon: Icons.favorite,
            title: 'Favourites',
            value: stats.favourites.toString(),
            color: const Color(0xFFB94747),
          ),
        ),
      ],
    );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : showAddCookbookDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Cookbook'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<_HomeStats>(
                future: loadHomeStats(),
                builder:
                    (BuildContext context, AsyncSnapshot<_HomeStats> snapshot) {
                      final _HomeStats stats =
                          snapshot.data ??
                          const _HomeStats(recipes: 0, favourites: 0);

                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  buildHeader(),
                                  const SizedBox(height: 24),
                                  buildSearchBar(),
                                  const SizedBox(height: 20),
                                  buildQuickActions(),
                                  const SizedBox(height: 22),
                                  buildStats(stats),
                                  const SizedBox(height: 28),
                                  SectionTitle(
                                    title: 'My Cookbooks',
                                    subtitle:
                                        '${cookbooks.length} '
                                        '${cookbooks.length == 1 ? 'cookbook' : 'cookbooks'}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (cookbooks.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyCookbookShelf(),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                110,
                              ),
                              sliver: SliverList.builder(
                                itemCount: cookbooks.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final _CookbookEntry cookbook =
                                      cookbooks[index];

                                  return FutureBuilder<List<int>>(
                                    future: loadCookbookCounts(cookbook.name),
                                    builder:
                                        (
                                          BuildContext context,
                                          AsyncSnapshot<List<int>>
                                          countSnapshot,
                                        ) {
                                          final List<int> counts =
                                              countSnapshot.data ?? <int>[0, 0];

                                          return Dismissible(
                                            key: ValueKey(cookbook.key),
                                            direction:
                                                DismissDirection.endToStart,
                                            confirmDismiss: (_) async {
                                              await confirmDeleteCookbook(
                                                cookbookKey: cookbook.key,
                                                cookbookName: cookbook.name,
                                              );

                                              return false;
                                            },
                                            background: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              padding: const EdgeInsets.only(
                                                right: 26,
                                              ),
                                              alignment: Alignment.centerRight,
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade400,
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                            child: CookbookCard(
                                              cookbookName: cookbook.name,
                                              cover: getCookbookCover(
                                                cookbook.name,
                                              ),
                                              recipeCount: counts[0],
                                              favouriteCount: counts[1],
                                              onTap: () {
                                                openCookbook(cookbook.name);
                                              },
                                              onChangeCover: () {
                                                chooseCookbookCover(
                                                  cookbook.name,
                                                );
                                              },
                                              onDelete: () {
                                                confirmDeleteCookbook(
                                                  cookbookKey: cookbook.key,
                                                  cookbookName: cookbook.name,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
              ),
      ),
    );
  }
}

class _CookbookEntry {
  final dynamic key;
  final String name;

  const _CookbookEntry({required this.key, required this.name});
}

class _HomeStats {
  final int recipes;
  final int favourites;

  const _HomeStats({required this.recipes, required this.favourites});
}

class _EmptyCookbookShelf extends StatelessWidget {
  const _EmptyCookbookShelf();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(30, 20, 30, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 76,
            color: Color(0xFFAAA19C),
          ),
          SizedBox(height: 18),
          Text(
            'Your cookbook shelf is empty',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Create your first cookbook, then '
            'add recipes manually or scan them '
            'from a page.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF7C7470)),
          ),
        ],
      ),
    );
  }
}
