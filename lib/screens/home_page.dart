import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'cookbook_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController controller = TextEditingController();

  late Box cookbookBox;
  List<String> cookbooks = [];

  @override
  void initState() {
    super.initState();

    cookbookBox = Hive.box('cookbooks');
    loadCookbooks();
  }

  void loadCookbooks() {
    setState(() {
      cookbooks = cookbookBox.values.cast<String>().toList();
    });
  }

  void addCookbook() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Cookbook"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Cookbook name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();

              if (name.isNotEmpty) {
                cookbookBox.add(name);
                loadCookbooks();
              }

              controller.clear();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),

      appBar: AppBar(
        title: const Text("📚 My Cookbook AI"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: addCookbook,
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search recipes...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt),
                label: const Text("Scan Cookbook"),
              ),
            ),

            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Cookbooks",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: cookbooks.isEmpty
                  ? const Center(
                      child: Text(
                        "No cookbooks yet.\nTap + to create your first cookbook.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: cookbooks.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.menu_book,
                                color: Colors.deepOrange,
                                size: 35,
                              ),
                            ),
                            title: Text(
                              cookbooks[index],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text("Tap to open cookbook"),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CookbookPage(
                                    cookbookName: cookbooks[index],
                                  ),
                                ),
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