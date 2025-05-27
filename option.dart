import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Option extends StatelessWidget {
  final Function(XFile xfile) onImagePicked;

  const Option({super.key, required this.onImagePicked});

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    final XFile? image = await ImagePicker().pickImage(source: source);
    if (image != null) {
      Navigator.of(context).pop();
      onImagePicked(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Choose Image Source")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera, context),
              icon: Icon(Icons.camera_alt),
              label: Text("Take a Photo"),
              style: ElevatedButton.styleFrom(minimumSize: Size(200, 50)),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery, context),
              icon: Icon(Icons.photo_library),
              label: Text("Choose from Gallery"),
              style: ElevatedButton.styleFrom(minimumSize: Size(200, 50)),
            ),
          ],
        ),
      ),
    );
  }
}
