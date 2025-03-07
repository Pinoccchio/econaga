import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BurialFilteredRequestScreen extends StatefulWidget {
  final String status;
  final List<DocumentSnapshot> requests;

  const BurialFilteredRequestScreen({Key? key, required this.status, required this.requests}) : super(key: key);

  @override
  _BurialFilteredRequestScreenState createState() => _BurialFilteredRequestScreenState();
}

class _BurialFilteredRequestScreenState extends State<BurialFilteredRequestScreen> {
  late List<DocumentSnapshot> filteredRequests;
  String searchQuery = '';
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    filteredRequests = _getFilteredRequests(widget.requests);
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  List<DocumentSnapshot> _getFilteredRequests(List<DocumentSnapshot> allRequests) {
    return allRequests.where((request) {
      final data = request.data() as Map<String, dynamic>;
      return (data['status'] as String).toLowerCase() == widget.status.toLowerCase();
    }).toList();
  }

  void _filterRequests(String query) {
    if (!_mounted) return;
    setState(() {
      searchQuery = query.toLowerCase();
      filteredRequests = _getFilteredRequests(widget.requests).where((request) {
        final data = request.data() as Map<String, dynamic>;
        final fullName = '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.toLowerCase();
        return fullName.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _fetchRequests() async {
    if (!_mounted) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('BURIAL_REQUESTS')
          .orderBy('created_at', descending: true)
          .get();

      if (_mounted) {
        setState(() {
          filteredRequests = _getFilteredRequests(snapshot.docs);
        });
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching requests: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.status.capitalize()} Requests'),
        backgroundColor: _getStatusColor(widget.status),
      ),
      body: Column(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
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
    String userId = data['user_id'] ?? '';

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
            _buildProfilePicture(userId, firstName, lastName),
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
                    'Created: ${DateFormat('MM/dd/yyyy hh:mm a').format(requestDate)}',
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

  Widget _buildProfilePicture(String userId, String firstName, String lastName) {
    if (userId.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Center(
          child: Text(
            _getInitial(firstName, lastName),
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

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
                _getInitial(firstName, lastName),
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
                _getInitial(firstName, lastName),
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
              errorWidget: (context, url, error) => Text(
                _getInitial(firstName, lastName),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    // Extract location data safely
    final pickupLocation = data['pickup_location'] as Map<String, dynamic>? ?? {};
    final destinationLocation = data['destination_location'] as Map<String, dynamic>? ?? {};

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
                  _buildDetailItem("Pickup Address", pickupLocation['address'] ?? 'N/A'),
                  _buildDetailItem("Destination Address", destinationLocation['address'] ?? 'N/A'),
                  _buildDetailItem("Note", data['note'] ?? 'N/A'),
                  _buildDetailItem("Status", data['status'] ?? 'pending'),
                  _buildDetailItem("User Type", data['user_type'] ?? 'N/A'),
                  _buildDetailItem("Created Date/Time", DateFormat('MM/dd/yyyy hh:mm a').format((data['created_at'] as Timestamp).toDate())),
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
            width: 140,
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

String _getInitial(String firstName, String lastName) {
  if (firstName.isNotEmpty) {
    return firstName[0].toUpperCase();
  } else if (lastName.isNotEmpty) {
    return lastName[0].toUpperCase();
  } else {
    return '?';
  }
}

