import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'cookbook_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController controller = TextEditingController();

  late Box cookbookBox;
  Box? cookbookCoversBox;

  List<dynamic> cookbookKeys = [];
  List<String> cookbooks = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    cookbookBox = Hive.box('cookbooks');
    initialisePage();
  }

  Future<void> initialisePage() async {
    cookbookCoversBox = Hive.isBoxOpen('cookbook_covers')
        ? Hive.box('cookbook_covers')
        : await Hive.openBox('cookbook_covers');

    if (!mounted) return;

    setState(() {
      loadCookbooks();
      isLoading = false;
    });
  }

  void loadCookbooks() {
    cookbookKeys = cookbookBox.keys.toList();

    cookbooks = cookbookBox.values
        .map((value) => value.toString())
        .toList();
  }

  Uint8List? getCookbookCover(String cookbookName) {
    final savedCover = cookbookCoversBox?.get(cookbookName);

    if (savedCover is Uint8List) {
      return savedCover;
    }

    if (savedCover is List<int>) {
      return Uint8List.fromList(savedCover);
    }

    return null;
  }

  Future<void> chooseCookbookCover(String cookbookName) async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final Uint8List? imageBytes = result.files.first.bytes;

    if (imageBytes == null) return;

    await cookbookCoversBox?.put(
      cookbookName,
      imageBytes,
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<int> getRecipeCount(String cookbookName) async {
    final Box recipeBox = Hive.isBoxOpen(cookbookName)
        ? Hive.box(cookbookName)
        : await Hive.openBox(cookbookName);

    return recipeBox.length;
  }

  void showAddCookbookDialog() {
    controller.clear();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Cookbook'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Cookbook name',
            ),
            onSubmitted: (_) {
              saveCookbook(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                saveCookbook(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveCookbook(
    BuildContext dialogContext,
  ) async {
    final String cookbookName = controller.text.trim();

    if (cookbookName.isEmpty) return;

    await cookbookBox.add(cookbookName);

    if (!mounted) return;

    setState(loadCookbooks);

    controller.clear();

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
  }

  Future<void> confirmDeleteCookbook({
    required dynamic cookbookKey,
    required String cookbookName,
  }) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete cookbook?'),
          content: Text(
            'Delete "$cookbookName" and all its recipes?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
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
    Box? recipeBox;

    if (Hive.isBoxOpen(cookbookName)) {
      recipeBox = Hive.box(cookbookName);
    } else if (await Hive.boxExists(cookbookName)) {
      recipeBox = await Hive.openBox(cookbookName);
    }

    final List<String> recipeNames = recipeBox == null
        ? <String>[]
        : recipeBox.values
            .map((value) => value.toString())
            .toList();

    final Box detailsBox = Hive.isBoxOpen('recipe_details')
        ? Hive.box('recipe_details')
        : await Hive.openBox('recipe_details');

    for (final String recipeName in recipeNames) {
      await detailsBox.delete(recipeName);
    }

    if (recipeBox != null && recipeBox.isOpen) {
      await recipeBox.close();
    }

    if (await Hive.boxExists(cookbookName)) {
      await Hive.deleteBoxFromDisk(cookbookName);
    }

    await cookbookCoversBox?.delete(cookbookName);
    await cookbookBox.delete(cookbookKey);

    if (!mounted) return;

    setState(loadCookbooks);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cookbookName deleted'),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('📚 My Cookbook AI'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddCookbookDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Cookbook'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchPage(),
                        ),
                      );
                    },
                    child: IgnorePointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by recipe or ingredient...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Cookbooks',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tap a cover to add or change its photo.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: cookbooks.isEmpty
                        ? const Center(
                            child: Text(
                              'No cookbooks yet.\n'
                              'Tap Add Cookbook to create one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            itemCount: cookbooks.length,
                            itemBuilder: (context, index) {
                              final String cookbookName =
                                  cookbooks[index];

                              final dynamic cookbookKey =
                                  cookbookKeys[index];

                              final Uint8List? cover =
                                  getCookbookCover(
                                cookbookName,
                              );

                              return Dismissible(
                                key: ValueKey(cookbookKey),
                                direction:
                                    DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  await confirmDeleteCookbook(
                                    cookbookKey: cookbookKey,
                                    cookbookName: cookbookName,
                                  );

                                  return false;
                                },
                                background: Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 16,
                                  ),
                                  padding: const EdgeInsets.only(
                                    right: 24,
                                  ),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius:
                                        BorderRadius.circular(22),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  elevation: 4,
                                  margin: const EdgeInsets.only(
                                    bottom: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(22),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          chooseCookbookCover(
                                            cookbookName,
                                          );
                                        },
                                        child: SizedBox(
                                          height: 170,
                                          width: double.infinity,
                                          child: cover == null
                                              ? Container(
                                                  color: Colors
                                                      .orange
                                                      .shade100,
                                                  child:
                                                      const Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .add_a_photo,
                                                        size: 46,
                                                        color: Colors
                                                            .deepOrange,
                                                      ),
                                                      SizedBox(
                                                        height: 8,
                                                      ),
                                                      Text(
                                                        'Add cover photo',
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Image.memory(
                                                  cover,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      ListTile(
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                          18,
                                          10,
                                          8,
                                          10,
                                        ),
                                        title: Text(
                                          cookbookName,
                                          style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        subtitle:
                                            FutureBuilder<int>(
                                          future: getRecipeCount(
                                            cookbookName,
                                          ),
                                          builder:
                                              (context, snapshot) {
                                            final int count =
                                                snapshot.data ?? 0;

                                            return Text(
                                              '$count '
                                              '${count == 1 ? 'recipe' : 'recipes'}',
                                            );
                                          },
                                        ),
                                        trailing: Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip:
                                                  'Change cover',
                                              onPressed: () {
                                                chooseCookbookCover(
                                                  cookbookName,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.photo_camera_outlined,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip:
                                                  'Delete cookbook',
                                              onPressed: () {
                                                confirmDeleteCookbook(
                                                  cookbookKey:
                                                      cookbookKey,
                                                  cookbookName:
                                                      cookbookName,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                            ),
                                          ],
                                        ),
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CookbookPage(
                                                cookbookName:
                                                    cookbookName,
                                              ),
                                            ),
                                          );

                                          if (!mounted) return;

                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 70),
                ],
              ),
            ),
    );
  }
}