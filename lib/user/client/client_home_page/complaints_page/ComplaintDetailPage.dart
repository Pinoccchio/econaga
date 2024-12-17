import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ComplaintDetailPage extends StatefulWidget {
  final String complaintId;
  final String userId;

  ComplaintDetailPage({required this.complaintId, required this.userId});

  @override
  _ComplaintDetailPageState createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Modern green color palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFAED581);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color accentGreen = Color(0xFF69F0AE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text(
          'Complaint Details',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .doc(widget.complaintId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Complaint not found'));
          }

          var complaintData = snapshot.data!.data() as Map<String, dynamic>;
          var messages = complaintData['messages'] as List<dynamic>? ?? [];

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index] as Map<String, dynamic>;
                    bool isUser = message['senderId'] == widget.userId;
                    return _buildMessageBubble(
                      isUser ? 'You' : 'Admin',
                      message['content'],
                      _formatTimestamp(message['timestamp']),
                      isUser: isUser,
                    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.2, end: 0);
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(String sender, String message, String timestamp, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? lightGreen.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatar(sender, isUser),
                SizedBox(width: 8),
                Text(
                  sender,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isUser ? darkGreen : primaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              timestamp,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String sender, bool isUser) {
    if (isUser) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('USERS_ACCOUNTS')
            .doc(widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(strokeWidth: 2, color: primaryGreen);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _defaultAvatar(sender);
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          String? profileImageUrl = userData?['selfieImageUrl'];
          return CircleAvatar(
            radius: 16,
            backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
            backgroundColor: lightGreen,
            child: profileImageUrl == null ? _defaultAvatarChild(sender) : null,
          );
        },
      );
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundImage: AssetImage('lib/components/assets/images/official_logo.png'),
        backgroundColor: primaryGreen,
      );
    }
  }

  Widget _defaultAvatar(String sender) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: lightGreen,
      child: _defaultAvatarChild(sender),
    );
  }

  Widget _defaultAvatarChild(String sender) {
    return Text(
      sender[0].toUpperCase(),
      style: GoogleFonts.montserrat(
        color: darkGreen,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.montserrat(
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              maxLines: null,
              style: GoogleFonts.montserrat(),
            ),
          ),
          SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              padding: EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final newMessage = {
        'content': _messageController.text,
        'senderId': widget.userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId)
          .update({
        'messages': FieldValue.arrayUnion([newMessage]),
        'lastMessage': _messageController.text,
        'lastMessageTimestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _messageController.clear();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send message.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('MMM d, y h:mm a').format(date); // Format: Dec 9, 2024 3:45 PM
    } catch (e) {
      print('Error formatting timestamp: $e');
      return '';
    }
  }
}



