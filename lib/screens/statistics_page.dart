import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool isLoading = true;

  int cookbookCount = 0;
  int recipeCount = 0;
  int favouriteCount = 0;
  int recipesWithPhotos = 0;

  String mostUsedCookbook = 'None';

  List<_CookbookStatistic> cookbookStatistics = [];

  @override
  void initState() {
    super.initState();

    loadStatistics();
  }

  Future<void> loadStatistics() async {
    final Box cookbookListBox = Hive.isBoxOpen('cookbooks')
        ? Hive.box('cookbooks')
        : await Hive.openBox('cookbooks');

    final List<_CookbookStatistic> loadedStatistics = [];

    int loadedRecipeCount = 0;
    int loadedFavouriteCount = 0;
    int loadedRecipesWithPhotos = 0;

    for (final dynamic cookbookValue in cookbookListBox.values) {
      final String cookbookName = cookbookValue.toString().trim();

      if (cookbookName.isEmpty) {
        continue;
      }

      final Box cookbookBox = Hive.isBoxOpen(cookbookName)
          ? Hive.box(cookbookName)
          : await Hive.openBox(cookbookName);

      int cookbookFavouriteCount = 0;
      int cookbookPhotoCount = 0;

      for (final dynamic recipeValue in cookbookBox.values) {
        if (recipeValue is! Map) {
          continue;
        }

        if (recipeValue['favourite'] == true) {
          cookbookFavouriteCount++;
          loadedFavouriteCount++;
        }

        final dynamic photo = recipeValue['photo'];

        if (photo != null) {
          cookbookPhotoCount++;
          loadedRecipesWithPhotos++;
        }
      }

      final int cookbookRecipeCount = cookbookBox.length;

      loadedRecipeCount += cookbookRecipeCount;

      loadedStatistics.add(
        _CookbookStatistic(
          name: cookbookName,
          recipeCount: cookbookRecipeCount,
          favouriteCount: cookbookFavouriteCount,
          photoCount: cookbookPhotoCount,
        ),
      );
    }

    loadedStatistics.sort((
      _CookbookStatistic first,
      _CookbookStatistic second,
    ) {
      final int recipeComparison = second.recipeCount.compareTo(
        first.recipeCount,
      );

      if (recipeComparison != 0) {
        return recipeComparison;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    if (!mounted) return;

    setState(() {
      cookbookCount = loadedStatistics.length;
      recipeCount = loadedRecipeCount;
      favouriteCount = loadedFavouriteCount;
      recipesWithPhotos = loadedRecipesWithPhotos;
      cookbookStatistics = loadedStatistics;

      mostUsedCookbook = loadedStatistics.isEmpty
          ? 'None'
          : loadedStatistics.first.name;

      isLoading = false;
    });
  }

  double get favouritePercentage {
    if (recipeCount == 0) {
      return 0;
    }

    return favouriteCount / recipeCount;
  }

  double get photoPercentage {
    if (recipeCount == 0) {
      return 0;
    }

    return recipesWithPhotos / recipeCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Cookbook Statistics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                isLoading = true;
              });

              loadStatistics();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadStatistics,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                children: [
                  const _StatisticsHeader(),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StatisticCard(
                        title: 'Cookbooks',
                        value: cookbookCount.toString(),
                        icon: Icons.menu_book_outlined,
                        backgroundColor: const Color(0xFFFFE3D5),
                        foregroundColor: const Color(0xFFD96C3F),
                      ),
                      _StatisticCard(
                        title: 'Recipes',
                        value: recipeCount.toString(),
                        icon: Icons.restaurant_menu,
                        backgroundColor: const Color(0xFFE8EEF8),
                        foregroundColor: const Color(0xFF4F678A),
                      ),
                      _StatisticCard(
                        title: 'Favourites',
                        value: favouriteCount.toString(),
                        icon: Icons.favorite,
                        backgroundColor: const Color(0xFFFFE8E5),
                        foregroundColor: const Color(0xFFB94747),
                      ),
                      _StatisticCard(
                        title: 'With photos',
                        value: recipesWithPhotos.toString(),
                        icon: Icons.photo_camera_outlined,
                        backgroundColor: const Color(0xFFE6EFE5),
                        foregroundColor: const Color(0xFF56715A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _HighlightCard(
                    title: 'Most-used cookbook',
                    value: mostUsedCookbook,
                    icon: Icons.emoji_events_outlined,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Your collection',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _ProgressCard(
                    title: 'Favourite recipes',
                    subtitle: '$favouriteCount of $recipeCount recipes',
                    value: favouritePercentage,
                    icon: Icons.favorite_outline,
                  ),
                  const SizedBox(height: 12),
                  _ProgressCard(
                    title: 'Recipes with photos',
                    subtitle: '$recipesWithPhotos of $recipeCount recipes',
                    value: photoPercentage,
                    icon: Icons.image_outlined,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recipes by cookbook',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '$cookbookCount total',
                        style: const TextStyle(color: Color(0xFF7C7470)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (cookbookStatistics.isEmpty)
                    const _EmptyStatisticsState()
                  else
                    for (final _CookbookStatistic statistic
                        in cookbookStatistics)
                      _CookbookStatisticCard(
                        statistic: statistic,
                        maximumRecipeCount:
                            cookbookStatistics.first.recipeCount,
                      ),
                ],
              ),
            ),
    );
  }
}

class _StatisticsHeader extends StatelessWidget {
  const _StatisticsHeader();

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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E7F4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.insert_chart_outlined,
                color: Color(0xFF625F85),
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your cooking library',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'See how your recipe collection is growing.',
                    style: TextStyle(color: Color(0xFF7C7470), height: 1.4),
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

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: foregroundColor),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF7C7470),
                    fontWeight: FontWeight.w600,
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

class _HighlightCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _HighlightCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF9A6824)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF7C7470))),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
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

class _ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final IconData icon;

  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final int percentage = (value * 100).round();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFD96C3F)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Color(0xFF7C7470)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD96C3F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 9,
                backgroundColor: const Color(0xFFE9E3DF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CookbookStatisticCard extends StatelessWidget {
  final _CookbookStatistic statistic;
  final int maximumRecipeCount;

  const _CookbookStatisticCard({
    required this.statistic,
    required this.maximumRecipeCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = maximumRecipeCount == 0
        ? 0
        : statistic.recipeCount / maximumRecipeCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    statistic.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${statistic.recipeCount} '
                  '${statistic.recipeCount == 1 ? 'recipe' : 'recipes'}',
                  style: const TextStyle(
                    color: Color(0xFFD96C3F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE9E3DF),
              ),
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _SmallStatistic(
                  icon: Icons.favorite_outline,
                  value: '${statistic.favouriteCount} favourites',
                ),
                _SmallStatistic(
                  icon: Icons.image_outlined,
                  value: '${statistic.photoCount} photos',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatistic extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SmallStatistic({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF7C7470)),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(color: Color(0xFF7C7470))),
      ],
    );
  }
}

class _EmptyStatisticsState extends StatelessWidget {
  const _EmptyStatisticsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 35, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.insert_chart_outlined, size: 70, color: Color(0xFFAAA19C)),
          SizedBox(height: 16),
          Text(
            'No statistics yet',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Add a cookbook and some recipes to start building your statistics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7C7470), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CookbookStatistic {
  final String name;
  final int recipeCount;
  final int favouriteCount;
  final int photoCount;

  const _CookbookStatistic({
    required this.name,
    required this.recipeCount,
    required this.favouriteCount,
    required this.photoCount,
  });
}
