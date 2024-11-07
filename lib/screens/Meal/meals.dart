import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../helper/constant.dart';
import '../../models/cart.dart';
import '../../models/category.dart';
import '../../models/meal.dart';
import '../../widgets/meal_item.dart';
import '../../widgets/no_data.dart';
import '../Authentication/phone.dart';
import 'add_meal.dart';
import 'meal_details.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({
    super.key,
    required this.mealCategory,
    required this.categories,
  });

  final MealCategory mealCategory;
  final List<MealCategory> categories;

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  List<Meal> meals = [];
  List<String> filters = [];
  bool isBannerVisible = false;

  /// Parses meal data from a list of [DocumentSnapshot] and applies filters to the meals.
  ///
  /// This function processes the raw meal data, converts it into a list of [Meal] objects,
  /// applies the specified filters, and sorts the meals in alphabetical order by title.
  ///
  /// If [isWantToSetState] is true, the function will call `setState` to update the UI with
  /// the filtered and sorted meal data. Otherwise, it will update the meal data without
  /// calling `setState`.
  ///
  /// Parameters:
  /// - [mealsData]: A list of [DocumentSnapshot] containing the raw meal data.
  /// - [isWantToSetState]: A boolean indicating whether to call `setState` to update the UI.
  ///
  /// The function also applies the following filters based on the `filters` list:
  /// - Gluten-free
  /// - Lactose-free
  /// - Vegetarian
  /// - Vegan
  ///
  /// The filtered meals are then sorted in alphabetical order by their title.
  void parseMealData(List<DocumentSnapshot> mealsData, bool isWantToSetState) {
    final List<Meal> localMeals = [];

    for (var doc in mealsData) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

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
          categoryId: data['categoryId'],
          title: data['title'],
          imageUrl: data['imageUrl'],
          thumbUrl: data['thumbUrl'],
          ingredients: List<String>.from(data['ingredients']),
          steps: List<String>.from(data['steps']),
          duration: data['duration'],
          price: data['price'],
          complexity: complexity,
          affordability: affordability,
          isGlutenFree: data['isGlutenFree'],
          isLactoseFree: data['isLactoseFree'],
          isVegan: data['isVegan'],
          isVegetarian: data['isVegetarian'],
        ),
      );
    }

    bool isGlutonFree =
        filters.contains(MealFilter.glutenFree.name) ? true : false;
    bool isLactoseFree =
        filters.contains(MealFilter.lactoseFree.name) ? true : false;
    bool isVegetarian =
        filters.contains(MealFilter.vegetarian.name) ? true : false;
    bool isVegan = filters.contains(MealFilter.vegan.name) ? true : false;

    List<Meal> finalData = [];

    var filteredMeals = localMeals
        .where((meal) => meal.categoryId == widget.mealCategory.id)
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

    // SORTING MEALS DATA ALPHABETIC ASCENDING ORDER
    finalData.sort((a, b) => a.title.toString().compareTo(b.title.toString()));

    if (isWantToSetState) {
      setState(() {
        _hideProgress();
        meals = finalData;
      });
    } else {
      _hideProgress();
      meals = finalData;
    }
  }

  // HIDE LOADER
  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  /// Navigates to the MealDetailsScreen with the selected meal and its category.
  ///
  /// This method uses the Navigator to push a new route onto the stack, which
  /// displays the MealDetailsScreen. The selected [meal] and its category
  /// [widget.mealCategory] are passed as arguments to the MealDetailsScreen.
  ///
  /// [context] is the BuildContext of the current widget.
  /// [meal] is the selected Meal object.
  void _selectMeal(BuildContext context, Meal meal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MealDetailsScreen(
          meal: meal,
          mealCategory: widget.mealCategory,
        ),
      ),
    );
  }

  /// Adds a meal item to the user's cart in the Firestore database.
  ///
  /// This function first shows a progress indicator and then checks if the user
  /// is authenticated. If the user is not authenticated, it navigates to the
  /// `PhoneScreen` for authentication. If the user is authenticated, it checks
  /// if the meal item already exists in the user's cart. If the item exists, it
  /// updates the quantity of the item in the cart. If the item does not exist,
  /// it adds the item to the cart.
  ///
  /// The function handles Firestore operations and shows a toast message upon
  /// successful addition or update of the meal item in the cart. It also hides
  /// the progress indicator after the operation is complete.
  ///
  /// Parameters:
  /// - `context`: The build context of the widget.
  /// - `meal`: The meal item to be added to the cart.
  void _addItemToCart(BuildContext context, Meal meal) async {
    _showProgress();
    var cart = Cart(
        id: meal.docID,
        title: meal.title,
        price: meal.price,
        image: meal.imageUrl,
        quantity: 1);
    User? user = fAuth.currentUser;
    final uid = user?.uid;

    if ((uid ?? "").trim().isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const PhoneScreen(),
        ),
      );
      return;
    }

    final snapshot = await db
        .collection('cart')
        .doc(uid)
        .collection("mycart")
        .doc(meal.docID)
        .get();

    if (snapshot.exists) {
      var cart = Cart.fromMap(snapshot.data()!);

      var updatedCartItem = Cart(
          id: cart.id,
          title: cart.title,
          price: cart.price,
          image: cart.image,
          quantity: cart.quantity + 1);

      db
          .collection('cart')
          .doc(uid)
          .collection("mycart")
          .doc(meal.docID)
          .update(updatedCartItem.toMap())
          .then((value) {
        _hideProgress();
        showToastMessage("Meal Added to Cart Successfully", context);
      }).catchError((error) {
        if (kDebugMode) {
          print('Update failed: $error');
        }
        _hideProgress();
      });
    } else {
      db
          .collection('cart')
          .doc(uid)
          .collection("mycart")
          .doc(meal.docID)
          .set(cart.toMap())
          .then((value) {
        _hideProgress();
        showToastMessage("Meal Added to Cart Successfully", context);
      }).catchError((error) {
        if (kDebugMode) {
          print('Update failed: $error');
        }
        _hideProgress();
      });
    }
  }

  // SHOW DELETE CATEGORY ALERT DIALOG
  void _selectDeleteCategory(BuildContext context, MealCategory category) {
    _showDeleteCategoryAlertDialog(context, category);
  }

  /// Displays an alert dialog to confirm the deletion of a meal category.
  ///
  /// The dialog informs the user that deleting the category will also delete all
  /// meal items related to this category. It provides two options: "No" to cancel
  /// the deletion and "Yes" to confirm the deletion.
  ///
  /// The dialog uses the current theme's color scheme for styling the text and buttons.
  ///
  /// Parameters:
  /// - `context`: The build context in which the dialog is displayed.
  /// - `category`: The meal category to be deleted.
  _showDeleteCategoryAlertDialog(BuildContext context, MealCategory category) {
    TextStyle style = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
    );

    TextStyle buttonStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
    );

    Widget noButton = TextButton(
      child: Text(
        "No",
        style: buttonStyle,
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget yesButton = TextButton(
      child: Text(
        "Yes",
        style: buttonStyle,
      ),
      onPressed: () {
        Navigator.pop(context);
        _deleteCategory(context, category);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        "Delete",
        style: buttonStyle,
      ),
      content: Text(
        "By deleting this category all meal item related to this category will be deleted.\n\nAre you sure you want to delete this category?",
        style: style,
      ),
      actions: [
        noButton,
        yesButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  /// Deletes a category and its associated meals from the Firestore database.
  ///
  /// This function performs the following steps:
  /// 1. Shows a progress indicator.
  /// 2. Deletes the category document from the 'categories' collection where the category ID matches.
  /// 3. Deletes all meal documents from the 'meals' collection where the category ID matches.
  /// 4. Hides the progress indicator.
  /// 5. Shows a toast message indicating successful deletion.
  /// 6. Pops the current screen from the navigation stack.
  ///
  /// Parameters:
  /// - `context`: The BuildContext of the current widget.
  /// - `category`: The MealCategory object representing the category to be deleted.
  void _deleteCategory(BuildContext context, MealCategory category) {
    _showProgress();
    db
        .collection('categories')
        .where('id', isEqualTo: category.id)
        .get()
        .then((value) {
      for (var element in value.docs) {
        db.collection('categories').doc(element.id).delete().then((value) {
          if (kDebugMode) {
            print('deleted category');
          }
        });
      }
    });

    db
        .collection('meals')
        .where('categoryId', isEqualTo: category.id)
        .get()
        .then((value) {
      for (var element in value.docs) {
        db.collection('meals').doc(element.id).delete().then((value) {
          if (kDebugMode) {
            print('deleted item from ${element.id} category');
          }
        });
      }
      _hideProgress();
      showToastMessage('Category deleted successfully', context);
      Navigator.pop(context);
    });
  }

  /// Fetches meals from the Firestore database based on the category ID.
  ///
  /// This function queries the 'meals' collection in the Firestore database
  /// and retrieves documents where the 'categoryId' field matches the
  /// `mealCategory.id` of the current widget.
  ///
  /// Returns a [Future] that resolves to a [QuerySnapshot] containing the
  /// results of the query.
  Future<QuerySnapshot> fetchMeals() async {
    final collection = db.collection('meals');
    final querySnapshot = await collection
        .where('categoryId', isEqualTo: widget.mealCategory.id)
        .get();
    return querySnapshot;
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(widget.mealCategory.title),
        actions: [
          Visibility(
            // ADD MEAL OPTION FOR ADMIN ONLY
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (ctx) => AddMealScreen(
                      mealCategory: widget.mealCategory,
                    ),
                  ),
                )
                    .then((value) {
                  setState(() {});
                });
              },
              icon: const Icon(Icons.add),
            ),
          ),
          // DELETE MEAL OPTION FOR ADMIN ONLY
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () {
                _selectDeleteCategory(context, widget.mealCategory);
              },
              icon: const Icon(Icons.delete),
            ),
          ),
        ],
      ),
      // FUTURE BUILDER TO FETCH DATA FROM FIRESTORE
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          future: fetchMeals(),
          builder: (context, snapshot) {
            // ERROR WHILE FETCHING DATA
            if (snapshot.hasError) {
              _hideProgress();
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // DATA FETCHING IS IN PROGRESS
            if (snapshot.connectionState == ConnectionState.waiting) {
              _showProgress();
              return Container();
            }

            // NO DATA FOUND
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              _hideProgress();
              return noDataWidget(context);
            }

            _hideProgress();

            // FOUND DATA AND PARSE DOCUMENT SNAPSHOT TO MEAL OBJECT
            List<DocumentSnapshot> data = snapshot.data!.docs;
            parseMealData(data, false);

            // DISPLAY DATA IN LIST VIEW
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Stack(
                children: [
                  ListView.builder(
                    itemCount: meals.length,
                    itemBuilder: (ctx, index) => MealItem(
                      meal: meals[index],
                      onSelectMeal: (meal) {
                        _selectMeal(context, meal);
                      },
                      onAddToCart: (Meal meal) {
                        _addItemToCart(context, meal);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
