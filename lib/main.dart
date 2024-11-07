import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'bottom_tabbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'helper/app_theme.dart';
import 'helper/constant.dart';
import 'models/user.dart';
import 'screens/Authentication/phone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // DISABLE CAPTCHA VERIFICATION CODE
  FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
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

  // INIT STATE
  @override
  void initState() {
    super.initState();

    // GET FIREBASE AUTH USER DATA
    User? user = fAuth.currentUser;
    final uid = user?.uid;
    if ((uid ?? "").trim().isEmpty) {
      // NOT LOGGED IN
    } else {
      // LOGGED IN
      var uid = fAuth.currentUser?.uid ?? "";
      _userDetail(uid);
      isUserLoggedIn = true;
    }
  }

  // GET USER DETAIL
  /// Fetches user details from the database using the provided user ID (uid).
  ///
  /// This function retrieves the user document from the 'users' collection in the
  /// database, converts the document data to a `CurrentUser` object, and assigns
  /// it to the `currentUser` variable.
  ///
  /// The function is asynchronous and uses the `await` keyword to wait for the
  /// database operation to complete.
  ///
  /// - Parameter uid: The unique identifier of the user whose details are to be fetched.
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
      overlayWidgetBuilder: (_) {
        return Center(
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
