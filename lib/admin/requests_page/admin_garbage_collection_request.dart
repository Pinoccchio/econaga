import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminGarbageCollectionRequest extends StatefulWidget {
  const AdminGarbageCollectionRequest({Key? key}) : super(key: key);

  @override
  _AdminGarbageCollectionRequestState createState() => _AdminGarbageCollectionRequestState();
}

class _AdminGarbageCollectionRequestState extends State<AdminGarbageCollectionRequest> {
  String searchQuery = '';
  List<DocumentSnapshot> allRequests = [];
  List<DocumentSnapshot> filteredRequests = [];
  Map<String, int> statusCounts = {
    'pending': 0,
    'approved': 0,
    'declined': 0,
    'completed': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('GARBAGE_REQUESTS')
        .orderBy('created_at', descending: true)
        .get();

    setState(() {
      allRequests = snapshot.docs;
      filteredRequests = allRequests;
      _updateStatusCounts();
    });
  }

  void _updateStatusCounts() {
    final counts = {
      'pending': 0,
      'approved': 0,
      'declined': 0,
      'completed': 0,
    };

    for (var request in allRequests) {
      final data = request.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'pending';
      counts[status.toLowerCase()] = (counts[status.toLowerCase()] ?? 0) + 1;
    }

    setState(() {
      statusCounts = counts;
    });
  }

  void _filterRequests(String query) {
    setState(() {
      searchQuery = query;
      filteredRequests = allRequests.where((request) {
        final data = request.data() as Map<String, dynamic>;
        final fullName = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.toLowerCase();
        return fullName.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Garbage Collection Request',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 24),
              _buildSearchBar(),
              SizedBox(height: 24),
              _buildStatusCards(),
              SizedBox(height: 24),
              _buildPendingHeader(),
              SizedBox(height: 16),
              Expanded(
                child: _buildRequestList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _filterRequests,
      ),
    );
  }

  Widget _buildStatusCards() {
    return Container(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusCard('Pending', statusCounts['pending'] ?? 0, Colors.orange),
          _buildStatusCard('Approved', statusCounts['approved'] ?? 0, Colors.green),
          _buildStatusCard('Declined', statusCounts['declined'] ?? 0, Colors.red),
          _buildStatusCard('Completed', statusCounts['completed'] ?? 0, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, int count, Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingHeader() {
    return Row(
      children: [
        Text(
          'Total Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${filteredRequests.length}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestList() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(width: 40), // Space for numbering
              SizedBox(width: 52), // Space for avatar
              Expanded(
                flex: 2,
                child: Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Request Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 160), // Space for action buttons
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final request = filteredRequests[index];
              final data = request.data() as Map<String, dynamic>;
              return _buildRequestCard(request, data, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(DocumentSnapshot request, Map<String, dynamic> data, int index) {
    String firstName = data['first_name'] ?? '';
    String lastName = data['last_name'] ?? '';
    DateTime requestDate = (data['created_at'] as Timestamp).toDate();
    DateTime requestedDateTime = (data['requested_date_time'] as Timestamp).toDate();
    String status = data['status'] ?? 'pending';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '$index.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            _buildProfilePicture(data['user_id'] ?? ''),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Created: ${DateFormat('MM/dd/yyyy').format(requestDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Requested: ${DateFormat('MM/dd/yyyy hh:mm a').format(requestedDateTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: _buildStatusBadge(status),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _showDetailsDialog(context, data),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            _buildActionButton(
              'APPROVE',
              Colors.green,
                  () => updateRequestStatus(request.id, 'approved'),
            ),
            SizedBox(width: 8),
            _buildActionButton(
              'DECLINE',
              Colors.red,
                  () => updateRequestStatus(request.id, 'declined'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'approved':
        badgeColor = Colors.green;
        break;
      case 'declined':
        badgeColor = Colors.red;
        break;
      case 'completed':
        badgeColor = Colors.blue;
        break;
      default:
        badgeColor = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProfilePicture(String userId) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
      ),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                userId.isNotEmpty ? userId[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          String profilePicUrl = userData['selfieImageUrl'] ?? '';

          if (profilePicUrl.isEmpty) {
            return Center(
              child: Text(
                userId[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: profilePicUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.person),
            ),
          );
        },
      ),
    );
  }

  void updateRequestStatus(String docId, String status) {
    FirebaseFirestore.instance
        .collection('GARBAGE_REQUESTS')
        .doc(docId)
        .get()
        .then((doc) {
      if (doc.exists) {
        String currentStatus = doc.data()!['status'];
        if (currentStatus == 'approved') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status cannot be changed once approved.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        } else {
          // Update status if not approved
          FirebaseFirestore.instance
              .collection('GARBAGE_REQUESTS')
              .doc(docId)
              .update({'status': status}).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Request ${status.toUpperCase()}'),
                backgroundColor: status == 'approved' ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            _fetchRequests(); // This will update both the list and the counts
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update status: $error'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          });
        }
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch request status: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Request Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                _buildDetailItem("Name", "${data['first_name']} ${data['last_name']}"),
                _buildDetailItem("Email", data['email'] ?? 'N/A'),
                _buildDetailItem("Contact Number", data['contact_number'] ?? 'N/A'),
                _buildDetailItem("Address", (data['location'] as Map<String, dynamic>)['address'] ?? 'N/A'),
                _buildDetailItem("Note", data['note'] ?? 'N/A'),
                _buildDetailItem("Status", data['status'] ?? 'pending'),
                _buildDetailItem("Created Date", DateFormat('MM/dd/yyyy').format((data['created_at'] as Timestamp).toDate())),
                _buildDetailItem("Requested Date/Time", DateFormat('MM/dd/yyyy hh:mm a').format((data['requested_date_time'] as Timestamp).toDate())),
                SizedBox(height: 24),
                TextButton(
                  child: Text(
                    "Close",
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

