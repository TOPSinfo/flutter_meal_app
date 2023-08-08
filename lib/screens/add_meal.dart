import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:meal_app/main.dart';
import 'package:meal_app/models/category.dart';
import 'package:meal_app/models/meal.dart';
import 'package:meal_app/widgets/dynamic_textfield.dart';
import 'package:multiselect/multiselect.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:radio_group_v2/radio_group_v2.dart';

import '../widgets/image_input.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({
    super.key,
    this.meal,
    required this.arrCategories,
  });

  final Meal? meal;
  final List<Categoryy> arrCategories;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController durationController = TextEditingController();

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

  List<String> affordabilities = [
    "Affordable",
    "Pricey",
    "Luxurious",
  ];

  String selectedAffordability = 'Affordable';

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

  @override
  void dispose() {
    super.dispose();

    idController.dispose();
    durationController.dispose();
  }

  @override
  void initState() {
    _urlToFile();
    super.initState();
  }

  void _showToastMessage(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _urlToFile() async {
    if (widget.meal != null) {
      var meal = widget.meal;
      idController.text = meal!.id;
      titleController.text = meal.title;
      durationController.text = '${meal.duration}';
      veganController.selectAt(meal.isVegan ? 0 : 1);
      vegetarianController.selectAt(meal.isVegetarian ? 0 : 1);
      lactoseController.selectAt(meal.isLactoseFree ? 0 : 1);
      var categorie = widget.arrCategories
          .where((element) => meal.categories.contains(element.id))
          .toList();
      selectedCategories = categorie.map((e) => e.title).toList();
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

  Future<void> _checkValidationsAndSaveMealInFireStoreDatabase(
      BuildContext context) async {
    List<String> arrSelectedCategoryIds = [];

    for (var availableCategory in widget.arrCategories) {
      if (selectedCategories.contains(availableCategory.title)) {
        arrSelectedCategoryIds.add(availableCategory.id);
      }
    }
    if (kDebugMode) {
      print(arrSelectedCategoryIds);
    }

    String isGlutonFree = glutonController.value.toString();
    String isVeganFree = veganController.value.toString();
    String isVegetarian = vegetarianController.value.toString();
    String isLactose = lactoseController.value.toString();

    if (idController.text.trim().isEmpty) {
      _showToastMessage("Please enter Id.");
    } else if (arrSelectedCategoryIds.isEmpty) {
      _showToastMessage("Please select atleast 1 Category.");
    } else if (titleController.text.trim().isEmpty) {
      _showToastMessage("Please enter Meal Title.");
    } else if (selectedAffordability.trim().isEmpty) {
      _showToastMessage("Please select Meal Affordability.");
    } else if (selectedcomplexity.trim().isEmpty) {
      _showToastMessage("Please select Meal Complexity.");
    } else if (_selectedImage == null && widget.meal == null) {
      _showToastMessage("Please select Meal Image.");
    } else if (durationController.text.trim().isEmpty) {
      _showToastMessage("Please enter Meal preparation Duration.");
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
      String documentID =
          (widget.meal != null) ? widget.meal!.docID : getRandomString(20);

      SVProgressHUD.show();

      if (_selectedImage != null) {
        mealURL = await uploadMealImageToStorage(documentID);
        if (kDebugMode) {
          print(mealURL);
        }
      } else {
        mealURL = widget.meal?.imageUrl ?? "";
      }

      Map<String, dynamic> mealData = {
        'id': idController.text.trim(),
        'docId': documentID,
        'categories': arrSelectedCategoryIds,
        'title': titleController.text.trim(),
        'affordability': selectedAffordability.toLowerCase(),
        'complexity': selectedcomplexity.toLowerCase(),
        'imageUrl': mealURL,
        'thumbUrl': mealURL,
        'duration': int.parse(durationController.text),
        'ingredients': ingredients,
        'steps': steps,
        'isGlutenFree': (isGlutonFree == "Yes" ? true : false),
        'isVegan': (isVeganFree == "Yes" ? true : false),
        'isVegetarian': (isVegetarian == "Yes" ? true : false),
        'isLactoseFree': (isLactose == "Yes" ? true : false),
      };

      if (widget.meal != null) {
        await collection.doc(documentID).update(mealData).then((value) {
          SVProgressHUD.dismiss();
          _showToastMessage("Meal Added Successfully");
          int count = 3;
          Navigator.of(context).popUntil((_) => count-- <= 0);
        }).catchError((error) {
          print('Update failed: $error');
          SVProgressHUD.dismiss();
        });
      } else {
        await collection.doc(documentID).set(mealData).then((value) {
          SVProgressHUD.dismiss();
          _showToastMessage("Meal Added Successfully");
          Navigator.pop(context);
        }).catchError((error) {
          print('Update failed: $error');
          SVProgressHUD.dismiss();
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    TextStyle bottomSheetBackgroundStyle =
        Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 15,
            );

    return Scaffold(
      appBar: AppBar(
        title: Text((widget.meal != null) ? "Update Meal" : "Add Meal"),
        actions: [
          TextButton(
            onPressed: () {
              _checkValidationsAndSaveMealInFireStoreDatabase(context);
            },
            child: Text(
              (widget.meal != null) ? "Update" : "Save",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
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
                IdWidget(
                    idController: idController,
                    bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DropDownMultiSelect(
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    selected_values_style: bottomSheetBackgroundStyle,
                    hintStyle: bottomSheetBackgroundStyle,
                    onChanged: (List<String> x) {
                      setState(() {
                        selectedCategories = x;
                      });
                    },
                    options: widget.arrCategories.map((e) => e.title).toList(),
                    selectedValues: selectedCategories,
                    whenEmpty: 'Select Category',
                  ),
                ),
                TitleWidget(
                    titleController: titleController,
                    bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
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
  });

  final TextEditingController titleController;
  final TextStyle bottomSheetBackgroundStyle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: titleController,
      decoration: const InputDecoration(hintText: "Meal Title"),
      style: bottomSheetBackgroundStyle,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter id.';
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
      decoration: const InputDecoration(hintText: "Duration"),
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

  @override
  void initState() {
    controller = widget.controller;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RadioButtonWidget oldWidget) {
    controller = widget.controller;
    super.didUpdateWidget(oldWidget);
  }

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

extension FileEx on File {
  String get name => path.split(Platform.pathSeparator).last;
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
