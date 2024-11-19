import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class NotificationPage extends StatefulWidget {
  final String userId;

  NotificationPage({required this.userId});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Stream<List<Map<String, dynamic>>> _requestsStream;

  @override
  void initState() {
    super.initState();
    _requestsStream = _listenToRequests();
  }

  Stream<List<Map<String, dynamic>>> _listenToRequests() {
    final garbageStream = FirebaseFirestore.instance
        .collection('GARBAGE_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'type': 'Garbage Collection', ...doc.data()})
        .toList());

    final burialStream = FirebaseFirestore.instance
        .collection('BURIAL_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'type': 'Burial Service', ...doc.data()})
        .toList());

    final transportationStream = FirebaseFirestore.instance
        .collection('TRANSPORTATION_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'type': 'Lipat Bahay Service', ...doc.data()})
        .toList());

    // Combine all three streams into one
    return Rx.combineLatest3<List<Map<String, dynamic>>, List<Map<String, dynamic>>, List<Map<String, dynamic>>, List<Map<String, dynamic>>>(
      garbageStream,
      burialStream,
      transportationStream,
          (garbage, burial, transportation) => [
        ...garbage,
        ...burial,
        ...transportation,
      ]..sort((a, b) => b['created_at'].compareTo(a['created_at'])),
    );
  }


  Future<void> _refreshData() async {
    setState(() {
      _requestsStream = _listenToRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        elevation: 4,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No requests found'));
          }
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final request = snapshot.data![index];
                return _buildRequestCard(request);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    Color statusColor;
    switch (request['status']) {
      case 'pending':
        statusColor = Colors.yellow;
        break;
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'declined':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(request['type'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${request['status']}'),
            Text('Date: ${DateFormat('MM/dd/yyyy').format((request['created_at'] as Timestamp).toDate())}'),
          ],
        ),
        trailing: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        onTap: () => _showRequestDetails(request),
      ),
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.green.shade800, size: 28),
                    SizedBox(width: 8),
                    Text(
                      request['type'],
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                Card(
                  color: Colors.green.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green.shade700),
                            SizedBox(width: 8),
                            Text(
                              'Status: ${request['status']}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.date_range, color: Colors.green.shade700),
                            SizedBox(width: 8),
                            Text(
                              'Date: ${DateFormat('MM/dd/yyyy').format((request['created_at'] as Timestamp).toDate())}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (request.containsKey('note'))
                          Row(
                            children: [
                              Icon(Icons.note, color: Colors.green.shade700),
                              SizedBox(width: 8),
                              Text(
                                'Note: ${request['note']}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Card(
                  color: Colors.green.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                        SizedBox(height: 8),
                        if (request['type'] == 'Garbage Collection')
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Address: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: request['location']['address']),
                              ],
                            ),
                            style: TextStyle(fontSize: 16),
                          )
                        else if (request['type'] == 'Burial Service' || request['type'] == 'Lipat Bahay Service')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: 'Pickup: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: request['pickup_location']['address']),
                                  ],
                                ),
                                style: TextStyle(fontSize: 16),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: 'Destination: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: request['destination_location']['address']),
                                  ],
                                ),
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        if (request.containsKey('first_name') && request.containsKey('last_name'))
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Name: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: '${request['first_name']} ${request['last_name']}'),
                              ],
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                        if (request.containsKey('contact_number'))
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Contact Number: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: request['contact_number']),
                              ],
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                        if (request.containsKey('email'))
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Email: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: request['email']),
                              ],
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                        if (request.containsKey('user_type'))
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'User Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: request['user_type']),
                              ],
                            ),
                            style: TextStyle(fontSize: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
