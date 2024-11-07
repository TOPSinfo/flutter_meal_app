import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../helper/constant.dart';
import '../Authentication/personal_detail.dart';
import '../Authentication/phone.dart';
import '../Order/order_list.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:store_redirect/store_redirect.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late RatingDialog _dialog;

  @override
  void initState() {
    super.initState();
    setupRatingDialog();
  }

  /// Sets up a rating dialog that prompts the user to rate the app on the App Store.
  ///
  /// The dialog includes a title, a message, an image, and a submit button. The user can select
  /// a rating from 1 to 5 stars. If the user cancels the dialog, a message is printed to the console
  /// in debug mode. If the user submits a rating, the rating and any comment are printed to the console
  /// in debug mode, and the user is redirected to the App Store page for the app.
  ///
  /// The dialog is shown after the current frame is rendered.
  void setupRatingDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _dialog = RatingDialog(
        title: Text(
          'Rate Us On App Store',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
        ),
        message: Text(
          'Select Number of Stars 1 - 5 to Rate This App',
          style: TextStyle(
              fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
        ),
        image: Image.asset(
          'assets/images/myMealLogo.png',
          width: 80,
          height: 80,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        submitButtonTextStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        submitButtonText: 'Submit',
        showCloseButton: true,
        enableComment: false,
        starSize: 30.0,
        onCancelled: () {
          if (kDebugMode) {
            print('cancelled');
          }
        },
        onSubmitted: (response) {
          if (kDebugMode) {
            print('rating: ${response.rating}, comment: ${response.comment}');
          }
          StoreRedirect.redirect(
              androidAppId: 'com.example.food_app',
              iOSAppId: 'com.example.foodApp');
        },
      );
    });
  }

  /// Signs out the current user from Firebase Authentication.
  ///
  /// This method signs out the current user using FirebaseAuth's `signOut` method.
  /// After signing out, it sets the `currentUser` to null and navigates to the
  /// `PhoneScreen`, removing all previous routes.
  ///
  /// If the widget is not mounted, the method returns early.
  ///
  /// Returns a [Future] that completes when the sign-out operation is finished.
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    currentUser = null;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneScreen(),
        ),
        (route) => false);
  }

  /// Displays a logout confirmation dialog.
  ///
  /// This function shows an alert dialog with a message asking the user if they
  /// are sure they want to logout. The dialog contains two buttons: "No" and "Yes".
  ///
  /// - The "No" button closes the dialog without performing any action.
  /// - The "Yes" button closes the dialog and calls the `_signOut` method to log the user out.
  ///
  /// The appearance of the text and buttons is styled using the current theme's
  /// color scheme.
  ///
  /// Parameters:
  /// - `context`: The BuildContext in which the dialog is displayed.
  showLogoutAlertDialog(BuildContext context) {
    TextStyle style = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
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
        _signOut();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        "Logout",
        style: buttonStyle,
      ),
      content: Text(
        "Are you sure you want to logout?",
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
        title: const Text("Settings"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const PersonalDetailScreen(
                            isCameAfterOTPVerify: false),
                      ),
                    );
                  },
                  child: const ListTile(
                    contentPadding: EdgeInsets.only(left: 0.0),
                    title: Text('Profile'),
                  ),
                ),
                Visibility(
                  visible:
                      (currentUser != null && currentUser?.isAdmin == false),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const OrderList(),
                        ),
                      );
                    },
                    child: const ListTile(
                      contentPadding: EdgeInsets.only(left: 0.0),
                      title: Text('My Orders'),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _dialog,
                    );
                  },
                  child: const ListTile(
                    contentPadding: EdgeInsets.only(left: 0.0),
                    title: Text('Rate App'),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showLogoutAlertDialog(context);
                  },
                  child: const ListTile(
                    contentPadding: EdgeInsets.only(left: 0.0),
                    title: Text('Logout'),
                  ),
                ),
              ],
            ).toList(),
          ),
        ),
      ),
    );
  }
}
