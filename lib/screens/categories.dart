import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:meal_app/main.dart';
import 'package:meal_app/models/category.dart';
import 'package:meal_app/screens/add_category.dart';
import 'package:meal_app/screens/meals.dart';
import '../widgets/category_grid_item.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Categoryy> categories = [];
  final collection = db.collection('categories').orderBy('title');

  // GET CATEGORIES FROM FIREBASE
  void _getCategoryList() async {
    final List<Categoryy> localCategories = [];
    var querySnapshot = await collection.get();
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data();
      localCategories.add(Categoryy.fromMap(data));
    }

    setState(() {
      categories = localCategories;
    });

    // HIDE LOADER
    Future.delayed(const Duration(seconds: 0), () {
      context.loaderOverlay.hide();
    });
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  // INIT STATE
  @override
  void initState() {
    super.initState();
    _showProgress();
    _getCategoryList();
  }

  // SELECT CATEGORY & REDIRECT TO THE MEAL LIST SCREEN
  void _selectCategory(BuildContext context, Categoryy category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MealScreen(
          category: category,
          categories: categories,
        ),
      ),
    ).then((value) => _getCategoryList());
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        actions: [
          // ONLY VISIBLE IF LOGGED IN USER IS ADMIN
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              color: Theme.of(context).colorScheme.onBackground,
              onPressed: () {
                // REDIRECT TO ADD CATEGORY SCREEN
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            const AddCategoryScreen(), //AddMealScreen(arrCategories: categories),
                      ),
                    )
                    .then((value) => _getCategoryList());
              },
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: categories.isEmpty
          ? const Center(
              child: Text(
                "No Data!",
                style: TextStyle(color: Colors.white),
              ),
            )
          : GridView(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            children: [
              // availableCategories.map((category) => CategoryGridItem(category: category)).toList()
              for (final category in categories)
                CategoryGridItem(
                  category: category,
                  onSelectCategory: () {
                    _selectCategory(context, category);
                  }
                )
            ],
          ),
    );
  }
}
