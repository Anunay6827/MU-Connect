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

class ProfileViewScreen extends StatefulWidget {
  @override
  _ProfileViewScreenState createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  late Future<Map<String, dynamic>> userDataFuture;
  List<dynamic> posts = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    userDataFuture = fetchUserData();
    fetchUserPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      userDataFuture = fetchUserData();
    });
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    final response = await http.post(
      Uri.parse("https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/user_info"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"user_id": UserData.userId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load user data");
    }
  }

  Future<void> fetchUserPosts() async {
    final url = Uri.parse(
        'https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/blogs_list');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': UserData.userId, 'profile_id': UserData.userId}),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return FutureBuilder<Map<String, dynamic>>(
      future: userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        } else {
          final user = snapshot.data!['user'];
          final stats = snapshot.data!['stats'];

          final name = user['name'] ?? '';
          final username = user['email'] ?? '';
          final bio = (user['bio'] ?? '').isEmpty ? 'No bio available' : user['bio'];
          final profile_picture = user['profile_picture'] ?? '';
          final followers = stats['followers'] ?? 0;
          final following = stats['following'] ?? 0;
          final posts_count = stats['posts'] ?? 0;

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
                    const PopupMenuItem<String>(value: 'Edit', child: Text('Edit Profile')),
                    const PopupMenuItem<String>(value: 'Logout', child: Text('Logout')),
                  ],
                ),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    themeProvider.toggleTheme(!isDark);
                  },
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  userDataFuture = fetchUserData();
                  _isLoading = true;
                });
                await fetchUserPosts();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(name, username, bio, profile_picture),
                    _buildStats(context, followers, posts_count, following),
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
              ? CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(profile_picture),
          )
              : const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(username, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, int followers, int posts, int following) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FollowersScreen(key: ValueKey('followers'), type: 1),
                ),
              );
            },
            child: _buildStatItem(followers, "Followers"),
          ),
          _buildStatItem(posts, "Posts"),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FollowersScreen(key: ValueKey('following'), type: 0),
                ),
              );
            },
            child: _buildStatItem(following, "Following"),
          ),
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
      return Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No posts yet",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
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
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(profilePic),
                    radius: 22,
                  )
                      : CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 22,
                    child: Text(name.isNotEmpty ? name[0] : '?'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(email, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  if (isAuthor)
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePost(index),
                    ),
                ],
              ),
              SizedBox(height: 10),
              Text(content),
              if (imageUrl != null) ...[
                SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),
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
                      color: isLiked ? Colors.red : Colors.grey,
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
    );
  }
}