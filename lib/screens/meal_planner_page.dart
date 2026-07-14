import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'recipe_page.dart';

class MealPlannerPage extends StatefulWidget {
  const MealPlannerPage({super.key});

  @override
  State<MealPlannerPage> createState() =>
      _MealPlannerPageState();
}

class _MealPlannerPageState
    extends State<MealPlannerPage> {
  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Box? mealPlannerBox;

  List<Map<String, dynamic>> allRecipes = [];

  final Map<String, Map<String, dynamic>?>
      selectedRecipes = {
    for (final String day in days) day: null,
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    initialisePlanner();
  }

  Future<void> initialisePlanner() async {
    mealPlannerBox =
        Hive.isBoxOpen('meal_planner')
            ? Hive.box('meal_planner')
            : await Hive.openBox(
                'meal_planner',
              );

    await loadRecipes();
    loadSavedPlan();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadRecipes() async {
    final Box cookbookListBox =
        Hive.isBoxOpen('cookbooks')
            ? Hive.box('cookbooks')
            : await Hive.openBox(
                'cookbooks',
              );

    final List<Map<String, dynamic>>
        loadedRecipes = [];

    for (final dynamic cookbookValue
        in cookbookListBox.values) {
      final String cookbookName =
          cookbookValue.toString().trim();

      if (cookbookName.isEmpty) {
        continue;
      }

      final Box cookbookBox =
          Hive.isBoxOpen(cookbookName)
              ? Hive.box(cookbookName)
              : await Hive.openBox(
                  cookbookName,
                );

      for (final dynamic recipeKey
          in cookbookBox.keys) {
        final dynamic savedRecipe =
            cookbookBox.get(recipeKey);

        if (savedRecipe is! Map) {
          continue;
        }

        final Map<String, dynamic> recipe =
            Map<String, dynamic>.from(
          savedRecipe,
        );

        recipe['name'] =
            recipe['name']?.toString() ??
                recipeKey.toString();

        recipe['cookbookName'] =
            cookbookName;

        loadedRecipes.add(recipe);
      }
    }

    loadedRecipes.sort(
      (
        Map<String, dynamic> first,
        Map<String, dynamic> second,
      ) {
        final String firstName =
            first['name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final String secondName =
            second['name']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return firstName.compareTo(
          secondName,
        );
      },
    );

    allRecipes = loadedRecipes;
  }

  void loadSavedPlan() {
    final Box? box = mealPlannerBox;

    if (box == null) return;

    for (final String day in days) {
      final dynamic savedEntry =
          box.get(day);

      if (savedEntry is! Map) {
        selectedRecipes[day] = null;
        continue;
      }

      final String recipeName =
          savedEntry['recipeName']
                  ?.toString() ??
              '';

      final String cookbookName =
          savedEntry['cookbookName']
                  ?.toString() ??
              '';

      Map<String, dynamic>? matchingRecipe;

      for (final Map<String, dynamic>
          recipe in allRecipes) {
        final String savedRecipeName =
            recipe['name']?.toString() ??
                '';

        final String savedCookbookName =
            recipe['cookbookName']
                    ?.toString() ??
                '';

        if (savedRecipeName ==
                recipeName &&
            savedCookbookName ==
                cookbookName) {
          matchingRecipe = recipe;
          break;
        }
      }

      selectedRecipes[day] =
          matchingRecipe;
    }
  }

  Future<void> chooseRecipe(
    String day,
  ) async {
    if (allRecipes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Add some recipes before creating a meal plan.',
          ),
        ),
      );

      return;
    }

    final Map<String, dynamic>? recipe =
        await showModalBottomSheet<
            Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          const Color(0xFFF8F5F2),
      builder: (
        BuildContext bottomSheetContext,
      ) {
        return _RecipePickerSheet(
          day: day,
          recipes: allRecipes,
        );
      },
    );

    if (recipe == null) return;

    await saveDay(
      day: day,
      recipe: recipe,
    );
  }

  Future<void> saveDay({
    required String day,
    required Map<String, dynamic> recipe,
  }) async {
    final Box? box = mealPlannerBox;

    if (box == null) return;

    final String recipeName =
        recipe['name']?.toString() ??
            '';

    final String cookbookName =
        recipe['cookbookName']
                ?.toString() ??
            '';

    if (recipeName.isEmpty ||
        cookbookName.isEmpty) {
      return;
    }

    await box.put(
      day,
      <String, dynamic>{
        'recipeName': recipeName,
        'cookbookName': cookbookName,
      },
    );

    if (!mounted) return;

    setState(() {
      selectedRecipes[day] = recipe;
    });
  }

  Future<void> clearDay(
    String day,
  ) async {
    final Box? box = mealPlannerBox;

    if (box == null) return;

    await box.delete(day);

    if (!mounted) return;

    setState(() {
      selectedRecipes[day] = null;
    });
  }

  Future<void> clearWeek() async {
    final bool? shouldClear =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Clear meal plan?',
          ),
          content: const Text(
            'Remove every recipe from this week?',
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
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Clear week',
              ),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    final Box? box = mealPlannerBox;

    if (box == null) return;

    await box.clear();

    if (!mounted) return;

    setState(() {
      for (final String day in days) {
        selectedRecipes[day] = null;
      }
    });
  }

  Future<void> openRecipe(
    Map<String, dynamic> recipe,
  ) async {
    final String recipeName =
        recipe['name']?.toString() ??
            '';

    final String cookbookName =
        recipe['cookbookName']
                ?.toString() ??
            '';

    if (recipeName.isEmpty ||
        cookbookName.isEmpty) {
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipePage(
          cookbookName: cookbookName,
          recipeName: recipeName,
        ),
      ),
    );

    if (!mounted) return;

    await loadRecipes();
    loadSavedPlan();

    setState(() {});
  }

  Uint8List? getRecipePhoto(
    Map<String, dynamic> recipe,
  ) {
    final dynamic photo =
        recipe['photo'];

    if (photo is Uint8List) {
      return photo;
    }

    if (photo is List<int>) {
      return Uint8List.fromList(
        photo,
      );
    }

    return null;
  }

  int get plannedMealCount {
    return selectedRecipes.values
        .where(
          (
            Map<String, dynamic>?
                recipe,
          ) =>
              recipe != null,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text(
          'Meal Planner',
        ),
        actions: [
          if (plannedMealCount > 0)
            IconButton(
              tooltip: 'Clear week',
              onPressed: clearWeek,
              icon: const Icon(
                Icons.delete_sweep_outlined,
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                30,
              ),
              children: [
                _PlannerHeader(
                  plannedMealCount:
                      plannedMealCount,
                ),
                const SizedBox(height: 20),
                for (final String day in days)
                  _MealDayCard(
                    day: day,
                    recipe:
                        selectedRecipes[day],
                    photo:
                        selectedRecipes[day] ==
                                null
                            ? null
                            : getRecipePhoto(
                                selectedRecipes[
                                    day]!,
                              ),
                    onChoose: () {
                      chooseRecipe(day);
                    },
                    onOpen:
                        selectedRecipes[day] ==
                                null
                            ? null
                            : () {
                                openRecipe(
                                  selectedRecipes[
                                      day]!,
                                );
                              },
                    onClear:
                        selectedRecipes[day] ==
                                null
                            ? null
                            : () {
                                clearDay(day);
                              },
                  ),
              ],
            ),
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  final int plannedMealCount;

  const _PlannerHeader({
    required this.plannedMealCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFE9E7F4,
                ),
                borderRadius:
                    BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF625F85),
                size: 29,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan your week',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$plannedMealCount of 7 days planned',
                    style: const TextStyle(
                      color:
                          Color(0xFF7C7470),
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealDayCard extends StatelessWidget {
  final String day;
  final Map<String, dynamic>? recipe;
  final Uint8List? photo;
  final VoidCallback onChoose;
  final VoidCallback? onOpen;
  final VoidCallback? onClear;

  const _MealDayCard({
    required this.day,
    required this.recipe,
    required this.photo,
    required this.onChoose,
    required this.onOpen,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final String recipeName =
        recipe?['name']?.toString() ??
            '';

    final String cookbookName =
        recipe?['cookbookName']
                ?.toString() ??
            '';

    return Card(
      elevation: 1,
      margin:
          const EdgeInsets.only(bottom: 13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            recipe == null ? onChoose : onOpen,
        child: Padding(
          padding:
              const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(15),
                  child: recipe == null
                      ? Container(
                          color:
                              const Color(
                            0xFFFFE3D5,
                          ),
                          child:
                              const Icon(
                            Icons.add,
                            color: Color(
                              0xFFD96C3F,
                            ),
                            size: 32,
                          ),
                        )
                      : photo == null
                          ? Container(
                              color:
                                  const Color(
                                0xFFFFE3D5,
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .restaurant_menu,
                                color: Color(
                                  0xFFD96C3F,
                                ),
                                size: 31,
                              ),
                            )
                          : Image.memory(
                              photo!,
                              fit: BoxFit.cover,
                            ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF7C7470),
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recipe == null
                          ? 'Choose a recipe'
                          : recipeName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    if (cookbookName
                        .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        cookbookName,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: Color(
                            0xFF7C7470,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (recipe == null)
                const Icon(
                  Icons.chevron_right,
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'Meal options',
                  onSelected: (
                    String value,
                  ) {
                    if (value == 'change') {
                      onChoose();
                    }

                    if (value == 'remove') {
                      onClear?.call();
                    }
                  },
                  itemBuilder: (_) =>
                      const [
                    PopupMenuItem<String>(
                      value: 'change',
                      child: Text(
                        'Change recipe',
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Text(
                        'Remove from day',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipePickerSheet
    extends StatefulWidget {
  final String day;
  final List<Map<String, dynamic>>
      recipes;

  const _RecipePickerSheet({
    required this.day,
    required this.recipes,
  });

  @override
  State<_RecipePickerSheet> createState() =>
      _RecipePickerSheetState();
}

class _RecipePickerSheetState
    extends State<_RecipePickerSheet> {
  final TextEditingController
      searchController =
      TextEditingController();

  late List<Map<String, dynamic>>
      filteredRecipes;

  @override
  void initState() {
    super.initState();

    filteredRecipes =
        List<Map<String, dynamic>>.from(
      widget.recipes,
    );
  }

  void searchRecipes(
    String query,
  ) {
    final String normalisedQuery =
        query.trim().toLowerCase();

    setState(() {
      if (normalisedQuery.isEmpty) {
        filteredRecipes =
            List<Map<String, dynamic>>.from(
          widget.recipes,
        );

        return;
      }

      filteredRecipes =
          widget.recipes.where(
        (Map<String, dynamic> recipe) {
          final String searchableText = [
            recipe['name'],
            recipe['cookbookName'],
            recipe['tags'],
          ]
              .whereType<Object>()
              .join(' ')
              .toLowerCase();

          return searchableText.contains(
            normalisedQuery,
          );
        },
      ).toList();
    });
  }

  Uint8List? getPhoto(
    Map<String, dynamic> recipe,
  ) {
    final dynamic photo =
        recipe['photo'];

    if (photo is Uint8List) {
      return photo;
    }

    if (photo is List<int>) {
      return Uint8List.fromList(
        photo,
      );
    }

    return null;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (
        BuildContext context,
        ScrollController scrollController,
      ) {
        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                12,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Choose for ${widget.day}',
                          style:
                              const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${filteredRecipes.length} recipes available',
                          style:
                              const TextStyle(
                            color: Color(
                              0xFF7C7470,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                12,
              ),
              child: TextField(
                controller:
                    searchController,
                onChanged: searchRecipes,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Search recipes or tags',
                  prefixIcon:
                      Icon(Icons.search),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredRecipes.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching recipes.',
                      ),
                    )
                  : ListView.builder(
                      controller:
                          scrollController,
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      itemCount:
                          filteredRecipes
                              .length,
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        final Map<String,
                                dynamic>
                            recipe =
                            filteredRecipes[
                                index];

                        final Uint8List? photo =
                            getPhoto(recipe);

                        final String name =
                            recipe['name']
                                    ?.toString() ??
                                'Unnamed recipe';

                        final String
                            cookbookName =
                            recipe['cookbookName']
                                    ?.toString() ??
                                '';

                        return Card(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 11,
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets
                                    .all(
                              10,
                            ),
                            leading: ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              child: SizedBox(
                                width: 58,
                                height: 58,
                                child: photo ==
                                        null
                                    ? Container(
                                        color:
                                            const Color(
                                          0xFFFFE3D5,
                                        ),
                                        child:
                                            const Icon(
                                          Icons
                                              .restaurant_menu,
                                          color:
                                              Color(
                                            0xFFD96C3F,
                                          ),
                                        ),
                                      )
                                    : Image.memory(
                                        photo,
                                        fit:
                                            BoxFit.cover,
                                      ),
                              ),
                            ),
                            title: Text(
                              name,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              cookbookName,
                            ),
                            trailing:
                                const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () {
                              Navigator.pop(
                                context,
                                recipe,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}