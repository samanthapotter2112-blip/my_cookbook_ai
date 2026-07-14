import 'dart:typed_data';

import 'package:flutter/material.dart';

class CookbookCard extends StatelessWidget {
  final String cookbookName;
  final Uint8List? cover;
  final int recipeCount;
  final int favouriteCount;
  final VoidCallback onTap;
  final VoidCallback onChangeCover;
  final VoidCallback onDelete;

  const CookbookCard({
    super.key,
    required this.cookbookName,
    required this.cover,
    required this.recipeCount,
    required this.favouriteCount,
    required this.onTap,
    required this.onChangeCover,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 155,
              child: cover == null
                  ? Container(
                      color: const Color(0xFFFFE3D5),
                      child: const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 42,
                            color: Color(0xFFD96C3F),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add Cover',
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  8,
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      cookbookName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          size: 17,
                          color: Color(0xFF7C7470),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$recipeCount ${recipeCount == 1 ? 'recipe' : 'recipes'}',
                          style: const TextStyle(
                            color: Color(0xFF7C7470),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 17,
                          color: Color(0xFF7C7470),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$favouriteCount ${favouriteCount == 1 ? 'favourite' : 'favourites'}',
                          style: const TextStyle(
                            color: Color(0xFF7C7470),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cover') {
                  onChangeCover();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'cover',
                  child: Text('Change cover'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete cookbook',
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
    );
  }
}