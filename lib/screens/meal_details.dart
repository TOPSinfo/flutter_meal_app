import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:meal_app/main.dart';
import 'package:meal_app/models/cart.dart';
import 'package:meal_app/models/category.dart';
import 'package:meal_app/screens/Authentication/phone.dart';
import 'package:meal_app/screens/Cart/my_cart.dart';
import 'package:progressive_image/progressive_image.dart';
import '../models/meal.dart';
import 'add_meal.dart';

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen(
      {super.key, required this.meal, required this.categoryy});

  final Meal meal;
  final Categoryy categoryy;

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

  // DELETE MEAL FROM THE FIREBASE FIRESTORE
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

  // UPDATE CART BADGE COUNT
  void updateBadge() async {
    cartbadgeCount.value = await getCartCount(context);
    setState(() {
      _hideProgress();
    });
  }

  // ADD MEAL TO CART
  void _addItemToCart(BuildContext context) async {
    _showProgress();
    var cart = Cart(
        id: widget.meal.docID,
        title: widget.meal.title,
        price: widget.meal.price,
        image: widget.meal.imageUrl,
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

  // DELETE MEAL IMAGE FROM STORAGE
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

  // SHOW DELETE MEAL CONFIRMATION DIALOG
  showDeleteAlertDialog(BuildContext context) {
    TextStyle style = TextStyle(
        color: Theme.of(context).colorScheme.onBackground,
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
        title: Text(widget.meal.title),
        actions: [
          Visibility(
            visible: (currentUser != null && currentUser?.isAdmin == true),
            child: IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AddMealScreen(
                      category: widget.categoryy,
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
                color: Theme.of(context).colorScheme.onBackground,
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
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                onPressed: () {
                  if ((auth.currentUser?.uid ?? "").trim().isEmpty) {
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
                          color: Theme.of(context).colorScheme.onBackground,
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
                          color: Theme.of(context).colorScheme.onBackground,
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
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
