import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GarbageFilteredRequestScreen extends StatefulWidget {
  final String status;
  final List<DocumentSnapshot> requests;

  const GarbageFilteredRequestScreen({Key? key, required this.status, required this.requests}) : super(key: key);

  @override
  _GarbageFilteredRequestScreenState createState() => _GarbageFilteredRequestScreenState();
}

class _GarbageFilteredRequestScreenState extends State<GarbageFilteredRequestScreen> {
  late List<DocumentSnapshot> filteredRequests;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredRequests = widget.requests;
  }

  List<DocumentSnapshot> _getFilteredRequests(List<DocumentSnapshot> allRequests) {
    return allRequests.where((request) {
      final data = request.data() as Map<String, dynamic>;
      return (data['status'] as String).toLowerCase() == widget.status.toLowerCase();
    }).toList();
  }

  void _filterRequests(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredRequests = _getFilteredRequests(widget.requests).where((request) {
        final data = request.data() as Map<String, dynamic>;
        final fullName = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.toLowerCase();
        return fullName.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.status.capitalize()} Requests'),
        backgroundColor: _getStatusColor(widget.status),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('GARBAGE_REQUESTS').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<DocumentSnapshot> allRequests = snapshot.data!.docs;
          filteredRequests = _getFilteredRequests(allRequests);

          return Column(
            children: [
              _buildSearchBar(),
              if (filteredRequests.isEmpty)
                _buildEmptyState()
              else
                Expanded(
                  child: Column(
                    children: [
                      _buildListHeader(),
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
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No requests yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'There are no ${widget.status.toLowerCase()} requests at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        onChanged: _filterRequests,
        decoration: InputDecoration(
          hintText: 'Search by name',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
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
            flex: 1,
            child: Text(
              'Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(DocumentSnapshot request, Map<String, dynamic> data, int index) {
    String firstName = data['first_name'] ?? '';
    String lastName = data['last_name'] ?? '';
    DateTime requestDate = (data['created_at'] as Timestamp).toDate();
    DateTime requestedDateTime = (data['requested_date_time'] as Timestamp).toDate();
    String status = data['status'] ?? 'pending';

    return Container(
      margin: EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
              flex: 1,
              child: TextButton(
                onPressed: () => _showDetailsDialog(context, data),
                child: Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            _buildActionButtons(request.id, status),
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

  Widget _buildActionButtons(String docId, String currentStatus) {
    List<Widget> buttons = [];

    if (currentStatus != 'completed') {
      if (currentStatus != 'approved') {
        buttons.add(_buildActionButton('APPROVE', Colors.green, () => updateRequestStatus(docId, 'approved')));
      } else {
        buttons.add(_buildActionButton('PENDING', Colors.orange, () => updateRequestStatus(docId, 'pending')));
      }

      if (currentStatus != 'declined') {
        buttons.add(_buildActionButton('DECLINE', Colors.red, () => updateRequestStatus(docId, 'declined')));
      } else {
        buttons.add(_buildActionButton('PENDING', Colors.orange, () => updateRequestStatus(docId, 'pending')));
      }
    }

    return Row(
      children: buttons.map((button) => Padding(
        padding: EdgeInsets.only(left: 8),
        child: button,
      )).toList(),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  void updateRequestStatus(String docId, String newStatus) {
    FirebaseFirestore.instance
        .collection('GARBAGE_REQUESTS')
        .doc(docId)
        .update({'status': newStatus}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ${newStatus.toUpperCase()}'),
          backgroundColor: _getStatusColor(newStatus),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
            child: SingleChildScrollView(
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

