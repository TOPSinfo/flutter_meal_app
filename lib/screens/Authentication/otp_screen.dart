import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../bottom_tabbar.dart';
import '../../main.dart';
import '../Authentication/personal_detail.dart';
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
  void _hideProgress() {
    Future.delayed(const Duration(seconds: 2), () {
      context.loaderOverlay.hide();
    });
  }

  void _showProgress() {
    context.loaderOverlay.show();
  }

  void _singIn(BuildContext context) async {
    if (widget.smsCode.isEmpty || widget.smsCode.length < 6) {
      showToastMessage("Please enter valid code", context);
      return;
    }

    _showProgress();
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId, smsCode: widget.smsCode);
    try {
      var result = await auth.signInWithCredential(credential);
      if (result.user?.uid != null) {
        var snap = await db
            .collection('users')
            .where('userId', isEqualTo: result.user?.uid ?? "")
            .get();

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

  void _resendCode(BuildContext context) async {
    _showProgress();
    await auth.verifyPhoneNumber(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
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
