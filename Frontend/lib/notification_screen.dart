import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'user_data.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/notification_retrieve');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'receiver': UserData.userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        notifications = data['notifications'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Notification",
          style: Theme.of(context).appBarTheme.titleTextStyle ??
              TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
        ),
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No notifications found."))
          : ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final content = notification['content'] ?? '';
          final createdAt = notification['created_at'];
          final dateTime = DateTime.tryParse(createdAt ?? '') ?? DateTime.now();
          final timeAgo = timeago.format(dateTime, allowFromNow: true);

          return _buildNotificationItem(context, content, timeAgo);
        },
      ),
    );
  }

  /// Notification Item Builder
  Widget _buildNotificationItem(BuildContext context, String content, String timeAgo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      title: Text(
        content,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      subtitle: Text(
        timeAgo,
        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 12),
      ),
    );
  }
}