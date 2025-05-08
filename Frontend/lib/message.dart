import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:se_course/group_view_screen.dart';
import 'profile_other_screen.dart';
import 'user_data.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'group_view_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'messages_screen.dart';

class MessagePage extends StatefulWidget {
  final String name;
  final int id;
  final String picture;
  final int conv_type;

  const MessagePage({
    super.key,
    required this.name,
    required this.id,
    required this.picture,
    required this.conv_type,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  File? _selectedImage;
  bool _isImageSelected = false;

  final SupabaseClient supabase = Supabase.instance.client;
  late RealtimeChannel _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.conv_type == 0) {
      fetchMessages();
    } else {
      fetchGroupMessages();
    }
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _subscription = supabase.channel('messages_channel')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chats_messages',
        callback: (payload) {
          _reloadPage();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'groups_messages',
        callback: (payload) {
          _reloadPage();
        },
      )
      ..subscribe();
  }

  void _reloadPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          name: widget.name,
          id: widget.id,
          picture: widget.picture,
          conv_type: widget.conv_type,
        ),
      ),
    );
  }

  @override
  void dispose() {
    supabase.removeChannel(_subscription);
    super.dispose();
  }

  Future<void> fetchMessages() async {
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/chats_message_list');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': UserData.userId,
        'chatter_id': widget.id,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> chatData = data['data'];
      messages = chatData.map<Map<String, dynamic>>((msg) {
        final senderId = msg['sender_id'];
        return {
          'id': msg['id'],
          'fromMe': senderId == UserData.userId,
          'text': msg['content'],
          'timestamp': DateTime.parse(msg['created_at']),
          'content_type': msg['content_type'],
          'picture': widget.picture,
        };
      }).toList();
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchGroupMessages() async {
    final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_message_list');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'group_id': widget.id
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> chatData = data['messages'];
      messages = chatData.map<Map<String, dynamic>>((msg) {
        final senderId = msg['sender'];
        final sender = msg['sender_info'];
        return {
          'id': msg['id'],
          'fromMe': senderId == UserData.userId,
          'text': msg['content'],
          'timestamp': DateTime.parse(msg['created_at']),
          'content_type': msg['content_type'],
          'picture': sender['profile_picture'],
          'name': sender['name'],
        };
      }).toList();
    }

    setState(() => isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isImageSelected = true;
        _textController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () {
          _focusNode.unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              if (isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                _buildMessageList(context, isDark),
              _buildInputField(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          if (!isDark)
            const BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              widget.conv_type == 0
                  ? MaterialPageRoute(
                builder: (context) => ProfileOtherScreen(profileId: widget.id),
              )
                  : MaterialPageRoute(
                builder: (context) => GroupViewScreen(id: widget.id),
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[400],
              backgroundImage: widget.picture.isNotEmpty ? NetworkImage(widget.picture) : null,
              child: widget.picture.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  widget.conv_type == 0 ? "Tap to view full profile" : "Tap to view full group info",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, bool isDark) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isMe = message['fromMe'] as bool;
          final timestamp = message['timestamp'] as DateTime;

          DateTime istTimestamp = timestamp.toUtc().add(Duration(hours: 5, minutes: 30));

          bool showDateDivider = index == 0 ||
              !isSameDay(
                messages[index - 1]['timestamp'] as DateTime,
                timestamp,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDateDivider)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          DateFormat('EEEE, MMM d').format(istTimestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),
              Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe) ...[
                      CircleAvatar(
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[400],
                        radius: 12,
                        backgroundImage: widget.picture.isNotEmpty ? NetworkImage(widget.picture) : null,
                        child: widget.picture.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onLongPress: isMe
                              ? () => _showDeleteDialog(context, message['id'])
                              : null,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: message['content_type'] == 1 // Check if the content is an image (content_type == 1)
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(16), // Apply border radius to image
                              child: Image.network(
                                message['text'], // Assuming 'text' contains the image URL
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 300, // Adjust the height as needed
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  } else {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            (loadingProgress.expectedTotalBytes ?? 1)
                                            : null,
                                      ),
                                    );
                                  }
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(child: Text('Failed to load image'));
                                },
                              ),
                            )
                                : Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMe ? 14 : 3,
                                vertical: isMe ? 10 : 3,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.red
                                    : isDark
                                    ? Colors.grey[850]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                message['text'], // Default to displaying text if it's not an image
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : isDark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0, left: 4.0, right: 4.0),
                          child: Text(
                            DateFormat.jm().format(istTimestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputField(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          if (!isDark) const BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.blue),
            onPressed: _isImageSelected ? null : _pickImage, // Disable if image is selected
          ),
          if (_selectedImage != null) ...[
            Image.file(
              _selectedImage!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode, // Attach the focus node
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Say something",
                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                fillColor: isDark ? Colors.grey[800] : Colors.grey.shade200,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              enabled: !_isImageSelected, // Disable text input if image is selected
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage, // Disable send if image is selected
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    a = a.toUtc().add(Duration(hours: 5, minutes: 30));
    b = b.toUtc().add(Duration(hours: 5, minutes: 30));
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showDeleteDialog(BuildContext context, int messageId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(messageId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMessage(int messageId) async {
    if(widget.conv_type == 0) {
      final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/chats_message_delete');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': UserData.userId,
          'message_id': messageId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          messages.removeWhere((msg) => msg['id'] == messageId);
        });
      }
    } else {
      final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_message_delete');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': UserData.userId,
          'group_id': widget.id,
          'message_id': messageId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          messages.removeWhere((msg) => msg['id'] == messageId);
        });
      }
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    final selectedImage = _selectedImage;

    if (text.isEmpty && selectedImage == null) return;

    int contentType = 0;
    String content = text;

    if (selectedImage != null) {
      contentType = 1;
      content = '';
    }

    if(widget.conv_type == 0) {
      final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/chats_message_send');

      var request = http.MultipartRequest('POST', url)
        ..fields['sender_id'] = UserData.userId.toString()
        ..fields['receiver_id'] = widget.id.toString()
        ..fields['content'] = content
        ..fields['content_type'] = contentType.toString();

      if (selectedImage != null) {
        final mimeType = lookupMimeType(selectedImage.path) ?? 'application/octet-stream';
        final file = await http.MultipartFile.fromPath(
          'image',
          selectedImage.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(file);
      }

      try {
        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final responseData = jsonDecode(responseBody);

          final messageData = responseData['data'];

          setState(() {
            messages.add({
              'id': messageData['id'],
              'fromMe': messageData['sender_id'] == UserData.userId,
              'text': messageData['content'],
              'timestamp': DateTime.parse(messageData['created_at']),
              'content_type': messageData['content_type'],
              'picture': widget.picture,
            });
            _textController.clear();
            _isImageSelected = false;
            _selectedImage = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message')),
          );
        }
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } else {
      final url = Uri.parse('https://peugmvvuvjhxdmupzycb.supabase.co/functions/v1/groups_message_send');

      var request = http.MultipartRequest('POST', url)
        ..fields['user_id'] = UserData.userId.toString()
        ..fields['group_id'] = widget.id.toString()
        ..fields['content'] = content
        ..fields['content_type'] = contentType.toString();

      if (selectedImage != null) {
        final mimeType = lookupMimeType(selectedImage.path) ?? 'application/octet-stream';
        final file = await http.MultipartFile.fromPath(
          'image',
          selectedImage.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(file);
      }

      try {
        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final responseData = jsonDecode(responseBody);

          final messageData = responseData['message_record'];

          setState(() {
            messages.add({
              'id': messageData['id'],
              'fromMe': messageData['sender'] == UserData.userId,
              'text': messageData['content'],
              'timestamp': DateTime.parse(messageData['created_at']),
              'content_type': messageData['content_type'],
              'picture': widget.picture,
            });
            _textController.clear();
            _isImageSelected = false;
            _selectedImage = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }
}