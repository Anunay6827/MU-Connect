import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'user_data.dart';
import 'profile_other_screen.dart';

class TimelineScreen extends StatefulWidget {
  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<dynamic> posts = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  List<dynamic> searchedUsers = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchBlogs();
  }

  Future<void> fetchBlogs() async {
    final url = Uri.parse(
        'https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/blogs_list');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': UserData.userId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        posts = data['blogs'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load posts')),
      );
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) return;

    final url = Uri.parse(
        'https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/user_search');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': query}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        searchedUsers = data['users'] ?? [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search users')),
      );
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      searchedUsers = [];
    });
  }

  Future<void> _toggleLike(int index) async {
    final post = posts[index];
    final postId = post['id'];
    final isLiked = post['is_like'] ?? false;
    final count = post['likes_count'] ?? 0;
    final type = isLiked ? 1 : 0;

    final url = Uri.parse(
        'https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/blogs_like');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': UserData.userId,
        'blog_id': postId,
        'type': type,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        post['is_like'] = !isLiked;
        post['likes_count'] = isLiked ? count - 1 : count + 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like status')),
      );
    }
  }

  Future<void> _deletePost(int index) async {
    final post = posts[index];
    final postId = post['id'];

    final url = Uri.parse(
        'https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/blogs_delete');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': UserData.userId,
        'blog_id': postId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        posts.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : const Text("MU Connect"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _startSearch,
          ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSearching
                ? _buildSearchTray()
                : (_isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final post = posts[index];
                final user = post['user'] ?? {};
                final isLiked = post['is_like'] ?? false;
                final isAuthor = post['is_author'] ?? false;
                final profilePic = user['profile_picture'];
                final name = user['name'] ?? '';
                final email = user['email'] ?? '';
                final createdAt =
                    DateTime.tryParse(post['created_at'] ?? '') ??
                        DateTime.now();
                final timeAgo = timeago.format(createdAt);
                final content = post['content'] ?? '';
                final imageUrl = post['image'];

                return Padding(
                  padding: const EdgeInsets.all(17.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileOtherScreen(profileId: user['id']),
                              ),
                            );
                          },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          profilePic != null &&
                              profilePic
                                  .toString()
                                  .startsWith("http")
                              ? CircleAvatar(
                            backgroundImage:
                            NetworkImage(profilePic),
                            radius: 22,
                          )
                              : CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: 22,
                            child: Text(name.isNotEmpty
                                ? name[0]
                                : '?'),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(email,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(timeAgo,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      )
                      ),
                      SizedBox(height: 10),
                      Text(content),
                      if (imageUrl != null) ...[
                        SizedBox(height: 10),
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                        ),
                      ],
                      SizedBox(height: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleLike(index),
                            child: Icon(
                              Icons.favorite,
                              color:
                              isLiked ? Colors.red : Colors.grey,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text('${post['likes_count']} likes'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search users...',
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      onSubmitted: (query) {
        searchUsers(query);
      },
    );
  }

  Widget _buildSearchTray() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(10),
      color: isDark ? Colors.grey[900] : Colors.grey[200],
      child: searchedUsers.isEmpty
          ? Center(child: Text("Search for users with email or name"))
          : ListView.builder(
        itemCount: searchedUsers.length,
        itemBuilder: (context, index) {
          final user = searchedUsers[index];
          final profileId = user['id'];
          final name = user['name'] ?? '';
          final email = user['email'] ?? '';
          final profilePic = user['profile_picture'];

          return ListTile(
            leading: profilePic != null &&
                profilePic.toString().startsWith("http")
                ? CircleAvatar(
              backgroundImage: NetworkImage(profilePic),
            )
                : CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: TextStyle(color: Colors.black),
              ),
            ),
            title: Text(name),
            subtitle: Text(email, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileOtherScreen(profileId: profileId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}