import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:progressive_image/progressive_image.dart';
import '../../helper/constant.dart';
import '../../models/cart.dart';
import '../../models/category.dart';
import '../../models/meal.dart';
import '../Authentication/phone.dart';
import '../Cart/my_cart.dart';
import 'add_meal.dart';

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen(
      {super.key, required this.meal, required this.mealCategory});

  final Meal meal;
  final MealCategory mealCategory;

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  int badgeCount = 0;

  // INIT STATE
  @override
  void initState() {
    updateBadge();
    super.initState();
    _showProgress();
  }

  // HIDE LOADER
  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  /// Deletes a meal from the database and its associated image from storage.
  ///
  /// This function performs the following steps:
  /// 1. Shows a progress indicator.
  /// 2. Deletes the meal image from storage by calling `_deleteMealImageFromStorage`.
  /// 3. Deletes the meal data from the Firestore collection.
  /// 4. Hides the progress indicator.
  /// 5. Shows a success message using a `SnackBar`.
  /// 6. Pops two screens from the navigation stack after the meal is deleted successfully.
  ///
  /// If an error occurs during the deletion process, the progress indicator is hidden
  /// and the error is printed in debug mode.
  ///
  /// Parameters:
  /// - `context`: The `BuildContext` of the widget from which this function is called.
  void _deleteMeal(BuildContext context) async {
    _showProgress();
    // DELETE IMAGE FROM STORAGE FIRST
    await _deleteMealImageFromStorage(context);
    // DELETE MELAL DATA FROM COLLECTION
    db.collection("meals").doc(widget.meal.docID).delete().then(
      (doc) {
        _hideProgress();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Meal Deleted Successfully"),
          ),
        );

        // POP TWO SCREENS AFTER MEAL DELETED SUCCESSFULLY
        int count = 2;
        Navigator.of(context).popUntil((_) => count-- <= 0);
      },
      onError: (e) {
        _hideProgress();
        if (kDebugMode) {
          print("Error updating document $e");
        }
      },
    );
  }

  /// Updates the cart badge count by fetching the current cart count asynchronously.
  /// After updating the badge count, it hides the progress indicator.
  void updateBadge() async {
    cartbadgeCount.value = await getCartCount(context);
    setState(() {
      _hideProgress();
    });
  }

  /// Adds the current meal to the cart. If the user is not authenticated,
  /// navigates to the PhoneScreen for authentication. If the meal is already
  /// in the cart, updates the quantity. If the meal is not in the cart, adds
  /// it to the cart.
  ///
  /// This method performs the following steps:
  /// 1. Shows a progress indicator.
  /// 2. Creates a `Cart` object with the current meal details.
  /// 3. Checks if the user is authenticated.
  /// 4. If the user is not authenticated, navigates to the PhoneScreen.
  /// 5. If the user is authenticated, checks if the meal is already in the cart.
  /// 6. If the meal is already in the cart, updates the quantity.
  /// 7. If the meal is not in the cart, adds it to the cart.
  /// 8. Updates the cart badge.
  /// 9. Hides the progress indicator.
  ///
  /// Parameters:
  /// - `context`: The build context.
  void _addItemToCart(BuildContext context) async {
    _showProgress();
    var cart = Cart(
        id: widget.meal.docID,
        title: widget.meal.title,
        price: widget.meal.price,
        image: widget.meal.imageUrl,
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
        .doc(widget.meal.docID)
        .get();

    // FIRST CHECK IF THE MEAL IS ALREADY IN THE CART
    // IF YES THEN UPDATE THE QUANTITY
    // IF NO THEN ADD THE MEAL TO THE CART
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
          .doc(widget.meal.docID)
          .update(updatedCartItem.toMap())
          .then((value) {
        updateBadge();
        _hideProgress();
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
          .doc(widget.meal.docID)
          .set(cart.toMap())
          .then((value) {
        updateBadge();
        _hideProgress();
      }).catchError((error) {
        if (kDebugMode) {
          print('Update failed: $error');
        }
        _hideProgress();
      });
    }
  }

  /// Deletes the meal image from Firebase Storage.
  ///
  /// This method constructs the file path using the meal's document ID and
  /// attempts to delete the image from the 'images/meal/' directory in Firebase Storage.
  /// If the deletion is successful and the app is in debug mode, a message is printed
  /// to the console indicating the successful deletion.
  ///
  /// [context] is the BuildContext of the widget that calls this method.
  ///
  /// Throws an [Exception] if the deletion fails.
  Future<void> _deleteMealImageFromStorage(BuildContext context) async {
    String filePath = "${widget.meal.docID}_image";
    await FirebaseStorage.instance
        .ref()
        .child('images/meal/$filePath')
        .delete()
        .then((_) {
      if (kDebugMode) {
        print('Successfully deleted $filePath storage item');
      }
    });
  }

  /// Displays an alert dialog to confirm the deletion of a meal.
  ///
  /// The dialog contains a message asking the user if they are sure they want to delete the meal,
  /// and two buttons: "No" and "Yes". If the user presses "No", the dialog is dismissed. If the user
  /// presses "Yes", the meal is deleted and the dialog is dismissed.
  ///
  /// The appearance of the text and buttons is styled according to the current theme.
  ///
  /// Parameters:
  /// - `context`: The BuildContext in which the dialog is displayed.
  showDeleteAlertDialog(BuildContext context) {
    TextStyle style = TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w400);

    TextStyle buttonStyle = TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 15,
        fontWeight: FontWeight.w700);

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
        _deleteMeal(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        "Delete",
        style: buttonStyle,
      ),
      content: Text(
        "Are you sure want to delete the Meal?",
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

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(widget.meal.title),
        actions: [
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AddMealScreen(
                      mealCategory: widget.mealCategory,
                      meal: widget.meal,
                    ),
                  ),
                );
              },
            ),
          ),
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                showDeleteAlertDialog(context);
              },
            ),
          ),
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == false),
            child: Badge(
              label: Text(cartbadgeCount.value.toString()),
              isLabelVisible: cartbadgeCount.value > 0,
              alignment: Alignment.topRight,
              offset: const Offset(-10, 5),
              child: IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  if ((fAuth.currentUser?.uid ?? "").trim().isEmpty) {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (ctx) => const PhoneScreen(),
                      ),
                    )
                        .then((value) {
                      updateBadge();
                    });
                  } else {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (ctx) => const MyCartScreen(),
                      ),
                    )
                        .then((value) {
                      updateBadge();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Hero(
                tag: widget.meal.id,
                child: ProgressiveImage(
                  placeholder: null,
                  thumbnail: NetworkImage(widget.meal.thumbUrl),
                  image: NetworkImage(widget.meal.imageUrl),
                  fit: BoxFit.cover,
                  height: 300,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ingredients',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              for (final ingredient in widget.meal.ingredients)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    textAlign: TextAlign.center,
                    ingredient,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Steps',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              for (final step in widget.meal.steps)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    step,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Visibility(
        visible: (currentUser != null && currentUser?.isAdmin == false),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () {
              _addItemToCart(context);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.teal,
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(
              'Add To Cart',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
