class Recipe {
  String name;
  String ingredients;
  String method;
  String notes;
  String pageNumber;
  bool favourite;

  Recipe({
    required this.name,
    this.ingredients = "",
    this.method = "",
    this.notes = "",
    this.pageNumber = "",
    this.favourite = false,
  });
}