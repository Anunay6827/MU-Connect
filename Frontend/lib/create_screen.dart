import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'user_data.dart';
import 'main_navigation.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  _CreateScreenState createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  final int _maxChars = 280;

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
    final text = _postController.text.trim();
    if (text.isEmpty || text.length > _maxChars) {
      return; // Return if text is invalid
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/blogs_create'),
      );

      request.fields['author'] = UserData.userId.toString();
      request.fields['content'] = text;

      if (_selectedImage != null) {
        try {
          final mimeTypeData = lookupMimeType(_selectedImage!.path)?.split('/');
          final mediaType = (mimeTypeData != null && mimeTypeData.length == 2)
              ? MediaType(mimeTypeData[0], mimeTypeData[1])
              : MediaType('image', 'jpeg');

          request.files.add(await http.MultipartFile.fromPath(
            'image',
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
        _postController.clear();
        _removeImage();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  MainNavigation()),
        );
        print("Post submitted successfully.");
      } else {
        print("Failed to submit post. Status Code: ${response.statusCode}");
        print("Response: ${await response.stream.bytesToString()}");
      }
    } catch (e) {
      print("Error submitting post: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPostEnabled = _postController.text.trim().isNotEmpty || _selectedImage != null;
    final textLength = _postController.text.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).iconTheme,
        title: Text(
          "Create Post",
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
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  TextField(
                    controller: _postController,
                    minLines: 3,
                    maxLines: null,
                    maxLength: _maxChars,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
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
                      contentPadding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
                      counterText: '',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 8),
                    child: Text(
                      "$textLength/$_maxChars",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
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
                onPressed: isPostEnabled ? () => _submitPost(context) : null, // Pass context here
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Post", style: TextStyle(color: Colors.white)),
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