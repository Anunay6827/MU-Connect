import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Notification", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.black),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Show all", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text("Mark all as read", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Divider(),
            _buildNotificationItem("MU Student", "Shared your post", "52 min ago"),
            _buildNotificationItem("MU Student", "Liked your profile photo", "1 h ago", showReadButton: true),
            _buildNotificationItem("MU Student", "Liked your photo", "2 h ago"),
            _buildNotificationItem("MU Student", "Commend your post", "3 h ago"),
            _buildNotificationItem("MU Student", "Added photo in group", "4 h ago", boldText: "generic photo"),
            _buildNotificationItem("MU Student", "Liked your post", "5 h ago"),
            _buildNotificationItem("MU Student", "Liked your comments", "6 h ago"),
          ],
        ),
      ),
    );
  }

  /// **Notification Item (Reusable Widget)**
  Widget _buildNotificationItem(String user, String action, String time, {bool showReadButton = false, String? boldText}) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
      ),
      title: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black),
          children: [
            TextSpan(text: "$user ", style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: action),
            if (boldText != null) TextSpan(text: " $boldText", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      subtitle: Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: showReadButton
          ? ElevatedButton(
              onPressed: () {
                // TODO: Mark as read logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Read"),
            )
          : null,
    );
  }
}
