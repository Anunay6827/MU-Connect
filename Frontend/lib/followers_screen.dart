import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_data.dart';
import 'profile_other_screen.dart';

class FollowersScreen extends StatefulWidget {
  final int type;

  const FollowersScreen({Key? key, required this.type}) : super(key: key);

  @override
  _FollowersScreenState createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<Map<String, dynamic>> followers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/user_follow_list');

    final body = jsonEncode({
      "user_id": UserData.userId,
      "type": widget.type,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> follows = data['follows'] ?? [];

        setState(() {
          followers = follows.map<Map<String, dynamic>>((item) {
            final user = item['users'];
            return {
              "id": user['id'],
              "name": user['name'],
              "email": user['email'],
              "profilePic": user['profile_picture'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        print('Failed to load data: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.type == 1 ? "Followers" : "Following";

    // Debugging print statements
    print("FollowersScreen type: ${widget.type}");
    print("Title: $title");

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "$title (${followers.length})",
          style: Theme.of(context).appBarTheme.titleTextStyle ??
              TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : followers.isEmpty
          ? Center(child: Text("No $title found."))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: followers.length,
        itemBuilder: (context, index) {
          return _buildFollowerItem(index, isDark);
        },
      ),
    );
  }

  Widget _buildFollowerItem(int index, bool isDark) {
    var follower = followers[index];
    final profilePic = follower["profilePic"];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey[400],
        backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
        child: profilePic == null ? const Icon(Icons.person, color: Colors.white) : null,
      ),
      title: Text(
        follower["name"] ?? "Unknown",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        follower["email"] ?? "",
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileOtherScreen(profileId: follower["id"]),
          ),
        );
      },
    );
  }
}