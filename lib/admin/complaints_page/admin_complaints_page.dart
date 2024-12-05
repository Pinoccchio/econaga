import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

class ComplaintsOverview extends StatefulWidget {
  @override
  _ComplaintsOverviewState createState() => _ComplaintsOverviewState();
}

class _ComplaintsOverviewState extends State<ComplaintsOverview> {
  String? selectedComplaintId;
  TextEditingController replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('COMPLAINTS').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        int totalComplaints = snapshot.data!.docs.length;
        int readComplaints = snapshot.data!.docs.where((doc) {
          return (doc.data() as Map<String, dynamic>)['status'] == 'read';
        }).length;
        int unreadComplaints = totalComplaints - readComplaints;

        return Column(
          children: [
            Text(
              'Complaints Overview',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: readComplaints.toDouble(),
                      title: '$readComplaints',
                      radius: 50,
                      titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: unreadComplaints.toDouble(),
                      title: '$unreadComplaints',
                      radius: 60,
                      titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 0,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.blue, 'Read ($readComplaints)'),
                SizedBox(width: 20),
                _buildLegend(Colors.green, 'Unread ($unreadComplaints)'),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: ComplaintsList(
                      onComplaintSelected: (complaintId) {
                        setState(() {
                          selectedComplaintId = complaintId;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: selectedComplaintId != null
                        ? ComplaintDetail(
                      complaintId: selectedComplaintId!,
                      replyController: replyController,
                      onReplySent: () {
                        setState(() {
                          selectedComplaintId = null;
                        });
                      },
                    )
                        : Center(child: Text('Select a complaint to view details')),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class ComplaintsList extends StatelessWidget {
  final Function(String) onComplaintSelected;

  ComplaintsList({required this.onComplaintSelected});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('COMPLAINTS').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No complaints yet',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          );
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            bool isRead = data['status'] == 'read';
            String userId = data['userId'];

            return ListTile(
              leading: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return CircleAvatar(child: Icon(Icons.person));
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String profilePicUrl = userData['selfieImageUrl'] as String? ?? '';

                  return ClipOval(
                    child: profilePicUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: profilePicUrl,
                      placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.person),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                        : CircleAvatar(child: Icon(Icons.person)),
                  );
                },
              ),
              title: Text('${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'),
              subtitle: Text(data['complaint']?.toString().substring(0, min(50, data['complaint']?.toString().length ?? 0)) ?? 'No complaint text'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatTimestamp(data['timestamp'])),
                  SizedBox(width: 8),
                  Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread, color: isRead ? Colors.green : Colors.red),
                ],
              ),
              onTap: () => onComplaintSelected(doc.id),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat('MMM d, y HH:mm').format((timestamp as Timestamp).toDate());
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Invalid Date';
    }
  }
}

class ComplaintDetail extends StatelessWidget {
  final String complaintId;
  final TextEditingController replyController;
  final VoidCallback onReplySent;

  ComplaintDetail({
    required this.complaintId,
    required this.replyController,
    required this.onReplySent,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('COMPLAINTS').doc(complaintId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
        bool isRead = data['status'] == 'read';
        String userId = data['userId'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Complaint Details',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: Icon(isRead ? Icons.mark_email_unread : Icons.mark_email_read),
                  label: Text(isRead ? 'Mark as Unread' : 'Mark as Read'),
                  onPressed: () => _toggleReadStatus(complaintId, isRead),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(userId).get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return _buildMessageBubble(
                          '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
                          data['complaint'] ?? 'No complaint text',
                          _parseTimestamp(data['timestamp']),
                          isUser: true,
                        );
                      }

                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      String profilePicUrl = userData['selfieImageUrl'] as String? ?? '';

                      return _buildMessageBubble(
                        '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
                        data['complaint'] ?? 'No complaint text',
                        _parseTimestamp(data['timestamp']),
                        isUser: true,
                        profilePicUrl: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
                      );
                    },
                  ),
                  if (data['adminReply'] != null)
                    _buildMessageBubble(
                      'Admin',
                      data['adminReply'],
                      _parseTimestamp(data['adminReplyTimestamp']),
                      isUser: false,
                      profilePicUrl: AssetImage('lib/components/assets/images/official_logo.png'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyController,
                      decoration: InputDecoration(
                        labelText: 'Type your reply',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _sendReply(complaintId, replyController.text);
                      replyController.clear();
                      onReplySent();
                    },
                    child: Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleReadStatus(String complaintId, bool isRead) {
    FirebaseFirestore.instance.collection('COMPLAINTS').doc(complaintId).update({
      'status': isRead ? 'unread' : 'read',
    });
  }

  void _sendReply(String complaintId, String reply) {
    FirebaseFirestore.instance.collection('COMPLAINTS').doc(complaintId).update({
      'adminReply': reply,
      'adminReplyTimestamp': FieldValue.serverTimestamp(),
    });
  }

  String _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat('MMM d, y HH:mm').format((timestamp as Timestamp).toDate());
    } catch (e) {
      print('Error parsing timestamp: $e');
      return 'Invalid Date';
    }
  }

  Widget _buildMessageBubble(
      String senderName,
      String message,
      String timestamp, {
        bool isUser = true,
        ImageProvider? profilePicUrl,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: profilePicUrl != null
              ? profilePicUrl is NetworkImage
              ? CachedNetworkImage(
            imageUrl: (profilePicUrl as NetworkImage).url,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.person),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          )
              : Image(
            image: profilePicUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          )
              : CircleAvatar(child: Icon(Icons.person)),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                senderName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? Colors.blue[100] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    SizedBox(height: 4),
                    Text(
                      timestamp,
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


