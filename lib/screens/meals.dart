import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:meal_app/main.dart';
import 'package:meal_app/models/category.dart';
import '../models/meal.dart';
import '../widgets/meal_item.dart';
import 'meal_details.dart';

enum Filter {
  glutenFree,
  lactoseFree,
  vegetarian,
  vegan,
}

class MealScreen extends StatefulWidget {
  const MealScreen({
    super.key,
    this.category,
    required this.categories,
  });

  final Categoryy? category;
  final List<Categoryy> categories;

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  List<Meal> meals = [];
  List<String> filters = [];

  void _getMealList(Query<Map<String, dynamic>> collection) async {
    // **** ONE TIME DATA GET ****
    final List<Meal> localMeals = [];
    var querySnapshot = await collection.get();
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data();

      Complexity complexity = data['complexity'] == "simple"
          ? Complexity.simple
          : data['complexity'] == "challenging"
              ? Complexity.challenging
              : Complexity.hard;
      Affordability affordability = data['affordability'] == "affordable"
          ? Affordability.affordable
          : data['affordability'] == "pricey"
              ? Affordability.pricey
              : Affordability.luxurious;

      localMeals.add(
        Meal(
          id: data['id'],
          docID: data['docId'],
          categories: List<String>.from(data['categories']),
          title: data['title'],
          imageUrl: data['imageUrl'],
          thumbUrl: data['thumbUrl'],
          ingredients: List<String>.from(data['ingredients']),
          steps: List<String>.from(data['steps']),
          duration: data['duration'],
          complexity: complexity,
          affordability: affordability,
          isGlutenFree: data['isGlutenFree'],
          isLactoseFree: data['isLactoseFree'],
          isVegan: data['isVegan'],
          isVegetarian: data['isVegetarian'],
        ),
      );
    }

    _filterMealList(localMeals);
  }

  void _filterMealList(List<Meal> localMeals) {
    bool isGlutonFree = filters.contains(Filter.glutenFree.name) ? true : false;
    bool isLactoseFree =
        filters.contains(Filter.lactoseFree.name) ? true : false;
    bool isVegetarian = filters.contains(Filter.vegetarian.name) ? true : false;
    bool isVegan = filters.contains(Filter.vegan.name) ? true : false;

    List<Meal> finalData = [];

    var filteredMeals = localMeals
        .where((meal) => meal.categories.contains(widget.category?.id))
        .toList();
    finalData = filteredMeals.where((meal) {
      if (isGlutonFree && !meal.isGlutenFree) {
        return false;
      }
      if (isLactoseFree && !meal.isLactoseFree) {
        return false;
      }
      if (isVegetarian && !meal.isVegetarian) {
        return false;
      }
      if (isVegan && !meal.isVegan) {
        return false;
      }
      return true;
    }).toList();

    finalData.sort((a, b) => a.title.toString().compareTo(b.title.toString()));
    setState(() {
      SVProgressHUD.dismiss();
      meals = finalData;
    });
  }

  void _showProgress() {
    SVProgressHUD.show();
  }

  @override
  void initState() {
    super.initState();
    _showProgress();

    final collection = db
        .collection('meals')
        .where('categories', arrayContains: widget.category?.id);
    _getMealList(collection);
  }

  void _selectMeal(BuildContext context, Meal meal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MealDetailsScreen(
          meal: meal,
          categories: widget.categories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Uh oh ... nothing here!',
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Try selecting a different category!',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ),
        ],
      ),
    );

    if (meals.isNotEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.builder(
          itemCount: meals.length,
          itemBuilder: (ctx, index) => MealItem(
            meal: meals[index],
            onSelectMeal: (meal) {
              _selectMeal(context, meal);
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category?.title ?? "Meals"),
      ),
      body: content,
    );
  }
}
