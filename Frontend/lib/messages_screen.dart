import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'message.dart';
import "user_data.dart";
import 'package:timeago/timeago.dart' as timeago;
import 'create_group_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> filteredMessages = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/conversations_list');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': UserData.userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List convs = data['conversations'];

      if (mounted) {
        setState(() {
          messages = convs.map<Map<String, dynamic>>((conv) {
            return {
              'conv_id': conv['id'],
              'sender': conv['name'],
              'message': (conv['last_message_content'] as String?)?.trim().isNotEmpty == true
                ? conv['last_message_content']
                : 'No messages',
              'timestamp': conv['last_message_time'] != null
                  ? DateTime.parse(conv['last_message_time'])
                  : DateTime.now(),
              'picture': conv['picture'],
              'conv_type': conv['conv_type'],
              'trashed': false,
            };
          }).toList();
          filteredMessages = messages;
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Failed to load conversations');
    }
  }

  void filterMessages(String query) {
    final result = messages.where((msg) {
      final sender = msg['sender'].toString().toLowerCase();
      final text = msg['message'].toString().toLowerCase();
      return sender.contains(query.toLowerCase()) || text.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredMessages = result;
    });
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
          "Messages",
          style: Theme.of(context).appBarTheme.titleTextStyle ??
              TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
        ),
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: 26,
            color: isDark ? Colors.white : Colors.black,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  CreateGroupScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: searchController,
              onChanged: filterMessages,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[700]),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search,
                    color: isDark ? Colors.white : Colors.grey[800]),
              ),
            ),
          ),
          isLoading
              ? Center(
            child: CircularProgressIndicator(),
          )
              : Expanded(
            child: ListView.builder(
              itemCount: filteredMessages.length,
              itemBuilder: (context, index) {
                if (filteredMessages[index]['trashed']) return const SizedBox();

                return InkWell(
                  onTap: () {
                    String picture = filteredMessages[index]['picture'] ?? '';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessagePage(
                          name: filteredMessages[index]['sender'],
                          id: filteredMessages[index]['conv_id'],
                          picture: picture,
                          conv_type: filteredMessages[index]['conv_type'],
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: filteredMessages[index]['picture'] != null
                        ? CircleAvatar(
                      backgroundImage: NetworkImage(
                          filteredMessages[index]['picture']),
                      radius: 25,
                    )
                        : CircleAvatar(
                      backgroundColor:
                      isDark ? Colors.grey[700] : Colors.grey[300],
                      radius: 25,
                    ),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                filteredMessages[index]['sender'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 0),
                              Text(
                                filteredMessages[index]['message'],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              timeago.format(filteredMessages[index]['timestamp']),
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}