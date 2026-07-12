import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('cookbooks');
  final cookbookBox = Hive.box('cookbooks');

  debugPrint(
    'Cookbooks stored: ${cookbookBox.values.toList()}',
  );

  runApp(const MyCookbookApp());
}

class MyCookbookApp extends StatelessWidget {
  const MyCookbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Cookbook AI',
      theme: ThemeData(
        useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFD96C3F),
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F5F2),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF8F5F2),
    foregroundColor: Colors.black87,
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
),
home: const MainNavigation(),
    );
  }
}