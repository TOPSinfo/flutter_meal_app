import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meal_app/main.dart';
import '../Authentication/personal_detail.dart';
import '../Authentication/phone.dart';
import '../MyOrder/order_list.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:store_redirect/store_redirect.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // RATE APP DIALOG
  final _dialog = RatingDialog(
    title: const Text(
      'Rate Us On App Store',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16),
    ),
    message: const Text(
      'Select Number of Stars 1 - 5 to Rate This App',
      style: TextStyle(fontSize: 12),
    ),
    image: Image.asset(
      'assets/images/myMealLogo.png',
      width: 80,
      height: 80,
    ),
    submitButtonTextStyle: const TextStyle(fontSize: 14),
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
      if (response.rating < 3.0) {
        // send their comments to your email or anywhere you wish
        // ask the user to contact you instead of leaving a bad review
      } else {
        //go to app store
        StoreRedirect.redirect(
            androidAppId: 'com.donation.basket',
            iOSAppId: 'com.donationbasket.donations');
      }
    },
  );

  // SIGN OUT FUNCTION
  // REDIRECT TO PHONE SCREEN AFTER SIGN OUT
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

  // LOGOUT CONFIRMATION DIALOG
  showLogoutAlertDialog(BuildContext context) {
    TextStyle style = TextStyle(
      color: Theme.of(context).colorScheme.onBackground,
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
                    // RateUsOnStore(androidPackageName: "com.donation.basket", appstoreAppId: "6448574083").launch();
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
