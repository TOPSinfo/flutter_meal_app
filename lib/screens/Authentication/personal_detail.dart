import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../../bottom_tabbar.dart';
import '../../models/user.dart';

import '../../main.dart';
import 'phone.dart';

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

  void _hideProgress() {
    context.loaderOverlay.hide();
  }

  void _showProgress() {
    context.loaderOverlay.show();
  }

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
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onBackground),
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
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onBackground),
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

  @override
  void dispose() {
    super.dispose();

    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  @override
  void initState() {
    super.initState();
    phoneController.text = auth.currentUser?.phoneNumber ?? "";
    if (widget.isCameAfterOTPVerify) {
      navigationTitle = "Personal Details";
    } else {
      navigationTitle = "Profile";
      _showProgress();
      _getMyProfile();
    }
  }

  void _getMyProfile() async {
    var uid = auth.currentUser?.uid ?? "";

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

  Future<String> uploadMealImageToStorage(String docID) async {
    Reference reference = storageRef.child('images/users').child(docID);
    UploadTask uploadTask = reference.putFile(_selectedImage!);

    String url = "";
    await uploadTask.whenComplete(() async {
      url = await uploadTask.snapshot.ref.getDownloadURL();
    });

    return url;
  }

  Future<void> _postProfile(BuildContext context) async {
    var uid = auth.currentUser?.uid ?? "";
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
      profileURL = await uploadMealImageToStorage(uid);
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
        imageUrl: profileURL, isAdmin: currentUser?.isAdmin == true ? true:false);

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

  void _setupUserDetail(CurrentUser user) {
    setState(() {
      firstNameController.text = user.firstName;
      lastNameController.text = user.lastName;
      emailController.text = user.email;
      phoneController.text = user.phone;
    });
  }

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
        title: Text(navigationTitle),
        actions: [
          if (!widget.isCameAfterOTPVerify)
            IconButton(
              color: Theme.of(context).colorScheme.onBackground,
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
                color: Theme.of(context).colorScheme.onBackground,
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
                            .onBackground
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
                          color: Theme.of(context).colorScheme.onBackground),
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
                            color: Theme.of(context).colorScheme.onBackground),
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
                          color: Theme.of(context).colorScheme.onBackground),
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
                              color:
                                  Theme.of(context).colorScheme.onBackground),
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
                              color:
                                  Theme.of(context).colorScheme.onBackground),
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
                        _postProfile(context);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.teal,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        widget.isCameAfterOTPVerify ? 'SAVE' : 'UPDATE',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onBackground,
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
