import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'user_data.dart';
import 'profile_other_screen.dart';
import 'main_navigation.dart';

class GroupViewScreen extends StatefulWidget {
  final int id;

  GroupViewScreen({required this.id});

  @override
  _GroupViewScreenState createState() => _GroupViewScreenState();
}

class _GroupViewScreenState extends State<GroupViewScreen> {
  String groupName = '';
  String groupDescription = '';
  String? groupPicture;
  DateTime? createdAt;
  List<dynamic> members = [];
  bool isLoading = true;
  bool isEditing = false;
  bool userIsAdmin = false;
  File? newPicture;

  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
  }

  Future<void> fetchGroupDetails() async {
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_details');
    final body = jsonEncode({
      "user_id": UserData.userId,
      "group_id": widget.id,
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final group = data['group'];
        final List<dynamic> fetchedMembers = data['members'];
        final bool isAdmin = data['user_is_admin'] ?? false;

        setState(() {
          groupName = group['name'] ?? '';
          groupDescription = group['bio'] ?? '';
          groupPicture = group['picture'];
          createdAt = DateTime.tryParse(group['created_at'] ?? '');
          members = fetchedMembers;
          userIsAdmin = isAdmin;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load group details");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day}${_getDaySuffix(date.day)} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return "th";
    switch (day % 10) {
      case 1: return "st";
      case 2: return "nd";
      case 3: return "rd";
      default: return "th";
    }
  }

  String _getMonthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  }

  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        newPicture = File(pickedFile.path);
      });
    }
  }

  Future<void> saveGroupDetails() async {
    if (groupNameController.text.isEmpty || groupDescriptionController.text.isEmpty) {
      return;
    }

    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_edit');
    final request = http.MultipartRequest('POST', url)
      ..fields['group_id'] = widget.id.toString()
      ..fields['name'] = groupNameController.text
      ..fields['bio'] = groupDescriptionController.text;

    if (newPicture != null) {
      final mimeType = lookupMimeType(newPicture!.path);
      final mediaType = mimeType != null ? MediaType.parse(mimeType) : MediaType('application', 'octet-stream');

      final imageFile = await http.MultipartFile.fromPath(
        'picture',
        newPicture!.path,
        contentType: mediaType,
      );
      request.files.add(imageFile);
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          groupName = groupNameController.text;
          groupDescription = groupDescriptionController.text;
          isEditing = false;
          newPicture = null;
        });
        fetchGroupDetails();
      } else {
        throw Exception("Failed to save group details");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName.isEmpty ? 'Loading...' : groupName),
        actions: [
          if (!isLoading && !isEditing)
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: groupName,
                  applicationVersion: "Group Info",
                  children: [Text(groupDescription)],
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildHeader(),
          const Divider(),
          Expanded(child: _buildMemberList()),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _buildGroupActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final memberCount = members.length;
    final createdStr = createdAt != null ? _formatDate(createdAt) : '';
    final details = "$memberCount member${memberCount != 1 ? 's' : ''}"
        "${createdStr.isNotEmpty ? ' • Created $createdStr' : ''}";

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: isEditing ? pickImage : null,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: newPicture != null
                  ? FileImage(newPicture!)
                  : (groupPicture != null ? NetworkImage(groupPicture!) as ImageProvider : null),
              backgroundColor: Colors.grey.shade300,
              child: (groupPicture == null && newPicture == null)
                  ? Icon(Icons.group, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          isEditing
              ? TextField(
            controller: groupNameController..text = groupName,
            decoration: InputDecoration(hintText: 'Group Name'),
          )
              : Text(groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          isEditing
              ? TextField(
            controller: groupDescriptionController..text = groupDescription,
            decoration: InputDecoration(hintText: 'Group Description'),
          )
              : Text(groupDescription,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(details, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: members.length,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (context, index) {
        final member = members[index];
        final name = member['name'] ?? '';
        final email = member['email'] ?? '';
        final isAdmin = member['is_admin'] ?? false;
        final profilePic = member['profile_picture'];
        final memberId = member['id'];

        return ListTile(
          leading: profilePic != null
              ? CircleAvatar(backgroundImage: NetworkImage(profilePic))
              : CircleAvatar(backgroundColor: Colors.grey.shade300, child: Icon(Icons.person)),
          title: Text(name),
          subtitle: Text(email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (userIsAdmin && !isAdmin)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_member_remove');
                    final body = jsonEncode({
                      "admin_id": UserData.userId,
                      "group_id": widget.id,
                      "user_id_to_remove": memberId,
                    });

                    try {
                      final response = await http.post(
                        url,
                        headers: {"Content-Type": "application/json"},
                        body: body,
                      );

                      if (response.statusCode == 200) {
                        setState(() {
                          members.removeAt(index); // remove the member from the list immediately
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Member removed')),
                        );
                      } else {
                        throw Exception("Failed to remove member");
                      }
                    } catch (e) {
                      print("Error removing member: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error removing member')),
                      );
                    }
                  },
                ),
              Row(
                children: [
                  Text(
                    isAdmin ? 'Admin' : 'Member',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileOtherScreen(profileId: memberId),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(Icons.person_add, 'Add Member', () {
          _showAddMemberDialog();
        }),
        _actionButton(isEditing ? Icons.save : Icons.edit,
            isEditing ? 'Save Group' : 'Edit Group', () {
              if (isEditing) {
                saveGroupDetails();
              } else {
                setState(() {
                  isEditing = true;
                  groupNameController.text = groupName;
                  groupDescriptionController.text = groupDescription;
                });
              }
            }),
        _actionButton(
          userIsAdmin ? Icons.delete : Icons.exit_to_app,
          userIsAdmin ? 'Delete Group' : 'Exit Group',
              () {
            if (userIsAdmin) {
              _deleteGroup();
            } else {
              _exitGroup();
            }
          },
        ),
      ],
    );
  }

  void _deleteGroup() async {
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_delete');
    final body = jsonEncode({
      "user_id": UserData.userId,
      "group_id": widget.id,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group deleted successfully')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  MainNavigation(initialTab: 1)),
        ); // Navigate back after deletion
      } else {
        print("Failed to delete group: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete group')),
        );
      }
    } catch (e) {
      print("Error deleting group: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting group')),
      );
    }
  }

  void _exitGroup() async {
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_exit');
    final body = jsonEncode({
      "user_id": UserData.userId,
      "group_id": widget.id,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have exited the group')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  MainNavigation(initialTab: 1)),
        );
      } else {
        print("Failed to exit group: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to exit group')),
        );
      }
    } catch (e) {
      print("Error exiting group: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exiting group')),
      );
    }
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: textColor),
      child: Column(
        children: [
          Icon(icon, size: 28, color: textColor),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Member by Email'),
          content: SizedBox(
            width: 300,
            child: TextField(
              controller: emailController,
              decoration: InputDecoration(hintText: 'Enter email address'),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) {
                _addMember(emailController.text.trim());
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addMember(emailController.text.trim());
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMember(String email) async {
    if (email.isEmpty) return;

    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_member_add');
    final body = jsonEncode({
      "admin_id": UserData.userId,
      "group_id": widget.id,
      "email_to_add": email,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member added successfully')),
        );
        Navigator.of(context).pop(); // Navigate back to previous screen
      } else {
        print("Failed to add member: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add member')),
        );
      }
    } catch (e) {
      print("Error adding member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding member')),
      );
    }
  }
}