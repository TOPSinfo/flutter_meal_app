import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../helper/app_theme.dart';
import '../../helper/constant.dart';
import '../../helper/extension.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  TextEditingController countryController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  String phone = "";

  // INIT STATE
  @override
  void initState() {
    countryController.text = "+91";
    super.initState();
  }

  // HIDE LOADER & NAVIGATE TO OTP VERIFICATION SCREEN
  void _hideProgress(bool isWantToNavigate, String verificationId) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.loaderOverlay.hide();
      }
      if (isWantToNavigate) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => OTPScreen("",
                phone: countryController.text + phone,
                verificationId: verificationId),
          ),
        );
      }
    });
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  /// Verifies the phone number entered by the user.
  ///
  /// This function performs the following steps:
  /// 1. Shows a progress indicator.
  /// 2. Validates the mobile number.
  /// 3. If the mobile number is invalid, shows a toast message and returns.
  /// 4. If the mobile number is valid, initiates the Firebase phone number verification process.
  ///
  /// The Firebase phone number verification process involves:
  /// - `verificationCompleted`: A callback triggered when the phone number is automatically verified.
  /// - `verificationFailed`: A callback triggered when the verification process fails. Hides the progress indicator and logs the error message if in debug mode.
  /// - `codeSent`: A callback triggered when the verification code is sent to the user's phone. Hides the progress indicator and passes the verification ID.
  /// - `codeAutoRetrievalTimeout`: A callback triggered when the automatic code retrieval times out. Hides the progress indicator.
  void _verifyPhone() async {
    _showProgress();
    var isValidmobile = validateMobile(phone);

    if (isValidmobile != null) {
      showToastMessage(isValidmobile, context);
      return;
    }

    // FIREBASE VERIFY PHONE NUMBER FUNCTION
    await fAuth.verifyPhoneNumber(
      phoneNumber: countryController.text + phone,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        if (kDebugMode) {
          print(e.message);
        }
        _hideProgress(false, "");
      },
      codeSent: (String verificationId, int? resendToken) {
        _hideProgress(true, verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _hideProgress(false, "");
      },
    );
  }

  /// Validates a mobile number to ensure it is exactly 10 digits long.
  ///
  /// Returns a string error message if the mobile number is not 10 digits long,
  /// otherwise returns null indicating the mobile number is valid.
  ///
  /// - Parameter value: The mobile number to validate.
  /// - Returns: A string error message if the mobile number is invalid, otherwise null.
  String? validateMobile(String value) {
    if (value.length != 10) {
      return 'Mobile Number must be of 10 digit';
    } else {
      return null;
    }
  }

  // PHONE NUMBER UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(left: 25, right: 25),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/img1.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(
                height: 25,
              ),
              Text(
                "Enter your Phone Number",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(
                height: 5,
              ),
              RichText(
                text: TextSpan(
                  text: 'We will send you a ',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '6 digit',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextSpan(
                      text: ' verification code',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                height: 55,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: HexColor.fromHex(greenColor).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: 40,
                      child: TextField(
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        controller: countryController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Text(
                      "|",
                      style: TextStyle(
                        fontSize: 33,
                        color: HexColor.fromHex(greenColor).withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        controller: phoneController,
                        maxLength: 10,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9]'),
                          ),
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          phone = value;
                        },
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Phone",
                          counterText: "",
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                child: ElevatedButton(
                  onPressed: () {
                    _verifyPhone();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(
                    'GENERATE OTP',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
