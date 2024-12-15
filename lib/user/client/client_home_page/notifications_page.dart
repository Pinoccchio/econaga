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

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pendingSubject = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  final _approvedSubject = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  final _declinedSubject = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  final _completedSubject = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _listenToRequests('pending', _pendingSubject);
    _listenToRequests('approved', _approvedSubject);
    _listenToRequests('declined', _declinedSubject);
    _listenToRequests('completed', _completedSubject);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      switch (_tabController.index) {
        case 0:
          _listenToRequests('pending', _pendingSubject);
          break;
        case 1:
          _listenToRequests('approved', _approvedSubject);
          break;
        case 2:
          _listenToRequests('declined', _declinedSubject);
          break;
        case 3:
          _listenToRequests('completed', _completedSubject);
          break;
      }
    }
  }

  void _listenToRequests(String status, BehaviorSubject<List<Map<String, dynamic>>> subject) {
    subject.add([]); // Clear the subject before adding new data

    void addData(List<Map<String, dynamic>> newData) {
      if (subject.hasValue) {
        final currentData = subject.value;
        final updatedData = [...currentData, ...newData]
          ..sort((a, b) {
            final aTimestamp = a['created_at'] as Timestamp?;
            final bTimestamp = b['created_at'] as Timestamp?;
            // Handle null values by treating them as older than non-null values
            if (aTimestamp == null) return 1; // a is older
            if (bTimestamp == null) return -1; // b is older
            return bTimestamp.compareTo(aTimestamp); // Sort descending
          });
        subject.add(updatedData);
      } else {
        subject.add(newData);
      }
    }

    FirebaseFirestore.instance
        .collectionGroup('GARBAGE_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'type': 'Garbage Collection', ...doc.data()})
        .toList())
        .listen(addData);

    FirebaseFirestore.instance
        .collectionGroup('BURIAL_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'type': 'Burial Service', ...doc.data()})
        .toList())
        .listen(addData);

    FirebaseFirestore.instance
        .collectionGroup('TRANSPORTATION_REQUESTS')
        .where('user_id', isEqualTo: widget.userId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {'type': 'Lipat Bahay Service', ...doc.data()})
        .toList())
        .listen(addData);
  }

  Future<void> _refreshData() async {
    final currentStatus = ['pending', 'approved', 'declined', 'completed'][_tabController.index];
    final currentSubject = [_pendingSubject, _approvedSubject, _declinedSubject, _completedSubject][_tabController.index];
    _listenToRequests(currentStatus, currentSubject);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _pendingSubject.close();
    _approvedSubject.close();
    _declinedSubject.close();
    _completedSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade600,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            _buildTab('Pending', _pendingSubject, Colors.yellow),
            _buildTab('Approved', _approvedSubject, Colors.blue),
            _buildTab('Declined', _declinedSubject, Colors.red),
            _buildTab('Complete', _completedSubject, Colors.green),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestStream(_pendingSubject),
          _buildRequestStream(_approvedSubject),
          _buildRequestStream(_declinedSubject),
          _buildRequestStream(_completedSubject),
        ],
      ),
    );
  }

  Widget _buildTab(String title, BehaviorSubject<List<Map<String, dynamic>>> subject, Color color) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: subject,
      builder: (context, snapshot) {
        int count = snapshot.data?.length ?? 0;
        return Tab(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(title),
              Positioned(
                right: 8,
                top: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestStream(BehaviorSubject<List<Map<String, dynamic>>> subject) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: subject,
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
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    Color statusColor;
    switch (request['status']) {
      case 'pending':
        statusColor = Colors.yellow;
        break;
      case 'approved':
        statusColor = Colors.blue;
        break;
      case 'declined':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    final createdAt = request['created_at'];
    // Format date and time together
    final formattedDateTime = (createdAt is Timestamp)
        ? DateFormat('MM/dd/yyyy hh:mm a').format(createdAt.toDate()) // MM/dd/yyyy hh:mm AM/PM format
        : 'N/A';

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
            Text('Date & Time: $formattedDateTime'), // Display the formatted date and time here
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
    final createdAt = request['created_at'];
    final formattedDateTime = (createdAt is Timestamp)
        ? DateFormat('MM/dd/yyyy hh:mm a').format(createdAt.toDate())
        : 'N/A';

    final contactNumber = request['contact_number'] ?? 'No contact number available';
    final email = request['email'] ?? 'No email available';
    final firstName = request['first_name'] ?? 'No first name available';
    final lastName = request['last_name'] ?? 'No last name available';
    final userType = request['user_type'] ?? 'No user type available';

    String addressInfo = '';
    if (request['type'] == 'Burial Service' || request['type'] == 'Lipat Bahay Service') {
      final pickupLocation = request['pickup_location']?['address'] ?? 'No pickup address available';
      final destinationLocation = request['destination_location']?['address'] ?? 'No destination address available';
      addressInfo = 'Pickup: $pickupLocation\nDestination: $destinationLocation';
    } else {
      addressInfo = request['location']?['address'] ?? 'No address available';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.green.shade800, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      request['type'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Card(
                  color: Colors.green.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Request Date: $formattedDateTime',
                      style: TextStyle(fontSize: 16, color: Colors.green.shade800),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Status: ${request['status']}',
                  style: TextStyle(fontSize: 18, color: Colors.green.shade800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Details:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  'User Type: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    userType,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ),

                _buildField('First Name:', firstName),
                _buildField('Last Name:', lastName),
                _buildField('Email:', email),
                _buildField('Contact Number:', contactNumber),
                _buildField('Address Information:', addressInfo),

                if (request['type'] == 'Garbage Collection')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Note:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          request['note'] ?? 'No note available',
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade800),
        ),
        Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

