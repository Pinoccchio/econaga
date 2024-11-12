import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../designs/app_colors.dart';
import 'ComplaintDetailPage.dart';  // Ensure this path is correct
import 'package:intl/intl.dart';

class SubmittedComplaintsPage extends StatefulWidget {
  final String userId;

  SubmittedComplaintsPage({required this.userId});

  @override
  _SubmittedComplaintsPageState createState() =>
      _SubmittedComplaintsPageState();
}

class _SubmittedComplaintsPageState extends State<SubmittedComplaintsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        title: Text('SUBMITTED COMPLAINTS'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('COMPLAINTS')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var complaints = snapshot.data!.docs;

          if (complaints.isEmpty) {
            return Center(child: Text('No complaints submitted yet.'));
          }

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var complaint = complaints[index];
              var complaintId = complaint.id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(
                      'lib/components/assets/images/official_logo.png'),
                ),
                title: Text('To: Admin'),
                subtitle: Text(complaint['complaint']),
                trailing: Text(
                    'Submitted: ${_parseTimestamp(complaint['timestamp'])}'),
                onTap: () {
                  /*
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintDetailPage(
                        complaintId: complaintId,
                        userId: widget.userId,
                      ),
                    ),
                  );

                   */
                },
              );
            },
          );
        },
      ),
    );
  }

  String _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat('MMM d, y HH:mm')
          .format((timestamp as Timestamp).toDate());
    } catch (e) {
      print('Error parsing timestamp: $e');
      return 'Invalid Date';
    }
  }
}
