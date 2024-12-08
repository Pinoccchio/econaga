import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../designs/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        title: Text(
          'Complaint Details',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .doc(widget.complaintId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.secondaryGreen));
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
                    );
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
          color: isUser ? AppColors.secondaryGreen.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
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
                if (isUser)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('USERS_ACCOUNTS')
                        .doc(widget.userId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(strokeWidth: 2);
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.secondaryGreen,
                          child: Text(
                            sender[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      var userData = snapshot.data!.data() as Map<String, dynamic>?;
                      String? profileImageUrl = userData?['selfieImageUrl'];
                      return CircleAvatar(
                        radius: 16,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl)
                            : null,
                        backgroundColor: AppColors.secondaryGreen,
                        child: profileImageUrl == null
                            ? Text(
                          sender[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        )
                            : null,
                      );
                    },
                  )
                else
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage('lib/components/assets/images/official_logo.png'),
                  ),
                SizedBox(width: 8),
                Text(
                  sender,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isUser ? AppColors.secondaryGreen : Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              timestamp,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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
                hintStyle: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(),
            ),
          ),
          SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.secondaryGreen,
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




