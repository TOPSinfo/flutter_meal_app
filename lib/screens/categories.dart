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

    Future.delayed(const Duration(seconds: 0), () {
      context.loaderOverlay.hide();
    });
  }

  void _showProgress() {
    context.loaderOverlay.show();
  }

  @override
  void initState() {
    super.initState();
    _showProgress();
    _getCategoryList();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        actions: [
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              color: Theme.of(context).colorScheme.onBackground,
              onPressed: () {
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
