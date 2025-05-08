import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'followers_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'theme_provider.dart';
import 'main.dart';
import 'user_data.dart';
import 'message.dart';

class ProfileOtherScreen extends StatefulWidget {
  final int profileId;

  ProfileOtherScreen({required this.profileId});

  @override
  _ProfileOtherScreenState createState() => _ProfileOtherScreenState();
}

class _ProfileOtherScreenState extends State<ProfileOtherScreen> {
  late Future<Map<String, dynamic>> userDataFuture;
  List<dynamic> posts = [];
  bool _isLoading = true;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  void _fetchAll() {
    userDataFuture = fetchUserData();
    fetchUserPosts();
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final response = await http.post(
      Uri.parse("https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/user_profile_info"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "user_id": UserData.userId,
        "profile_id": widget.profileId,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load user data");
    }
  }

  Future<void> fetchUserPosts() async {
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/blogs_list');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': UserData.userId,
        'profile_id': widget.profileId,
      }),
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

  Future<void> _toggleFollow(bool isCurrentlyFollowing) async {
    if (_followLoading) return; // Prevent multiple requests

    setState(() {
      _followLoading = true;
    });

    final type = isCurrentlyFollowing ? 1 : 0;
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/user_follow');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': UserData.userId,
          'other_user_id': widget.profileId,
          'type': type,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          userDataFuture = fetchUserData();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${isCurrentlyFollowing ? 'unfollow' : 'follow'} user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _followLoading = false;
      });
    }
  }

  Future<void> _toggleLike(int index) async {
    final post = posts[index];
    final postId = post['id'];
    final isLiked = post['is_like'] ?? false;
    final count = post['likes_count'] ?? 0;
    final type = isLiked ? 1 : 0;

    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/blogs_like');
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
    final postId = posts[index]['id'];

    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/blogs_delete');
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(userDataFuture),
      future: userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        } else {
          final user = snapshot.data!['user'];
          final stats = snapshot.data!['stats'];

          final id = user['id'];
          final name = user['name'] ?? '';
          final username = user['email'] ?? '';
          final bio = (user['bio'] ?? '').isEmpty ? 'No bio available' : user['bio'];
          final profile_picture = user['profile_picture'] ?? '';
          final followers = stats['followers'] ?? 0;
          final following = stats['following'] ?? 0;
          final posts_count = stats['posts'] ?? 0;
          final isFollowing = snapshot.data!['is_following'] ?? false;

          return Scaffold(
            appBar: AppBar(
              title: Text(name),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  onSelected: (String choice) {
                    if (choice == 'Edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            name: name,
                            username: username,
                            bio: bio,
                            password: "",
                            profile_picture: profile_picture,
                          ),
                        ),
                      );
                    } else if (choice == 'Logout') {
                      isLoggedIn = false;
                      UserData.userId = null;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dark Mode'),
                          Switch(
                            value: isDark,
                            onChanged: (val) {
                              themeProvider.toggleTheme(val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(value: 'Edit', child: Text('Edit Profile')),
                    const PopupMenuItem<String>(value: 'Logout', child: Text('Logout')),
                  ],
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() => _isLoading = true);
                _fetchAll();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(name, username, bio, profile_picture),
                    _buildStats(context, followers, posts_count, following, isFollowing, name, id, profile_picture),
                    const Divider(),
                    _buildUserPosts(),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildProfileHeader(String name, String username, String bio, String profile_picture) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          profile_picture.isNotEmpty
              ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(profile_picture))
              : const CircleAvatar(radius: 50, backgroundColor: Colors.grey),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(username, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text(bio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, int followers, int posts, int following, bool isFollowing, String name, int id, String picture) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(followers, "Followers"),
              _buildStatItem(posts, "Posts"),
              _buildStatItem(following, "Following"),
            ],
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          // Buttons for Follow and Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _followLoading
                        ? null
                        : () => _toggleFollow(isFollowing),
                    style: TextButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.white : Colors.black,
                      foregroundColor: isFollowing ? Colors.black : Colors.white,
                      side: isFollowing ? const BorderSide(color: Colors.grey) : null,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _followLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isFollowing ? Colors.black : Colors.white,
                      ),
                    )
                        : Text(isFollowing ? "Following" : "Follow"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessagePage(name: name, id: id, picture: picture, conv_type: 0),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Message"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStatItem(int value, String label) {
    return Column(
      children: [
        Text("$value", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildUserPosts() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No posts yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final post = posts[index];
        final user = post['user'] ?? {};
        final isLiked = post['is_like'] ?? false;
        final isAuthor = post['is_author'] ?? false;
        final profilePic = user['profile_picture'];
        final name = user['name'] ?? '';
        final email = user['email'] ?? '';
        final createdAt = DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now();
        final timeAgo = timeago.format(createdAt);
        final content = post['content'] ?? '';
        final imageUrl = post['image'];

        return Padding(
          padding: const EdgeInsets.all(17.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  profilePic != null && profilePic.toString().startsWith("http")
                      ? CircleAvatar(backgroundImage: NetworkImage(profilePic), radius: 22)
                      : CircleAvatar(backgroundColor: Colors.grey, radius: 22, child: Text(name.isNotEmpty ? name[0] : '?')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (isAuthor)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePost(index),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(content),
              if (imageUrl != null) ...[
                const SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(index),
                    child: Icon(Icons.favorite, color: isLiked ? Colors.red : Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text('${post['likes_count']} likes'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}