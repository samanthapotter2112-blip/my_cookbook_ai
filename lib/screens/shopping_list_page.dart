import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() =>
      _ShoppingListPageState();
}

class _ShoppingListPageState
    extends State<ShoppingListPage> {
  final TextEditingController addItemController =
      TextEditingController();

  Box? mealPlannerBox;
  Box? shoppingListBox;

  List<_ShoppingItem> items = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initialiseShoppingList();
  }

  Future<void> initialiseShoppingList() async {
    mealPlannerBox = Hive.isBoxOpen('meal_planner')
        ? Hive.box('meal_planner')
        : await Hive.openBox('meal_planner');

    shoppingListBox =
        Hive.isBoxOpen('shopping_list')
            ? Hive.box('shopping_list')
            : await Hive.openBox(
                'shopping_list',
              );

    await loadShoppingList();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadShoppingList() async {
    final List<_ShoppingItem> loadedItems = [];

    final Box? plannerBox = mealPlannerBox;
    final Box? listBox = shoppingListBox;

    if (plannerBox == null || listBox == null) {
      items = [];
      return;
    }

    final Set<String> generatedKeys = {};

    for (final dynamic plannerValue
        in plannerBox.values) {
      if (plannerValue is! Map) continue;

      final String recipeName =
          plannerValue['recipeName']
                  ?.toString()
                  .trim() ??
              '';

      final String cookbookName =
          plannerValue['cookbookName']
                  ?.toString()
                  .trim() ??
              '';

      if (recipeName.isEmpty ||
          cookbookName.isEmpty) {
        continue;
      }

      final Box cookbookBox =
          Hive.isBoxOpen(cookbookName)
              ? Hive.box(cookbookName)
              : await Hive.openBox(
                  cookbookName,
                );

      final dynamic savedRecipe =
          cookbookBox.get(recipeName);

      if (savedRecipe is! Map) continue;

      final String ingredients =
          savedRecipe['ingredients']
                  ?.toString()
                  .trim() ??
              '';

      if (ingredients.isEmpty) continue;

      final List<String> ingredientLines =
          ingredients
              .split('\n')
              .map(
                (String line) => line.trim(),
              )
              .where(
                (String line) => line.isNotEmpty,
              )
              .toList();

      for (final String ingredient
          in ingredientLines) {
        final String normalised =
            normaliseItem(ingredient);

        if (normalised.isEmpty ||
            generatedKeys.contains(normalised)) {
          continue;
        }

        generatedKeys.add(normalised);

        loadedItems.add(
          _ShoppingItem(
            id: 'generated-$normalised',
            name: ingredient,
            checked:
                listBox.get(
                      'checked-generated-$normalised',
                      defaultValue: false,
                    ) ==
                    true,
            isCustom: false,
          ),
        );
      }
    }

    for (final dynamic key in listBox.keys) {
      final String keyText = key.toString();

      if (!keyText.startsWith('custom-')) {
        continue;
      }

      final dynamic savedValue =
          listBox.get(key);

      if (savedValue is! Map) continue;

      final String name =
          savedValue['name']
                  ?.toString()
                  .trim() ??
              '';

      if (name.isEmpty) continue;

      loadedItems.add(
        _ShoppingItem(
          id: keyText,
          name: name,
          checked:
              savedValue['checked'] == true,
          isCustom: true,
        ),
      );
    }

    loadedItems.sort(
      (
        _ShoppingItem first,
        _ShoppingItem second,
      ) {
        if (first.checked != second.checked) {
          return first.checked ? 1 : -1;
        }

        return first.name
            .toLowerCase()
            .compareTo(
              second.name.toLowerCase(),
            );
      },
    );

    items = loadedItems;
  }

  String normaliseItem(String value) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^\w\s-]'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  Future<void> toggleItem(
    _ShoppingItem item,
  ) async {
    final Box? box = shoppingListBox;

    if (box == null) return;

    final bool newValue = !item.checked;

    if (item.isCustom) {
      await box.put(
        item.id,
        <String, dynamic>{
          'name': item.name,
          'checked': newValue,
        },
      );
    } else {
      await box.put(
        'checked-${item.id}',
        newValue,
      );
    }

    if (!mounted) return;

    setState(() {
      item.checked = newValue;

      items.sort(
        (
          _ShoppingItem first,
          _ShoppingItem second,
        ) {
          if (first.checked != second.checked) {
            return first.checked ? 1 : -1;
          }

          return first.name
              .toLowerCase()
              .compareTo(
                second.name.toLowerCase(),
              );
        },
      );
    });
  }

  Future<void> addCustomItem() async {
    final String itemName =
        addItemController.text.trim();

    if (itemName.isEmpty) return;

    final Box? box = shoppingListBox;

    if (box == null) return;

    final String itemId =
        'custom-${DateTime.now().microsecondsSinceEpoch}';

    await box.put(
      itemId,
      <String, dynamic>{
        'name': itemName,
        'checked': false,
      },
    );

    addItemController.clear();

    if (!mounted) return;

    await refreshList();
  }

  Future<void> deleteCustomItem(
    _ShoppingItem item,
  ) async {
    if (!item.isCustom) return;

    final Box? box = shoppingListBox;

    if (box == null) return;

    await box.delete(item.id);

    if (!mounted) return;

    await refreshList();
  }

  Future<void> clearCheckedItems() async {
    final Box? box = shoppingListBox;

    if (box == null) return;

    for (final _ShoppingItem item
        in items.where(
      (_ShoppingItem item) => item.checked,
    )) {
      if (item.isCustom) {
        await box.delete(item.id);
      } else {
        await box.delete(
          'checked-${item.id}',
        );
      }
    }

    if (!mounted) return;

    await refreshList();
  }

  Future<void> resetChecks() async {
    final Box? box = shoppingListBox;

    if (box == null) return;

    for (final dynamic key
        in box.keys.toList()) {
      final String keyText = key.toString();

      if (keyText.startsWith(
        'checked-generated-',
      )) {
        await box.delete(key);
      }

      if (keyText.startsWith('custom-')) {
        final dynamic value = box.get(key);

        if (value is Map) {
          final Map<String, dynamic>
              updated =
              Map<String, dynamic>.from(
            value,
          );

          updated['checked'] = false;

          await box.put(
            key,
            updated,
          );
        }
      }
    }

    if (!mounted) return;

    await refreshList();
  }

  Future<void> refreshList() async {
    await loadShoppingList();

    if (!mounted) return;

    setState(() {});
  }

  int get checkedCount {
    return items
        .where(
          (_ShoppingItem item) =>
              item.checked,
        )
        .length;
  }

  int get remainingCount {
    return items.length - checkedCount;
  }

  @override
  void dispose() {
    addItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text(
          'Shopping List',
        ),
        actions: [
          if (checkedCount > 0)
            IconButton(
              tooltip: 'Clear checked items',
              onPressed: clearCheckedItems,
              icon: const Icon(
                Icons
                    .delete_sweep_outlined,
              ),
            ),
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Shopping list options',
              onSelected: (
                String value,
              ) {
                if (value == 'reset') {
                  resetChecks();
                }

                if (value == 'refresh') {
                  refreshList();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading:
                        Icon(Icons.refresh),
                    title: Text(
                      'Refresh from meal plan',
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'reset',
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading: Icon(
                      Icons
                          .restart_alt_outlined,
                    ),
                    title: Text(
                      'Untick all items',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: refreshList,
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  30,
                ),
                children: [
                  _ShoppingListHeader(
                    totalCount: items.length,
                    remainingCount:
                        remainingCount,
                  ),
                  const SizedBox(height: 16),
                  _AddShoppingItemCard(
                    controller:
                        addItemController,
                    onAdd: addCustomItem,
                  ),
                  const SizedBox(height: 20),
                  if (items.isEmpty)
                    const _EmptyShoppingList()
                  else ...[
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final _ShoppingItem
                        item in items)
                      _ShoppingItemCard(
                        item: item,
                        onToggle: () {
                          toggleItem(item);
                        },
                        onDelete: item.isCustom
                            ? () {
                                deleteCustomItem(
                                  item,
                                );
                              }
                            : null,
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ShoppingItem {
  final String id;
  final String name;
  final bool isCustom;

  bool checked;

  _ShoppingItem({
    required this.id,
    required this.name,
    required this.checked,
    required this.isCustom,
  });
}

class _ShoppingListHeader
    extends StatelessWidget {
  final int totalCount;
  final int remainingCount;

  const _ShoppingListHeader({
    required this.totalCount,
    required this.remainingCount,
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
                  0xFFE6EFE5,
                ),
                borderRadius:
                    BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFF56715A),
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
                    'Your shopping list',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalCount == 0
                        ? 'No items yet'
                        : '$remainingCount of $totalCount items remaining',
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

class _AddShoppingItemCard
    extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddShoppingItemCard({
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Add another item',
                  prefixIcon:
                      Icon(Icons.add),
                ),
                onSubmitted: (_) {
                  onAdd();
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onAdd,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingItemCard
    extends StatelessWidget {
  final _ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _ShoppingItemCard({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin:
          const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onToggle,
        leading: Checkbox(
          value: item.checked,
          onChanged: (_) {
            onToggle();
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.checked
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.checked
                ? const Color(0xFF8C8581)
                : null,
          ),
        ),
        subtitle: item.isCustom
            ? const Text('Added manually')
            : const Text(
                'From your meal plan',
              ),
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: 'Delete item',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
      ),
    );
  }
}

class _EmptyShoppingList
    extends StatelessWidget {
  const _EmptyShoppingList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            Icons
                .shopping_cart_checkout_outlined,
            size: 72,
            color: Color(0xFFAAA19C),
          ),
          SizedBox(height: 18),
          Text(
            'Your list is empty',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Add recipes to the Meal Planner, '
            'then refresh this page to collect '
            'their ingredients automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7C7470),
            ),
          ),
        ],
      ),
    );
  }
}