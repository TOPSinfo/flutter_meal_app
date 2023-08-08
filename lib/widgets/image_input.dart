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
  // This shows a CupertinoModalPopup which hosts a CupertinoActionSheet.
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
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
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

    widget.onPickeImage(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = TextButton.icon(
      onPressed: _showActionSheet,
      icon: Icon(
        Icons.camera,
        color: Theme.of(context).colorScheme.onBackground,
      ),
      label: Text(
        'Take a Meal Image',
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
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
        // border: Border.all(
        //   width: 1,
        //   color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        // ),
      ),
      child: content,
    );
  }
}
