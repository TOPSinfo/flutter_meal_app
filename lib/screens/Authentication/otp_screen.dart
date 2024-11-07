import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../Authentication/personal_detail.dart';
import '../../bottom_tabbar.dart';
import '../../helper/constant.dart';
import '../../models/user.dart';

// ignore: must_be_immutable
class OTPScreen extends StatefulWidget {
  OTPScreen(this.smsCode,
      {super.key, required this.phone, required this.verificationId});
  final String phone;
  final String verificationId;
  String smsCode;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  // HIDE LOADER
  void _hideProgress() {
    Future.delayed(const Duration(seconds: 2), () {
      context.loaderOverlay.hide();
    });
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  /// Handles the sign-in process using OTP validation and Firebase authentication.
  ///
  /// This function performs the following steps:
  /// 1. Validates the OTP code entered by the user.
  /// 2. Shows a progress indicator.
  /// 3. Creates a phone authentication credential using the verification ID and SMS code.
  /// 4. Attempts to sign in with the given credentials.
  /// 5. Checks if the user ID exists in the 'users' collection in Firestore.
  ///    - If the user ID exists, redirects the user to the dashboard.
  ///    - If the user ID does not exist, redirects the user to the personal detail screen.
  /// 6. Handles any Firebase authentication exceptions and displays an error message if needed.
  ///
  /// Parameters:
  /// - `context`: The BuildContext of the current widget.
  // OTP VALIDATION & FIREBASE AUTHENTICATION
  void _singIn(BuildContext context) async {
    if (widget.smsCode.isEmpty || widget.smsCode.length < 6) {
      showToastMessage("Please enter valid code", context);
      return;
    }

    _showProgress();
    // CREATE PHONE AUTH PROVIDER CREDENTIAL USING VERIFICATION-ID & SMS CODE
    // VERIFICATION ID WHICH WE GET FROM VERIFY PHONE NUMBER FROM PREVIOUS SCREEN
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId, smsCode: widget.smsCode);
    try {
      // SIGN IN WITH THE GIVEN CREDENTIALS
      var result = await fAuth.signInWithCredential(credential);
      if (result.user?.uid != null) {
        var snap = await db
            .collection('users')
            .where('userId', isEqualTo: result.user?.uid ?? "")
            .get();

        // CHECK USER ID EXIST IN USERS TABLE OR NOT
        // IF USER ID EXIST, IT MEANS USER IS ALREADY REGISTERED WITH US. REDIRECT USER TO DASHBOARD
        // IF USER ID NOT EXIST, WE ARE REDIRECTING USER TO THE PERSONAL DETAIL SCREEN WHERE USER CAN FILL PERSONAL INFORMATION
        if (snap.docs.isNotEmpty) {
          currentUser = CurrentUser.fromMap(snap.docs.first.data());
          if (!context.mounted) return;

          Future.delayed(const Duration(seconds: 2), () {
            context.loaderOverlay.hide();
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const BottomTabBar(),
                ),
                (route) => false);
          });
        } else {
          if (!context.mounted) return;
          Future.delayed(const Duration(seconds: 2), () {
            context.loaderOverlay.hide();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) =>
                    const PersonalDetailScreen(isCameAfterOTPVerify: true),
              ),
            );
          });
        }
      }
    } on FirebaseAuthException catch (error) {
      _hideProgress();
      if (!context.mounted) return;
      showToastMessage(error.message ?? "Something went wrong", context);
      if (kDebugMode) {
        print(error.message);
      }
    }
  }

  /// Resends the OTP code to the user's phone number.
  ///
  /// This method triggers the phone number verification process again,
  /// showing a progress indicator while the verification is in progress.
  ///
  /// The verification process involves the following steps:
  /// - `verificationCompleted`: Called when the verification is completed successfully.
  /// - `verificationFailed`: Called when the verification fails. Hides the progress indicator.
  /// - `codeSent`: Called when the OTP code is sent successfully. Hides the progress indicator and shows a toast message.
  /// - `codeAutoRetrievalTimeout`: Called when the auto-retrieval of the OTP code times out. Hides the progress indicator.
  ///
  /// Parameters:
  /// - `context`: The BuildContext in which the method is called.
  void _resendCode(BuildContext context) async {
    _showProgress();
    await fAuth.verifyPhoneNumber(
      phoneNumber: widget.phone,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        _hideProgress();
      },
      codeSent: (String verificationId, int? resendToken) {
        _hideProgress();
        verificationId = verificationId;
        showToastMessage('Code sent again', context);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _hideProgress();
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
          title: const Text('')),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "CODE",
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 80.0,
                  color: Colors.white),
            ),
            Text("Verification".toUpperCase(),
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.normal,
                    fontSize: 20,
                    color: Colors.white)),
            const SizedBox(height: 40.0),
            Text("Enter verification code that we have sent to ${widget.phone}",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.normal,
                    fontSize: 20,
                    color: Colors.white)),
            const SizedBox(height: 20.0),
            OtpTextField(
                obscureText: true,
                mainAxisAlignment: MainAxisAlignment.center,
                numberOfFields: 6,
                textStyle: GoogleFonts.montserrat(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    color: Colors.white),
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
                onCodeChanged: (String code) {
                  widget.smsCode = code;
                  if (kDebugMode) {
                    print("OTP is => $code");
                  }
                },
                onSubmit: (code) {
                  widget.smsCode = code;
                  if (kDebugMode) {
                    print("OTP is => $code");
                  }
                }),
            const SizedBox(height: 20.0),
            SizedBox(
              // width: double.infinity,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal,
                  ),
                  onPressed: () {
                    _singIn(context);
                  },
                  child: Text(
                    'Verify Code',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  )),
            ),
            SizedBox(
              // width: double.infinity,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () {
                    _resendCode(context);
                  },
                  child: Text(
                    'Re-send code',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
