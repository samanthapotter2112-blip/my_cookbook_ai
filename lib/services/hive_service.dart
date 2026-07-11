import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static Future<Box> openCookbookBox() async {
    return await Hive.openBox('cookbooks');
  }

  static Future<Box> openRecipeBox(String cookbookName) async {
    return await Hive.openBox(cookbookName);
  }

  static Future<void> addCookbook(String name) async {
    final box = await openCookbookBox();
    await box.add(name);
  }

  static Future<List<String>> getCookbooks() async {
    final box = await openCookbookBox();
    return box.values.cast<String>().toList();
  }

  static Future<void> addRecipe(
    String cookbook,
    String recipe,
  ) async {
    final box = await openRecipeBox(cookbook);
    await box.add(recipe);
  }

  static Future<List<String>> getRecipes(
    String cookbook,
  ) async {
    final box = await openRecipeBox(cookbook);
    return box.values.cast<String>().toList();
  }

  static Future<void> deleteRecipe(
    String cookbook,
    int index,
  ) async {
    final box = await openRecipeBox(cookbook);
    await box.deleteAt(index);
  }
}