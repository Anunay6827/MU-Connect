import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'user_data.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String username;
  final String bio;
  final String password;
  final String profile_picture;

  EditProfileScreen({
    required this.name,
    required this.username,
    required this.bio,
    required this.password,
    required this.profile_picture,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _passwordController;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
    _passwordController = TextEditingController(text: widget.password);

    if (widget.profile_picture.isNotEmpty && widget.profile_picture.startsWith('http')) {
      _selectedImage = null;
    } else {
      _selectedImage = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String? mimeType = lookupMimeType(pickedFile.path);

      if (mimeType != null &&
          (mimeType == 'image/jpeg' ||
              mimeType == 'image/png' ||
              mimeType == 'image/jpg')) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a JPG, JPEG, or PNG image.')));
      }
    }
  }

  Future<void> _saveProfile() async {
    Map<String, dynamic> updatedFields = {
      "user_id": UserData.userId.toString(),
    };

    if (_nameController.text != widget.name) {
      updatedFields["name"] = _nameController.text;
    }
    if (_bioController.text != widget.bio) {
      updatedFields["bio"] = _bioController.text;
    }
    if (_passwordController.text != widget.password &&
        _passwordController.text.isNotEmpty) {
      updatedFields["password"] = _passwordController.text;
    }

    var uri = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/user_edit');
    var request = http.MultipartRequest('POST', uri);

    updatedFields.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (_selectedImage != null) {
      try {
        final mimeTypeData = lookupMimeType(_selectedImage!.path)?.split('/');
        final mediaType = (mimeTypeData != null && mimeTypeData.length == 2)
            ? MediaType(mimeTypeData[0], mimeTypeData[1])
            : MediaType('image', 'jpeg'); // fallback

        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          _selectedImage!.path,
          contentType: mediaType,
        ));
        print("Image file added to request.");
      } catch (e) {
        print("Error adding image to request: $e");
      }
    }

    try {
      print("Sending request to: $uri");
      final response = await request.send();
      print("Response status code: ${response.statusCode}");

      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        print("Profile updated successfully.");
        Navigator.pop(context);
      } else {
        print('Server responded with error: $responseBody');
      }
    } catch (e) {
      print('Error while sending request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : widget.profile_picture.startsWith('http')
                      ? NetworkImage(widget.profile_picture)
                      : null,
                  child: (_selectedImage == null &&
                      !widget.profile_picture.startsWith('http'))
                      ? Icon(Icons.camera_alt, size: 30, color: Colors.grey[700])
                      : null,
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: "Bio"),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }
}