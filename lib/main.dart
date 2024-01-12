import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'bottom_tabbar.dart';
import 'package:meal_app/models/meal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meal_app/models/user.dart';
import 'package:meal_app/screens/Authentication/phone.dart';

var db = FirebaseFirestore.instance;
final storageRef = FirebaseStorage.instance.ref();
final FirebaseAuth auth = FirebaseAuth.instance;
CurrentUser? currentUser;
var cartbadgeCount = ValueNotifier<int>(0);

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

List<Meal> favoriteMeals = [];

Future<int> getCartCount(BuildContext context) async {
  if (auth.currentUser?.uid != null) {
    var uuid = auth.currentUser?.uid;
    final snapshot =
        await db.collection('cart').doc(uuid).collection("mycart").get();
    return snapshot.docs.length;
  }
  return 0;
}

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color.fromARGB(255, 131, 57, 0),
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: Colors.white,
  ),
  textTheme: GoogleFonts.latoTextTheme(),
);

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isUserLoggedIn = false;
  @override
  void initState() {
    super.initState();

    // GET FIREBASE AUTH USER DATA
    User? user = auth.currentUser;
    final uid = user?.uid;
    if ((uid ?? "").trim().isEmpty) {
      // NOT LOGGED IN
    } else {
      // LOGGED IN
      var uid = auth.currentUser?.uid ?? "";
      _userDetail(uid);
      isUserLoggedIn = true;
    }
  }

  void _userDetail(String uid) async {
    var value = await db.collection('users').doc(uid).get();
    var data = value.data();
    if (data != null) {
      var userData = CurrentUser.fromMap(data);
      currentUser = userData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalLoaderOverlay(
      overlayColor: Colors.grey.withOpacity(0.3),
      useDefaultLoading: false,
      overlayWidgetBuilder: (_) {
        return  Center(
          child: SpinKitFadingCircle(
            color: Theme.of(context).colorScheme.onPrimary,
            size: 40.0,
          ),
        );
      },
      child: MaterialApp(
        home: isUserLoggedIn ? const BottomTabBar() : const PhoneScreen(),
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
      ),
    );
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
