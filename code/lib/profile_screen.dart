import 'package:flutter/material.dart';
import 'notification_screen.dart'; // Ensure you have this screen
import 'login_screen.dart'; // Ensure you have this screen

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(""),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStats(),
            Divider(),
            _buildMenuItem(context, "Notification", "See your recent activity", 35, NotificationScreen()),
            _buildMenuItem(context, "Friends", "Friendlist totals"),
            _buildMenuItem(context, "Messages", "Message your friends", 2),
            _buildMenuItem(context, "Albums", "Save or post your albums"),
            _buildMenuItem(context, "Favorites", "Friends you love"),
            Divider(),
            _buildMenuItem(context, "Privacy Policy", "Protect your privacy"),
            SizedBox(height: 20),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  /// **Profile Header (Profile Picture, Name, Username)**
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.red,
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("MU Student", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("@se@#####@@@", style: TextStyle(color: Colors.grey)),
            ],
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  /// **User Stats (Followers, Posts, Following)**
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem("6.3k", "Followers"),
          _buildStatItem("572", "Post"),
          _buildStatItem("2.5k", "Following"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  /// **Menu Items (Notifications, Friends, Messages, etc.)**
  Widget _buildMenuItem(BuildContext context, String title, String subtitle, [int? badge, Widget? screen]) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(
                "$badge",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(width: 10),
          Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        ],
      ),
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        }
      },
    );
  }

  /// **Logout Button (Functional)**
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red),
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            _logout(context);
          },
          child: Text("Log out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  /// **Logout Function**
  void _logout(BuildContext context) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }
}
