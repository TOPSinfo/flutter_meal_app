import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../helper/constant.dart';
import '../../models/category.dart';
import '../../widgets/category_grid_item.dart';
import 'add_category.dart';
import '../Meal/meals.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<MealCategory> categories = [];
  final collection = db.collection('categories').orderBy('title');

  /// Fetches the list of meal categories from the Firestore collection and updates the state.
  ///
  /// This method retrieves the documents from the Firestore collection, converts them into
  /// `MealCategory` objects, and updates the `categories` state with the fetched data. It also
  /// ensures that the loader overlay is hidden after the data is fetched.
  ///
  /// The method performs the following steps:
  /// 1. Initializes an empty list of `MealCategory`.
  /// 2. Fetches the documents from the Firestore collection.
  /// 3. Iterates through the documents and converts each document's data into a `MealCategory` object.
  /// 4. Updates the `categories` state with the fetched list of `MealCategory` if the widget is still mounted.
  /// 5. Hides the loader overlay after a short delay if the widget is still mounted.
  ///
  /// Note: The method uses `async` and `await` to handle asynchronous operations.
  void _getCategoryList() async {
    final List<MealCategory> localCategories = [];
    var querySnapshot = await collection.get();
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data();
      localCategories.add(MealCategory.fromMap(data));
    }

    if (mounted) {
      setState(() {
        categories = localCategories;
      });
    }

    // HIDE LOADER
    Future.delayed(const Duration(seconds: 0), () {
      if (mounted) {
        context.loaderOverlay.hide();
      }
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

  /// Navigates to the MealScreen with the selected category and retrieves the updated category list upon returning.
  ///
  /// This method uses the Navigator to push a new MaterialPageRoute to the MealScreen,
  /// passing the selected [category] and the list of [categories] as arguments.
  /// Once the MealScreen is popped, it calls [_getCategoryList] to refresh the category list.
  ///
  /// Parameters:
  /// - [context]: The BuildContext used to navigate.
  /// - [category]: The selected MealCategory to be displayed in the MealScreen.
  void _selectCategory(BuildContext context, MealCategory category) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (ctx) => MealScreen(
              mealCategory: category,
              categories: categories,
            ),
          ),
        )
        .then((value) => _getCategoryList());
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Categories"),
        actions: [
          // ONLY VISIBLE IF LOGGED IN USER IS ADMIN
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () {
                // REDIRECT TO ADD CATEGORY SCREEN
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (ctx) => const AddCategoryScreen(),
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
                for (final category in categories)
                  CategoryGridItem(
                      mealCategory: category,
                      onSelectCategory: () {
                        _selectCategory(context, category);
                      })
              ],
            ),
    );
  }
}
