import 'dart:convert';

enum Complexity {
  simple,
  challenging,
  hard,
}

enum Affordability {
  affordable,
  pricey,
  luxurious,
}

class Meal {
  const Meal({
    required this.id,
    required this.docID,
    required this.categories,
    required this.title,
    required this.imageUrl,
    required this.thumbUrl,
    required this.ingredients,
    required this.steps,
    required this.duration,
    required this.complexity,
    required this.affordability,
    required this.isGlutenFree,
    required this.isLactoseFree,
    required this.isVegan,
    required this.isVegetarian,
  });

  final String id;
  final String docID;
  final List<String> categories;
  final String title;
  final String imageUrl;
  final String thumbUrl;
  final List<String> ingredients;
  final List<String> steps;
  final int duration;
  final Complexity complexity;
  final Affordability affordability;
  final bool isGlutenFree;
  final bool isLactoseFree;
  final bool isVegan;
  final bool isVegetarian;

  factory Meal.fromJson(Map<String, dynamic> jsonData) {
    return Meal(
      id: jsonData['id'],
      docID: jsonData['docId'],
      categories: List<String>.from(jsonData['categories']),
      title: jsonData['title'],
      imageUrl: jsonData['imageUrl'],
      thumbUrl: jsonData['thumbUrl'],
      ingredients: List<String>.from(jsonData['ingredients']),
      steps: List<String>.from(jsonData['steps']),
      duration: jsonData['duration'],
      complexity: (jsonData['complexity'] == "challenging")
          ? Complexity.challenging
          : (jsonData['complexity'] == "hard"
              ? Complexity.hard
              : Complexity.simple),
      affordability: (jsonData['affordability'] == "affordable")
          ? Affordability.affordable
          : (jsonData['affordability'] == "luxurious")
              ? Affordability.luxurious
              : Affordability.pricey,
      isGlutenFree: jsonData['isGlutenFree'],
      isLactoseFree: jsonData['isLactoseFree'],
      isVegan: jsonData['isVegan'],
      isVegetarian: jsonData['isVegetarian'],
    );
  }

  static Map<String, dynamic> toMap(Meal meal) => {
        'id': meal.id,
        'categories': meal.categories,
        'title': meal.title,
        'imageUrl': meal.imageUrl,
        'thumbUrl': meal.thumbUrl,
        'ingredients': meal.ingredients,
        'steps': meal.steps,
        'duration': meal.duration,
        'complexity': (meal.complexity == Complexity.challenging)
            ? "challenging"
            : (meal.complexity == Complexity.hard)
                ? "hard"
                : "challenging",
        'affordability': (meal.affordability == Affordability.affordable)
            ? "affordable"
            : (meal.affordability == Affordability.pricey)
                ? "pricey"
                : "luxurious",
        'isGlutenFree': meal.isGlutenFree,
        'isLactoseFree': meal.isLactoseFree,
        'isVegan': meal.isVegan,
        'isVegetarian': meal.isVegetarian,
      };

  static String encode(List<Meal> meals) => json.encode(
        meals.map<Map<String, dynamic>>((music) => Meal.toMap(music)).toList(),
      );

  static List<Meal> decode(String meals) =>
      (json.decode(meals) as List<dynamic>)
          .map<Meal>((item) => Meal.fromJson(item))
          .toList();
}
