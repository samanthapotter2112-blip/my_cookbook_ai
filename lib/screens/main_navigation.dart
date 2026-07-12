import 'package:flutter/material.dart';

import 'favourites_page.dart';
import 'home_page.dart';
import 'scan_recipe_page.dart';
import 'search_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  // Changing this value rebuilds pages such as Favourites and Search.
  int refreshNumber = 0;

  Widget get currentPage {
    switch (currentIndex) {
      case 1:
        return FavouritesPage(
          key: ValueKey('favourites-$refreshNumber'),
        );

      case 2:
        return ScanRecipePage(
          key: ValueKey('scan-$refreshNumber'),
        );

      case 3:
        return SearchPage(
          key: ValueKey('search-$refreshNumber'),
        );

      case 0:
      default:
        return HomePage(
          key: ValueKey('home-$refreshNumber'),
        );
    }
  }

  void changePage(int index) {
    setState(() {
      currentIndex = index;
      refreshNumber++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPage,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: changePage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.manage_search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}