import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  late Box pantryBox;

  final TextEditingController searchController =
      TextEditingController();

  final TextEditingController addController =
      TextEditingController();

  List<String> ingredients = [];

  @override
  void initState() {
    super.initState();

    pantryBox = Hive.box('pantry');

    loadIngredients();
  }

  void loadIngredients() {
    ingredients = pantryBox.keys
        .map((e) => e.toString())
        .toList();

    ingredients.sort();

    setState(() {});
  }

  Future<void> addIngredient() async {
    final ingredient =
        addController.text.trim();

    if (ingredient.isEmpty) return;

    await pantryBox.put(
      ingredient,
      true,
    );

    addController.clear();

    loadIngredients();
  }

  Future<void> toggleIngredient(
      String ingredient) async {
    final current =
        pantryBox.get(ingredient) ?? false;

    await pantryBox.put(
      ingredient,
      !current,
    );

    loadIngredients();
  }

  Future<void> deleteIngredient(
      String ingredient) async {
    await pantryBox.delete(ingredient);

    loadIngredients();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ingredients
        .where(
          (e) => e
              .toLowerCase()
              .contains(
                searchController.text
                    .toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Pantry",
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title:
                    const Text("Add Ingredient"),
                content: TextField(
                  controller: addController,
                  autofocus: true,
                ),
                actions: [
                  FilledButton(
                    onPressed: () async {
                        await addIngredient();

                        if (!context.mounted) return;

                        Navigator.pop(context);
                    },
                    child: const Text("Add"),
                  )
                ],
              );
            },
          );
        },
        icon: const Icon(Icons.add),
        label:
            const Text("Ingredient"),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller:
                  searchController,
              decoration:
                  const InputDecoration(
                prefixIcon:
                    Icon(Icons.search),
                hintText:
                    "Search pantry",
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount:
                    filtered.length,
                itemBuilder:
                    (context, index) {
                  final ingredient =
                      filtered[index];

                  final inStock =
                      pantryBox.get(
                              ingredient) ??
                          false;

                  return Card(
                    child: CheckboxListTile(
                      value: inStock,
                      title:
                          Text(ingredient),
                      secondary:
                          IconButton(
                        icon:
                            const Icon(
                          Icons.delete,
                        ),
                        onPressed: () {
                          deleteIngredient(
                              ingredient);
                        },
                      ),
                      onChanged: (_) {
                        toggleIngredient(
                            ingredient);
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