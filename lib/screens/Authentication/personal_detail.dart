import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../bottom_tabbar.dart';
import '../../helper/app_theme.dart';
import '../../helper/constant.dart';
import '../../helper/extension.dart';
import '../../models/user.dart';

class PersonalDetailScreen extends StatefulWidget {
  const PersonalDetailScreen({
    super.key,
    required this.isCameAfterOTPVerify,
  });
  final bool isCameAfterOTPVerify;

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  final _scrollKey = GlobalKey();
  File? _selectedImage;
  ImageSource _imageSource = ImageSource.camera;
  bool isEditProfileTapped = false;
  String navigationTitle = "Personal Details";
  CurrentUser? objLoggedInUser;

  // HIDE LOADER
  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  // SHOW LOADER
  void _showProgress() {
    context.loaderOverlay.show();
  }

  // OPEN IMAGE PICKER
  /// Picks an image using the device's camera or gallery, and updates the state
  /// with the selected image file.
  ///
  /// This method uses the `ImagePicker` package to allow the user to select an
  /// image from their device. The selected image is then stored in the `_selectedImage`
  /// variable as a `File` object.
  ///
  /// If no image is selected, the method returns early without updating the state.
  ///
  /// Note: Ensure that the `_imageSource` variable is properly set to either
  /// `ImageSource.camera` or `ImageSource.gallery` before calling this method.
  void _takePicture() async {
    final imagePicker = ImagePicker();
    final pickedImage =
        await imagePicker.pickImage(source: _imageSource, maxWidth: 600);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      _selectedImage = File(pickedImage.path);
    });
  }

  // IMAGE PICKER BOTTOM SHEET PRESENT
  /// Displays a Cupertino-style action sheet with options to take a picture
  /// using the camera or select a photo from the gallery.
  ///
  /// The action sheet includes two actions:
  /// - "Camera": Sets the image source to the camera and calls `_takePicture()`.
  /// - "Photo Gallery": Sets the image source to the gallery and calls `_takePicture()`.
  ///
  /// There is also a cancel button to dismiss the action sheet without taking any action.
  void _showActionSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              _imageSource = ImageSource.camera;
              _takePicture();
              Navigator.pop(context);
            },
            child: Text(
              'Camera',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              _imageSource = ImageSource.gallery;
              _takePicture();
              Navigator.pop(context);
            },
            child: Text(
              'Photo Gallery',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Cancel',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // DISPOSE TEXT EDITING CONTROLLER ON SCREEN DESTROY
  @override
  void dispose() {
    super.dispose();

    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  // INIT STATE
  @override
  void initState() {
    super.initState();
    phoneController.text = fAuth.currentUser?.phoneNumber ?? "";
    if (widget.isCameAfterOTPVerify) {
      navigationTitle = "Personal Details";
    } else {
      navigationTitle = "Profile";
      _showProgress();
      _getMyProfile();
    }
  }

  /// Fetches the current user's profile from the Firestore database.
  ///
  /// This asynchronous function retrieves the user ID from the Firebase
  /// authentication instance. It then fetches the user's document from
  /// the 'users' collection in Firestore. If the document exists, it
  /// converts the data to a `CurrentUser` object and updates the
  /// `objLoggedInUser` and `currentUser` variables.
  ///
  /// If the user has navigated to this screen after OTP verification,
  /// it navigates to the `BottomTabBar` screen and removes all previous
  /// routes. Otherwise, it sets up the user details.
  ///
  /// The function also hides the progress indicator once the data is
  /// fetched and processed.
  void _getMyProfile() async {
    var uid = fAuth.currentUser?.uid ?? "";

    var snap = await db.collection('users').doc(uid).get();

    var data = snap.data();
    if (data != null) {
      var userData = CurrentUser.fromMap(data);
      objLoggedInUser = userData;
      currentUser = userData;
      _hideProgress();
      if (widget.isCameAfterOTPVerify) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const BottomTabBar(),
            ),
            (route) => false);
      } else {
        _setupUserDetail(userData);
      }
    }
  }

  /// Uploads the selected user image to Firebase Storage and returns the download URL.
  ///
  /// The image is uploaded to the path 'images/users/[docID]'.
  ///
  /// [docID] is the document ID used to uniquely identify the image in the storage.
  ///
  /// Returns a [Future<String>] that completes with the download URL of the uploaded image.
  Future<String> uploadUserImageToStorage(String docID) async {
    Reference reference = storageRef.child('images/users').child(docID);
    UploadTask uploadTask = reference.putFile(_selectedImage!);

    String url = "";
    await uploadTask.whenComplete(() async {
      url = await uploadTask.snapshot.ref.getDownloadURL();
    });

    return url;
  }

  /// Updates the user profile with the provided details.
  ///
  /// This method performs the following steps:
  /// 1. Retrieves the current user's UID.
  /// 2. Validates that the first name, last name, and email fields are not empty.
  /// 3. Unfocuses any active text fields and shows a progress indicator.
  /// 4. If a new profile image is selected, uploads it to storage and retrieves the URL.
  /// 5. Constructs a `CurrentUser` object with the provided details.
  /// 6. If editing an existing profile, updates the user document in the database.
  /// 7. If creating a new profile, sets the user document in the database.
  /// 8. Hides the progress indicator and fetches the updated profile.
  ///
  /// Parameters:
  /// - `context`: The build context of the widget calling this method.
  ///
  /// Returns:
  /// A `Future<void>` indicating the completion of the profile update operation.
  Future<void> _updateProfile(BuildContext context) async {
    var uid = fAuth.currentUser?.uid ?? "";
    if (firstNameController.text.isEmpty) {
      showToastMessage('Please enter your first name.', context);
      return;
    } else if (lastNameController.text.isEmpty) {
      showToastMessage('Please enter your last name.', context);
      return;
    } else if (emailController.text.isEmpty) {
      showToastMessage('Please enter your email address.', context);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _showProgress();

    String profileURL = "";
    if (_selectedImage != null) {
      profileURL = await uploadUserImageToStorage(uid);
      if (kDebugMode) {
        print(profileURL);
      }
    } else {
      profileURL = objLoggedInUser?.imageUrl ?? "";
    }

    var user = CurrentUser(
        userId: uid,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        imageUrl: profileURL,
        isAdmin: currentUser?.isAdmin == true ? true : false);

    // GET CURRENT LOGGED IN USER DETAIL AFTER ADD/UPDATE THE USER
    if (isEditProfileTapped) {
      _hideProgress();
      db.collection('users').doc(uid).update(user.toMap()).then((value) {
        _getMyProfile();
      });
    } else {
      db.collection('users').doc(uid).set(user.toMap()).then((value) {
        _getMyProfile();
      });
    }
  }

  /// Sets up the user details in the respective text controllers.
  ///
  /// This method takes a [CurrentUser] object and assigns its properties
  /// (first name, last name, email, and phone) to the corresponding text
  /// controllers. The state is updated to reflect these changes.
  ///
  /// Parameters:
  /// - [user]: The [CurrentUser] object containing the user's details.
  void _setupUserDetail(CurrentUser user) {
    setState(() {
      firstNameController.text = user.firstName;
      lastNameController.text = user.lastName;
      emailController.text = user.email;
      phoneController.text = user.phone;
    });
  }

  // PROFILE UI
  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration = BoxDecoration(
      border: Border.all(
        width: 1,
        color: HexColor.fromHex(greenColor).withOpacity(0.2),
      ),
      borderRadius: BorderRadius.circular(10),
    );

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(navigationTitle),
        actions: [
          if (!widget.isCameAfterOTPVerify)
            IconButton(
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () {
                setState(() {
                  isEditProfileTapped = !isEditProfileTapped;

                  if (isEditProfileTapped) {
                    navigationTitle = "Update Profile";
                  } else {
                    navigationTitle = "Profile";
                  }
                });
              },
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: _scrollKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                        child: _selectedImage == null
                            ? (objLoggedInUser?.imageUrl ?? "").isEmpty
                                ? null
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(70),
                                    child: Image.network(
                                      objLoggedInUser?.imageUrl ?? "",
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(70),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                      ),
                      if (isEditProfileTapped || widget.isCameAfterOTPVerify)
                        Positioned(
                          bottom: 5,
                          right: 1,
                          child: GestureDetector(
                            onTap: () {
                              _showActionSheet();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 3,
                                    color: Colors.white,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(
                                      50,
                                    ),
                                  ),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      offset: const Offset(2, 4),
                                      color: Colors.black.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 3,
                                    ),
                                  ]),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.add_a_photo,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Container(
                  decoration: decoration,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      readOnly: widget.isCameAfterOTPVerify
                          ? false
                          : isEditProfileTapped
                              ? false
                              : true,
                      controller: firstNameController,
                      keyboardType: TextInputType.name,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      maxLength: 50,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "First name",
                        counterText: "",
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    decoration: decoration,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextFormField(
                        readOnly: widget.isCameAfterOTPVerify
                            ? false
                            : isEditProfileTapped
                                ? false
                                : true,
                        controller: lastNameController,
                        keyboardType: TextInputType.name,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        maxLength: 50,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Last name",
                          counterText: "",
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: decoration,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      readOnly: widget.isCameAfterOTPVerify
                          ? false
                          : isEditProfileTapped
                              ? false
                              : true,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Email",
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Container(
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
                        child: Text(
                          "+91",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
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
                          readOnly: true,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                          controller: phoneController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Phone",
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                if (isEditProfileTapped || widget.isCameAfterOTPVerify)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        _updateProfile(context);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.teal,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        widget.isCameAfterOTPVerify ? 'SAVE' : 'UPDATE',
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
      ),
    );
  }
}
