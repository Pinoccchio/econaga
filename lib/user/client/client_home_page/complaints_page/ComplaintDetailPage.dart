import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../designs/app_colors.dart';

class ComplaintDetailPage extends StatefulWidget {
  final String complaintId;
  final String userId;

  ComplaintDetailPage({required this.complaintId, required this.userId});

  @override
  _ComplaintDetailPageState createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  TextEditingController _replyController = TextEditingController();
  DocumentSnapshot? _complaintData;

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetails();
  }

  Future<void> _fetchComplaintDetails() async {
    try {
      DocumentSnapshot complaintDoc = await FirebaseFirestore.instance
          .collection('COMPLAINTS')
          .doc(widget.complaintId)
          .get();
      if (complaintDoc.exists) {
        setState(() {
          _complaintData = complaintDoc;
        });
      }
    } catch (e) {
      print('Error fetching complaint details: $e');
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('COMPLAINTS')
          .doc(widget.complaintId)
          .update({
        'adminReply': _replyController.text,
        'adminReplyTimestamp': FieldValue.serverTimestamp(),
      });
      _replyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reply sent successfully.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print('Error sending reply: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send reply.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('MMM d, y HH:mm').format(timestamp.toDate());
  }

  Widget _buildProfilePicture(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(userId)
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(child: CircularProgressIndicator());
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return CircleAvatar(child: Icon(Icons.person));
        }

        final userData =
        userSnapshot.data!.data() as Map<String, dynamic>?;
        String profilePicUrl = userData?['profile_picture'] ?? '';
        return CircleAvatar(
          backgroundImage: profilePicUrl.isNotEmpty
              ? NetworkImage(profilePicUrl)
              : null,
          child: profilePicUrl.isEmpty ? Icon(Icons.person) : null,
        );
      },
    );
  }

  Widget _buildAdminProfilePicture() {
    return CircleAvatar(
      backgroundImage: AssetImage('lib/components/assets/images/official_logo.png'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        title: Text('Complaint Details'),
      ),
      body: _complaintData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Admin Message
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdminProfilePicture(),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              _complaintData!['complaint'],
                              style: TextStyle(fontSize: 16),
                            ),
                            if (_complaintData!['adminReplyTimestamp'] != null)
                              Text(
                                _formatTimestamp(
                                    _complaintData!['adminReplyTimestamp']),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // User Message
                  if (_complaintData!['adminReply'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'You',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _complaintData!['adminReply'],
                                style: TextStyle(fontSize: 16),
                              ),
                              if (_complaintData!['adminReplyTimestamp'] != null)
                                Text(
                                  _formatTimestamp(
                                      _complaintData!['adminReplyTimestamp']),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        _buildProfilePicture(widget.userId),
                      ],
                    ),
                ],
              ),
            ),

            // Reply input field for admin
            SizedBox(height: 10),
            TextField(
              controller: _replyController,
              decoration: InputDecoration(
                labelText: 'Enter your reply...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendReply,
              child: Text('Send Reply'),
            ),
          ],
        ),
      ),
    );
  }
}

