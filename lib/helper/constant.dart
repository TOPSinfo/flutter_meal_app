import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import '../models/meal.dart';
import '../models/user.dart';

// FILTER ENUM
enum MealFilter {
  glutenFree,
  lactoseFree,
  vegetarian,
  vegan,
}

var db = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final FirebaseAuth fAuth = FirebaseAuth.instance;
CurrentUser? currentUser;
var cartbadgeCount = ValueNotifier<int>(0);
// GET CART COUNT
Future<int> getCartCount(BuildContext context) async {
  if (fAuth.currentUser?.uid != null) {
    var uuid = fAuth.currentUser?.uid;
    final snapshot =
        await db.collection('cart').doc(uuid).collection("mycart").get();
    return snapshot.docs.length;
  }
  return 0;
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

List<Meal> favoriteMeals = [];

final orderProcesses = [
  'Order Placed',
  'Order Accepted',
  'Preparing',
  'Ready for Pickup',
  'Out for Delivery',
  'Delivered',
];

// SHOW TOAST MESSAGE
void showToastMessage(String message, BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
