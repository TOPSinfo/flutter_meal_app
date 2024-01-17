import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meal_app/main.dart';
import 'package:meal_app/screens/add_meal.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/category.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AddCategoryScreenState();
  }
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _scrollKey = GlobalKey();
  TextEditingController idController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController color = TextEditingController();

  // CATEGORY INITIAL COLOR
  Color _pickerColor = Colors.black;

  // CHANGE CATEGORY COLOR
  void changeColor(Color color) {
    setState(() {
      _pickerColor = color;
    });
  }

  // CHECK VALIDATIONS AND SAVE CATEGORY IN FIRESTORE DATABASE
  Future<void> _checkValidationsAndSaveCategoryInFireStoreDatabase(
      BuildContext context) async {
    if (idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter category id like 'c1'."),
        ),
      );
      return;
    } else if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter category title."),
        ),
      );
      return;
    }

    var category = Categoryy(
      id: idController.text,
      title: titleController.text,
      color: _pickerColor.toHex(),
    );

    // String documentID = getRandomString(20);

    // ADD CATEGORY IN FIRESTORE DATABASE
    db.collection('categories').doc().set(category.toMap()).then(
      (value) {
        Navigator.of(context).pop();
      },
      onError: (e) {
        if (kDebugMode) {
          print("Error updating document $e");
        }
      },
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    TextStyle bottomSheetBackgroundStyle =
        Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
            );

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Category'),
          actions: [
            TextButton(
              onPressed: () {
                _checkValidationsAndSaveCategoryInFireStoreDatabase(context);
              },
              child: Text(
                "Save",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          key: _scrollKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              IdWidget(
                  idController: idController,
                  bottomSheetBackgroundStyle: bottomSheetBackgroundStyle),
              TitleWidget(
                titleController: titleController,
                bottomSheetBackgroundStyle: bottomSheetBackgroundStyle,
                placeHolderText: 'Category Title',
                errorMessageText: 'Please enter category title.',
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Text(
                    'Select Theme color',
                    style: bottomSheetBackgroundStyle,
                  ),
                  const Spacer(),
                  OutlinedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(_pickerColor)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Theme.of(context).colorScheme.onBackground,
                            title: const Text('Pick a color!'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: _pickerColor,
                                onColorChanged: changeColor,
                                paletteType: PaletteType.rgbWithBlue,
                              ),
                            ),
                            actions: <Widget>[
                              ElevatedButton(
                                child: const Text('Got it'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(''),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
