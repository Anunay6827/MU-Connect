import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'user_data.dart';
import 'main_navigation.dart';
import 'messages_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateScreenState createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  File? _selectedImage;
  final int _maxChars = 280;
  final int _groupNameMaxChars = 48;
  final int _groupDescriptionMaxChars = 120;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitPost(BuildContext context) async {
    final groupName = _groupNameController.text.trim();
    final groupDescription = _groupDescriptionController.text.trim();

    if (groupName.isEmpty || groupDescription.isEmpty || groupName.length > _groupNameMaxChars || groupDescription.length > _groupDescriptionMaxChars) {
      return; // Return if fields are invalid
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_create'),
      );

      // Add the group name, description, and author
      request.fields['name'] = groupName;
      request.fields['bio'] = groupDescription;
      request.fields['user_id'] = UserData.userId.toString();

      // Add the image if selected
      if (_selectedImage != null) {
        try {
          final mimeTypeData = lookupMimeType(_selectedImage!.path)?.split('/');
          final mediaType = (mimeTypeData != null && mimeTypeData.length == 2)
              ? MediaType(mimeTypeData[0], mimeTypeData[1])
              : MediaType('image', 'jpeg');

          request.files.add(await http.MultipartFile.fromPath(
            'picture',
            _selectedImage!.path,
            contentType: mediaType,
          ));
          print("Image file added to request.");
        } catch (e) {
          print("Error adding image to request: $e");
        }
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        _groupNameController.clear();
        _groupDescriptionController.clear();
        _removeImage();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  MainNavigation(initialTab: 1)),
        );
        print("Group created successfully.");
      } else {
        print("Failed to create group. Status Code: ${response.statusCode}");
        print("Response: ${await response.stream.bytesToString()}");
      }
    } catch (e) {
      print("Error creating group: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPostEnabled = _groupNameController.text.trim().isNotEmpty || _groupDescriptionController.text.trim().isNotEmpty || _selectedImage != null;
    final groupNameLength = _groupNameController.text.length;
    final groupDescriptionLength = _groupDescriptionController.text.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).iconTheme,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainNavigation(initialTab: 1)),
            );
          },
        ),
        title: Text(
          "Create Group",
          style: Theme.of(context).appBarTheme.titleTextStyle ??
              TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.image, color: Theme.of(context).iconTheme.color),
            onPressed: _pickImage,
            tooltip: "Add Image",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Group Name Field
              TextField(
                controller: _groupNameController,
                maxLength: _groupNameMaxChars,
                maxLines: 1,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Group Name",
                  hintText: "Enter the group name",
                  hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade400,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _groupDescriptionController,
                maxLength: _groupDescriptionMaxChars,
                minLines: 3,
                maxLines: null,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Group Description",
                  hintText: "Enter the group description",
                  hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade400,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: isPostEnabled ? () => _submitPost(context) : null,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Create Group", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}