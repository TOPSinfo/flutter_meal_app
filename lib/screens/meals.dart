import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:meal_app/models/cart.dart';
import 'package:meal_app/screens/Authentication/phone.dart';
import 'package:meal_app/main.dart';
import 'package:meal_app/models/category.dart';
import 'package:meal_app/screens/add_meal.dart';
import '../models/meal.dart';
import '../widgets/meal_item.dart';
import 'MyOrder/order_list.dart';
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
    required this.category,
    required this.categories,
  });

  final Categoryy category;
  final List<Categoryy> categories;

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  List<Meal> meals = [];
  List<String> filters = [];
  bool isBannerVisible = false;

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

    bool isGlutonFree = filters.contains(Filter.glutenFree.name) ? true : false;
    bool isLactoseFree =
        filters.contains(Filter.lactoseFree.name) ? true : false;
    bool isVegetarian = filters.contains(Filter.vegetarian.name) ? true : false;
    bool isVegan = filters.contains(Filter.vegan.name) ? true : false;

    List<Meal> finalData = [];

    var filteredMeals = localMeals
        .where((meal) => meal.categoryId == widget.category.id)
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

  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  void _showProgress() {
    context.loaderOverlay.show();
  }

  void _selectMeal(BuildContext context, Meal meal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MealDetailsScreen(
          meal: meal,
          categoryy: widget.category,
        ),
      ),
    );
  }

  // ADD ITEM TO CART ON CLICK OF CART ICON
  void _addItemToCart(BuildContext context, Meal meal) async {
    _showProgress();
    var cart = Cart(
        id: meal.docID,
        title: meal.title,
        price: meal.price,
        image: meal.imageUrl,
        quantity: 1);
    User? user = auth.currentUser;
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

  void _selectDeleteCategory(BuildContext context, Categoryy category) {
    _showDeleteCategoryAlertDialog(context, category);
  }

  _showDeleteCategoryAlertDialog(BuildContext context, Categoryy category) {
    TextStyle style = TextStyle(
      color: Theme.of(context).colorScheme.onBackground,
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

  void _deleteCategory(BuildContext context, Categoryy category) {
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

  // Widget noDataWidget() {
  //   return Center(
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Text(
  //           'Uh oh ... nothing here!',
  //           style: Theme.of(context).textTheme.headlineLarge!.copyWith(
  //                 color: Theme.of(context).colorScheme.onBackground,
  //               ),
  //         ),
  //         const SizedBox(height: 16),
  //         Text(
  //           'Try selecting a different category!',
  //           style: Theme.of(context).textTheme.bodyLarge!.copyWith(
  //                 color: Theme.of(context).colorScheme.onBackground,
  //               ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<QuerySnapshot> fetchMeals() async {
    final collection = db.collection('meals');
    final querySnapshot = await collection
        .where('categoryId', isEqualTo: widget.category.id)
        .get();
    return querySnapshot;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
        actions: [
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              color: Theme.of(context).colorScheme.onBackground,
              onPressed: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (ctx) => AddMealScreen(
                      category: widget.category,
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
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              color: Theme.of(context).colorScheme.onBackground,
              onPressed: () {
                _selectDeleteCategory(context, widget.category);
              },
              icon: const Icon(Icons.delete),
            ),
          ),
        ],
      ),
      // body: content,
      body: FutureBuilder<QuerySnapshot>(
        future: fetchMeals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _hideProgress();
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            _showProgress();
            return Container();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            _hideProgress();
            return noDataWidget(context);
          }

          _hideProgress();

          List<DocumentSnapshot> data = snapshot.data!.docs;
          parseMealData(data, false);

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
    );
  }
}
