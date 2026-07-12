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
  late Box cookbookBox;

  List<String> cookbooks = [];

  @override
  void initState() {
    super.initState();

    cookbookBox = Hive.box('cookbooks');

    cookbooks = cookbookBox.values
        .map((e) => e.toString())
        .toList();

    cookbooks.sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Cookbook'),
      ),
      body: cookbooks.isEmpty
          ? const Center(
              child: Text(
                'Create a cookbook first.',
              ),
            )
          : ListView.builder(
              itemCount: cookbooks.length,
              itemBuilder: (context, index) {
                final cookbook = cookbooks[index];

                return ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(cookbook),
                  trailing:
                      const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(
                      context,
                      cookbook,
                    );
                  },
                );
              },
            ),
    );
  }
}