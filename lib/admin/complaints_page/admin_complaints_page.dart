import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../designs/app_colors.dart';

class ComplaintsOverview extends StatefulWidget {
  @override
  _ComplaintsOverviewState createState() => _ComplaintsOverviewState();
}

class _ComplaintsOverviewState extends State<ComplaintsOverview> {
  String? selectedComplaintId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Account Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.secondaryGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          var complaints = snapshot.data?.docs ?? [];

          return Row(
            children: [
              Container(
                width: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _buildComplaintsList(complaints),
              ),
              Expanded(
                child: selectedComplaintId != null
                    ? _buildComplaintDetail()
                    : Center(
                  child: Text(
                    'Select a complaint to view details',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComplaintsList(List<QueryDocumentSnapshot> complaints) {
    return ListView.separated(
      itemCount: complaints.length,
      padding: EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        var complaint = complaints[index];
        var complaintData = complaint.data() as Map<String, dynamic>;
        bool isSelected = selectedComplaintId == complaint.id;

        return InkWell(
          onTap: () {
            setState(() {
              selectedComplaintId = complaint.id;
            });
          },
          child: Container(
            color: isSelected ? Colors.grey[100] : Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('USERS_ACCOUNTS')
                      .doc(complaintData['userId'])
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: _getAvatarColor(complaintData['email'] ?? ''),
                        child: Text(
                          _getInitials(complaintData['email'] ?? ''),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    var userData = snapshot.data!.data() as Map<String, dynamic>?;
                    String? profileImageUrl = userData?['selfieImageUrl'];
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? Text(
                        _getInitials(complaintData['email'] ?? ''),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      )
                          : null,
                    );
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              complaintData['email'] ?? 'No email',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(complaintData['lastMessageTimestamp']),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        complaintData['lastMessage'] ?? complaintData['complaint'] ?? 'No message',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.isEmpty) return '';
    final name = parts[0];
    if (name.isEmpty) return '';
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  Color _getAvatarColor(String email) {
    final colors = [
      Colors.teal,
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.pink,
      Colors.indigo
    ];
    return colors[email.hashCode.abs() % colors.length];
  }

  int min(int a, int b) => a < b ? a : b;

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

  Widget _buildComplaintDetail() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .doc(selectedComplaintId)
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

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _buildComplaintHeader(complaintData),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index] as Map<String, dynamic>;
                    return _buildMessageBubble(
                      message['senderId'] == 'admin' ? 'Admin' : complaintData['email'] ?? 'User',
                      message['content'],
                      _formatTimestamp(message['timestamp']),
                      isAdmin: message['senderId'] == 'admin',
                      userId: complaintData['userId'],
                    );
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplaintHeader(Map<String, dynamic> complaintData) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('USERS_ACCOUNTS')
                .doc(complaintData['userId'])
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: _getAvatarColor(complaintData['email'] ?? ''),
                  child: Text(
                    _getInitials(complaintData['email'] ?? ''),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                );
              }
              var userData = snapshot.data!.data() as Map<String, dynamic>?;
              String? profileImageUrl = userData?['selfieImageUrl'];
              return CircleAvatar(
                radius: 24,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null
                    ? Text(
                  _getInitials(complaintData['email'] ?? ''),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                )
                    : null,
              );
            },
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaintData['email'] ?? 'No email',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complaint: ${complaintData['complaint'] ?? 'No details'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      String sender,
      String message,
      String timestamp,
      {required bool isAdmin, required String userId}
      ) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isAdmin) ...[
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('USERS_ACCOUNTS')
                    .doc(userId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: _getAvatarColor(sender),
                      child: Text(
                        _getInitials(sender),
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
                    child: profileImageUrl == null
                        ? Text(
                      _getInitials(sender),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    )
                        : null,
                  );
                },
              ),
              SizedBox(width: 8),
            ],
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdmin ? AppColors.secondaryGreen.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin) ...[
              SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('lib/components/assets/images/official_logo.png'),
              ),
            ],
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
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    if (_messageController.text.trim().isEmpty || selectedComplaintId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(selectedComplaintId)
          .update({
        'messages': FieldValue.arrayUnion([
          {
            'content': _messageController.text,
            'senderId': 'admin',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }
        ]),
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
}





