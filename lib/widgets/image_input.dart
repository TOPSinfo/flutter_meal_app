import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageInput extends StatefulWidget {
  const ImageInput(
      {super.key, required this.selectedImage, required this.onPickeImage});

  final void Function(File image) onPickeImage;
  final String? selectedImage;

  @override
  State<ImageInput> createState() {
    return _ImageInputState();
  }
}

class _ImageInputState extends State<ImageInput> {
  File? _selectedImage;
  ImageSource _imageSource = ImageSource.camera;

  /// Displays a Cupertino-style action sheet with options to take a picture
  /// using the camera or select a picture from the photo gallery.
  ///
  /// The action sheet includes two main actions:
  /// - "Camera": Sets the image source to the camera, takes a picture, and
  ///   then closes the action sheet.
  /// - "Photo Gallery": Sets the image source to the photo gallery, takes a
  ///   picture, and then closes the action sheet.
  ///
  /// There is also a cancel button that closes the action sheet without
  /// performing any action.
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

  // DID UPDATE WIDGET
  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  // INIT STATE
  @override
  void initState() {
    super.initState();
  }

  /// Takes a picture using the device's camera or selects an image from the gallery,
  /// then updates the state with the selected image and calls the `onPickImage`
  /// callback with the selected image.
  ///
  /// This method uses the `ImagePicker` package to handle image selection. The
  /// image is resized to a maximum width of 600 pixels.
  ///
  /// If no image is selected, the method returns early without updating the state
  /// or calling the callback.
  ///
  /// The selected image is stored in the `_selectedImage` variable and passed to
  /// the `onPickImage` callback provided by the parent widget.
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

    widget.onPickeImage(_selectedImage!);
  }

  // UI
  @override
  Widget build(BuildContext context) {
    Widget content = TextButton.icon(
      onPressed: _showActionSheet,
      icon: Icon(
        Icons.camera,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      label: Text(
        'Take a Meal Image',
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
      ),
    );

    if (_selectedImage != null) {
      content = GestureDetector(
        onTap: _showActionSheet,
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (widget.selectedImage != null) {
      content = GestureDetector(
        onTap: _showActionSheet,
        child: Image.network(
          widget.selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      ),
      child: content,
    );
  }
}
