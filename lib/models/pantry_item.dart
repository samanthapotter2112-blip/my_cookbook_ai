class PantryItem {
  final String name;
  final String category;
  final bool inStock;

  PantryItem({
    required this.name,
    required this.category,
    this.inStock = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'inStock': inStock,
    };
  }

  factory PantryItem.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    return PantryItem(
      name: map['name'] ?? '',
      category: map['category'] ?? 'Other',
      inStock: map['inStock'] ?? true,
    );
  }
}