class MealCategory {
  const MealCategory({
    required this.id,
    required this.title,
    required this.color,
  });

  final String id;
  final String title;
  final String color;

  factory MealCategory.fromMap(Map<String, dynamic> data) {
    return MealCategory(
        id: data['id'], title: data['title'], color: data['color']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color,
    };
  }
}
