import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:radio_group_v2/radio_group_v2.dart';

import '../../helper/constant.dart';
import '../../helper/extension.dart';
import '../../models/category.dart';
import '../../models/meal.dart';
import '../../widgets/dynamic_textfield.dart';
import '../../widgets/image_input.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({
    super.key,
    this.meal,
    required this.mealCategory,
  });

  final Meal? meal;
  final MealCategory mealCategory;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  RadioGroupController glutonController = RadioGroupController();
  RadioGroupController veganController = RadioGroupController();
  RadioGroupController vegetarianController = RadioGroupController();
  RadioGroupController lactoseController = RadioGroupController();

  final GlobalKey<RadioGroupState> glutenGroupKey =
      GlobalKey<RadioGroupState>();

  final GlobalKey<RadioGroupState> veganGroupKey = GlobalKey<RadioGroupState>();

  final GlobalKey<RadioGroupState> vegetarianGroupKey =
      GlobalKey<RadioGroupState>();

  final GlobalKey<RadioGroupState> lactoseGroupKey =
      GlobalKey<RadioGroupState>();

  List<String> selectedCategories = [];

  // AFFORDINABILITY OPTIONS
  List<String> affordabilities = [
    "Affordable",
    "Pricey",
    "Luxurious",
  ];

  String selectedAffordability = 'Affordable';

  // COMPLEXITY OPTIONS
  List<String> complexities = [
    "Simple",
    "Challenging",
    "Hard",
  ];

  String selectedcomplexity = 'Simple';

  File? _selectedImage;
  List<String> ingredients = [''];
  List<String> steps = [''];
  final _scrollKey = GlobalKey();

  // DISPOSE TEXTFIELDS ONCE CONTROLLER IS DISPOSED
  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
    durationController.dispose();
    priceController.dispose();
  }

  // INIT STATE
  @override
  void initState() {
    _urlToFile();
    super.initState();
  }

  // HIDE LOADER
  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  /// Displays a toast message using a SnackBar.
  ///
  /// This method clears any existing SnackBars and shows a new SnackBar
  /// with the provided message.
  ///
  /// Parameters:
  /// - `message`: The message to be displayed in the SnackBar.
  void _showToastMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  /// Populates the form fields with the data from the provided meal object.
  ///
  /// If the `meal` object is not null, this method sets the text controllers
  /// with the meal's title, duration, and price. It also updates the selection
  /// controllers for vegan, vegetarian, lactose-free, and gluten-free options.
  /// Additionally, it sets the ingredients, steps, affordability, and complexity
  /// fields based on the meal's properties.
  ///
  /// A delayed update is performed to ensure the state is properly set for the
  /// gluten-free, vegan, vegetarian, and lactose-free options.
  void _urlToFile() async {
    if (widget.meal != null) {
      var meal = widget.meal;
      titleController.text = meal!.title;
      durationController.text = '${meal.duration}';
      priceController.text = '${meal.price}';
      veganController.selectAt(meal.isVegan ? 0 : 1);
      vegetarianController.selectAt(meal.isVegetarian ? 0 : 1);
      lactoseController.selectAt(meal.isLactoseFree ? 0 : 1);
      ingredients = meal.ingredients;
      steps = meal.steps;
      selectedAffordability = meal.affordability.name.capitalize();
      selectedcomplexity = meal.complexity.name.capitalize();

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          glutonController.selectAt(meal.isGlutenFree ? 0 : 1);
          veganController.selectAt(meal.isVegan ? 0 : 1);
          vegetarianController.selectAt(meal.isVegetarian ? 0 : 1);
          lactoseController.selectAt(meal.isLactoseFree ? 0 : 1);
        });
      });
    }
  }

  /// Validates the meal form inputs and saves the meal data to Firestore database.
  ///
  /// This method performs the following steps:
  /// 1. Validates the form inputs such as meal title, affordability, complexity, image, duration, price, ingredients, steps, and dietary options.
  /// 2. If any validation fails, it shows a toast message indicating the missing or incorrect input.
  /// 3. If all validations pass, it proceeds to save the meal data to Firestore.
  /// 4. If a new meal is being added, it generates a new document ID with 20 random characters.
  /// 5. If an existing meal is being updated, it uses the existing document ID.
  /// 6. If an image is selected, it uploads the image to storage and gets the image URL.
  /// 7. Removes any empty ingredients and steps from the respective lists.
  /// 8. Converts the meal form data into a map.
  /// 9. If updating an existing meal, it updates the meal document in Firestore.
  /// 10. If adding a new meal, it creates a new meal document in Firestore.
  /// 11. Shows a progress indicator while the operation is in progress.
  /// 12. Shows a toast message indicating the success or failure of the operation.
  /// 13. Navigates back to the previous screen upon successful completion.
  ///
  /// Parameters:
  /// - `context`: The build context of the widget.
  ///
  /// Returns:
  /// - A `Future<void>` indicating the completion of the operation.
  Future<void> _checkValidationsAndSaveMealInFireStoreDatabase(
      BuildContext context) async {
    String isGlutonFree = glutonController.value.toString();
    String isVeganFree = veganController.value.toString();
    String isVegetarian = vegetarianController.value.toString();
    String isLactose = lactoseController.value.toString();

    if (titleController.text.trim().isEmpty) {
      _showToastMessage("Please enter Meal Title.");
    } else if (selectedAffordability.trim().isEmpty) {
      _showToastMessage("Please select Meal Affordability.");
    } else if (selectedcomplexity.trim().isEmpty) {
      _showToastMessage("Please select Meal Complexity.");
    } else if (_selectedImage == null && widget.meal == null) {
      _showToastMessage("Please select Meal Image.");
    } else if (durationController.text.trim().isEmpty) {
      _showToastMessage("Please enter Meal preparation Duration.");
    } else if (priceController.text.trim().isEmpty) {
      _showToastMessage("Please enter Meal price.");
    } else if (ingredients.length == 1 && ingredients[0].trim().isEmpty) {
      _showToastMessage("Please add Meal Ingredients.");
    } else if (steps.length == 1 && steps[0].trim().isEmpty) {
      _showToastMessage("Please add the steps to prepare the Meal.");
    } else if (isGlutonFree == "null" || isGlutonFree.trim().isEmpty) {
      _showToastMessage("Please select Gluton option.");
    } else if (isVeganFree == "null" || isVeganFree.trim().isEmpty) {
      _showToastMessage("Please select Vegan option.");
    } else if (isVegetarian == "null" || isVegetarian.trim().isEmpty) {
      _showToastMessage("Please select Vegetarian option.");
    } else if (isLactose == "null" || isLactose.trim().isEmpty) {
      _showToastMessage("Please select Lactose option.");
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
      String mealURL = "";
      var collection = db.collection('meals');

      // GENERATING NEW DOCUMENT ID WITH 20 RANDOM CHARACTERS
      // IF ADMIN TRYING TO ADD NEW MEAL
      // WE ARE CHECKING THE MEAL OBJECT, WETHER IT'S NULL OR NOT
      // IF IT'S NULL THEN GENERATING DOCUMENT ID WITH 20 RANDOM CHARACTERS
      // IF IT'S NOT NULL THEN DIRECTLY ASSIGN MEAL DOCUMENT ID
      String documentID =
          (widget.meal != null) ? widget.meal!.docID : getRandomString(20);

      _showProgress();

      // IF SELECTED IMAGE IS NOT NULL THEN UPLOADING IMAGE TO STORAGE
      if (_selectedImage != null) {
        mealURL = await uploadMealImageToStorage(documentID);
        if (kDebugMode) {
          print(mealURL);
        }
      } else {
        mealURL = widget.meal?.imageUrl ?? "";
      }

      // REMOVING EMPTY INGREDIENTS AND STEPS
      ingredients = ingredients
          .where((ingredient) => ingredient.trim().isNotEmpty)
          .toList();
      steps = steps.where((step) => step.trim().isNotEmpty).toList();

      // CONVERTING THE MEAL FORM DATA INTO MAP
      Map<String, dynamic> mealData = {
        'id': widget.mealCategory.id.trim(),
        'docId': documentID,
        'categoryId': widget.mealCategory.id,
        'title': titleController.text.trim(),
        'affordability': selectedAffordability.toLowerCase(),
        'complexity': selectedcomplexity.toLowerCase(),
        'imageUrl': mealURL,
        'thumbUrl': mealURL,
        'duration': int.parse(durationController.text),
        'price': int.parse(priceController.text),
        'ingredients': ingredients,
        'steps': steps,
        'isGlutenFree': (isGlutonFree == "Yes" ? true : false),
        'isVegan': (isVeganFree == "Yes" ? true : false),
        'isVegetarian': (isVegetarian == "Yes" ? true : false),
        'isLactoseFree': (isLactose == "Yes" ? true : false),
      };

      // IF MEAL OBJECT IS NOT NULL THEN UPDATE THE MEAL
      // ELSE ADD NEW MEAL
      if (widget.meal != null) {
        await collection.doc(documentID).update(mealData).then((value) {
          _hideProgress();
          _showToastMessage("Meal Added Successfully");
          int count = 3;
          Navigator.of(context).popUntil((_) => count-- <= 0);
        }).catchError((error) {
          if (kDebugMode) {
            print('Update failed: $error');
          }
          _hideProgress();
        });
      } else {
        // ADD NEW MEAL
        await collection.doc(documentID).set(mealData).then((value) {
          _hideProgress();
          _showToastMessage("Meal Added Successfully");
          Navigator.pop(context);
        }).catchError((error) {
          if (kDebugMode) {
            print('Update failed: $error');
          }
          _hideProgress();
        });
      }
    }
  }

  // UPLOAD MEAL IMAGE TO FIREBASE STORAGE
  // ONCE IMAGE WILL UPLOADED SUCCESSFULLY WE GET URL FROM FIREBASE STORAGE
  // AND RETURN URL
  Future<String> uploadMealImageToStorage(String docID) async {
    Reference reference =
        storageRef.child('images/meal').child('${docID}_image');
    UploadTask uploadTask = reference.putFile(_selectedImage!);

    String url = "";
    await uploadTask.whenComplete(() async {
      url = await uploadTask.snapshot.ref.getDownloadURL();
    });

    return url;
  }

  // STEPS & INGREDIENTS DYNAMIC TEXTFIELDS ADD/REMOVE BUTTON LOGIC
  // INITIALLY THERE IS ONLY ONE EMPTY TEXTFIELD FOR STEPS AND INGREDIENTS
  // ONCE USER WILL ADD STEP & INGREDIENT AND PRESS THE PLUS BUTTON WILL ADD NEW TEXTFIELD FOR STEP & INGREDIENT
  // ONCE USER WILL PRESS THE MINUS BUTTON WILL REMOVE THE TEXTFIELD
  Widget _textfieldBtn(int index, bool isIngredient) {
    bool isLast = false;
    if (isIngredient) {
      isLast = index == ingredients.length - 1;
    } else {
      isLast = index == steps.length - 1;
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (isIngredient) {
            if (!isLast) {
              ingredients.removeAt(index);
            } else {
              if (ingredients.last.trim().isNotEmpty) {
                ingredients.add('');
              } else {
                _showToastMessage(
                    "To add new ingredient please fill the blank field");
              }
            }
          } else {
            if (!isLast) {
              steps.removeAt(index);
            } else {
              if (steps.last.trim().isNotEmpty) {
                steps.add('');
              } else {
                _showToastMessage(
                    "To add new step please fill the blank field");
              }
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isLast ? Colors.green : Colors.red,
        ),
        child: Icon(
          isLast ? Icons.add : Icons.remove,
          color: Colors.white,
        ),
      ),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    TextStyle bottomSheetBackgroundStyle =
        Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
            );

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text((widget.meal != null) ? "Update Meal" : "Add Meal"),
        actions: [
          TextButton(
            onPressed: () {
              _checkValidationsAndSaveMealInFireStoreDatabase(context);
            },
            child: Text(
              (widget.meal != null) ? "Update" : "Save",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: _scrollKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CenterTitleWidget(
                    title: "General",
                    bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                TitleWidget(
                  titleController: titleController,
                  bottomSheetBackgroundStyle: bottomSheetBackgroundStyle,
                  placeHolderText: 'Meal Title',
                  errorMessageText: 'Please enter meal title.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                      child: DropdownButton(
                        isExpanded: true,
                        value: selectedAffordability,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: affordabilities.map((String items) {
                          return DropdownMenuItem(
                            value: items,
                            child: Text(
                              items,
                              style: TextStyle(
                                  color: bottomSheetBackgroundStyle.color,
                                  fontSize: 15),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedAffordability = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                DropdownButton(
                  isExpanded: true,
                  value: selectedcomplexity,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: complexities.map((String items) {
                    return DropdownMenuItem(
                      value: items,
                      child: Text(
                        items,
                        style: TextStyle(
                            color: bottomSheetBackgroundStyle.color,
                            fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedcomplexity = newValue!;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ImageInput(
                    selectedImage: widget.meal?.imageUrl,
                    onPickeImage: (image) {
                      _selectedImage = image;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DurationWidget(
                      durationController: durationController,
                      bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PriceWidget(
                      priceController: priceController,
                      bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                ),
                CenterTitleWidget(
                    title: "Ingredients",
                    bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ingredients.length,
                    itemBuilder: (context, index) => Row(
                      children: [
                        Expanded(
                          child: DynamicTextfield(
                            key: UniqueKey(),
                            initialValue: ingredients[index],
                            isIngredient: true,
                            onChanged: (v) => ingredients[index] = v,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _textfieldBtn(index, true),
                      ],
                    ),
                    separatorBuilder: (context, index) => const SizedBox(
                      height: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CenterTitleWidget(
                      title: "Steps",
                      bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) => Row(
                      children: [
                        Expanded(
                          child: DynamicTextfield(
                            key: UniqueKey(),
                            initialValue: steps[index],
                            isIngredient: false,
                            onChanged: (v) => steps[index] = v,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _textfieldBtn(index, false),
                      ],
                    ),
                    separatorBuilder: (context, index) => const SizedBox(
                      height: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CenterTitleWidget(
                      title: "Gluton Free",
                      bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                ),
                RadioButtonWidget(
                    controller: glutonController,
                    bottomSheetBackgroundStyle: bottomSheetBackgroundStyle,
                    groupKey: glutenGroupKey),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CenterTitleWidget(
                      title: "Vegan",
                      bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                ),
                RadioButtonWidget(
                    controller: veganController,
                    bottomSheetBackgroundStyle: bottomSheetBackgroundStyle,
                    groupKey: veganGroupKey),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CenterTitleWidget(
                      title: "Vegetarian",
                      bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                ),
                RadioButtonWidget(
                    controller: vegetarianController,
                    bottomSheetBackgroundStyle: bottomSheetBackgroundStyle,
                    groupKey: vegetarianGroupKey),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CenterTitleWidget(
                      title: "Lactose Free",
                      bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                ),
                RadioButtonWidget(
                    controller: lactoseController,
                    bottomSheetBackgroundStyle: bottomSheetBackgroundStyle,
                    groupKey: lactoseGroupKey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ID Widget
class IdWidget extends StatelessWidget {
  const IdWidget({
    super.key,
    required this.idController,
    required this.bottomSheetBackgroundStyle,
  });

  final TextEditingController idController;
  final TextStyle bottomSheetBackgroundStyle;

  // UI
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: idController,
      // maxLength: 2,
      decoration: const InputDecoration(hintText: "Id"),
      style: bottomSheetBackgroundStyle,
    );
  }
}

// TITLE Widget
class TitleWidget extends StatelessWidget {
  const TitleWidget({
    super.key,
    required this.titleController,
    required this.bottomSheetBackgroundStyle,
    required this.placeHolderText,
    required this.errorMessageText,
  });

  final TextEditingController titleController;
  final TextStyle bottomSheetBackgroundStyle;
  final String placeHolderText;
  final String errorMessageText;

  // UI
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: titleController,
      decoration: InputDecoration(hintText: placeHolderText),
      style: bottomSheetBackgroundStyle,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errorMessageText;
        }
        return null;
      },
    );
  }
}

// TITLE Widget
class CenterTitleWidget extends StatelessWidget {
  const CenterTitleWidget({
    super.key,
    required this.title,
    required this.bottomSheetBackgroundStyle,
  });

  final TextStyle bottomSheetBackgroundStyle;
  final String title;

  // UI
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 17,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// DURATION Widget
class DurationWidget extends StatelessWidget {
  const DurationWidget({
    super.key,
    required this.durationController,
    required this.bottomSheetBackgroundStyle,
  });

  final TextEditingController durationController;
  final TextStyle bottomSheetBackgroundStyle;

  // UI
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLength: 2,
      controller: durationController,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        FilteringTextInputFormatter.digitsOnly
      ],
      decoration: const InputDecoration(
        hintText: "Duration",
        counterText: "",
      ),
      style: bottomSheetBackgroundStyle,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Duration.';
        }
        return null;
      },
    );
  }
}

// PRICE Widget
class PriceWidget extends StatelessWidget {
  const PriceWidget({
    super.key,
    required this.priceController,
    required this.bottomSheetBackgroundStyle,
  });

  final TextEditingController priceController;
  final TextStyle bottomSheetBackgroundStyle;

  // UI
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLength: 3,
      controller: priceController,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        FilteringTextInputFormatter.digitsOnly
      ],
      decoration: const InputDecoration(
        hintText: "Price",
        counterText: "",
      ),
      style: bottomSheetBackgroundStyle,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter Price.';
        }
        return null;
      },
    );
  }
}

// RADIO BUTTON Widget
class RadioButtonWidget extends StatefulWidget {
  const RadioButtonWidget({
    super.key,
    required this.controller,
    required this.bottomSheetBackgroundStyle,
    required this.groupKey,
  });

  final RadioGroupController controller;
  final TextStyle bottomSheetBackgroundStyle;
  final GlobalKey<RadioGroupState> groupKey;

  @override
  State<StatefulWidget> createState() {
    return _RadioButtonWidgetState();
  }
}

class _RadioButtonWidgetState extends State<RadioButtonWidget> {
  RadioGroupController? controller;

  // INIT STATE
  @override
  void initState() {
    controller = widget.controller;
    super.initState();
  }

  // DID UPDATE WIDGET
  @override
  void didUpdateWidget(covariant RadioButtonWidget oldWidget) {
    controller = widget.controller;
    super.didUpdateWidget(oldWidget);
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      key: widget.groupKey,
      orientation: RadioGroupOrientation.horizontal,
      controller: controller,
      values: const ["Yes", "No"],
      decoration: RadioGroupDecoration(
        activeColor: Colors.white,
        labelStyle: TextStyle(
            color: widget.bottomSheetBackgroundStyle.color, fontSize: 15),
      ),
    );
  }
}
