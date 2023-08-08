import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:meal_app/main.dart';
import 'package:meal_app/models/category.dart';
import 'package:progressive_image/progressive_image.dart';
import '../models/meal.dart';
import 'add_meal.dart';

class MealDetailsScreen extends StatefulWidget {
  const MealDetailsScreen(
      {super.key, required this.meal, required this.categories});

  final Meal meal;
  final List<Categoryy> categories;

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  void _deleteMeal(BuildContext context) async {
    SVProgressHUD.show();
    // DELETE IMAGE FROM STORAGE FIRST
    await _deleteMealImageFromStorage(context);
    // DELETE MELAL DATA FROM COLLECTION
    db.collection("meals").doc(widget.meal.docID).delete().then(
      (doc) {
        SVProgressHUD.dismiss();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Meal Deleted Successfully"),
          ),
        );

        int count = 2;
        Navigator.of(context).popUntil((_) => count-- <= 0);
      },
      onError: (e) {
        SVProgressHUD.dismiss();
        print("Error updating document $e");
      },
    );
  }

  Future<void> _deleteMealImageFromStorage(BuildContext context) async {
    String filePath = "${widget.meal.docID}_image";
    await FirebaseStorage.instance
        .ref()
        .child('images/meal/$filePath')
        .delete()
        .then((_) {
      print('Successfully deleted $filePath storage item');
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal.title),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => AddMealScreen(
                    arrCategories: widget.categories,
                    meal: widget.meal,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onPressed: () {
              showDeleteAlertDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
    );
  }
}
