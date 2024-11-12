import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminLipatBahayServiceRequest extends StatefulWidget {
  @override
  _AdminLipatBahayServiceRequestState createState() => _AdminLipatBahayServiceRequestState();
}

class _AdminLipatBahayServiceRequestState extends State<AdminLipatBahayServiceRequest> {
  String searchQuery = '';
  List<DocumentSnapshot> allRequests = [];
  List<DocumentSnapshot> filteredRequests = [];
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('TRANSPORTATION_REQUESTS')
        .orderBy('created_at', descending: true)
        .get();

    setState(() {
      allRequests = snapshot.docs;
      filteredRequests = allRequests;
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Lipat Bahay Service Requests'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRequestsHeader(filteredRequests.length),
          Expanded(
            child: filteredRequests.isEmpty
                ? Center(
              child: Text(
                'No requests available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : _buildRequestList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsHeader(int count) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Total Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.green,
            child: Text(
              count.toString(),
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Spacer(),
          Container(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              ),
              onChanged: _filterRequests,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    return ListView.builder(
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];
        final data = request.data() as Map<String, dynamic>;
        return _buildRequestCard(request, data);
      },
    );
  }

  Widget _buildRequestCard(DocumentSnapshot request, Map<String, dynamic> data) {
    String firstName = data['first_name'] as String? ?? '';
    String lastName = data['last_name'] as String? ?? '';
    String email = data['email'] as String? ?? '';
    String contactNumber = data['contact_number'] as String? ?? 'N/A';
    Map<String, dynamic> pickupLocation = data['pickup_location'] as Map<String, dynamic>? ?? {};
    Map<String, dynamic> destinationLocation = data['destination_location'] as Map<String, dynamic>? ?? {};
    String userId = data['user_id'] as String? ?? '';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text('$firstName $lastName', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('MM/dd/yyyy').format((data['created_at'] as Timestamp).toDate())),
        leading: _buildProfilePicture(userId),
        children: [
          ListTile(
            title: Text('Email'),
            subtitle: Text(email),
          ),
          ListTile(
            title: Text('Contact Number'),
            subtitle: Text(contactNumber),
          ),
          ListTile(
            title: Text('Pickup Location'),
            subtitle: _buildLocationInfo(pickupLocation),
          ),
          ListTile(
            title: Text('Destination Location'),
            subtitle: _buildLocationInfo(destinationLocation),
          ),
          ListTile(
            title: Text('Status'),
            subtitle: Text(data['status'] as String? ?? 'N/A'),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => updateRequestStatus(request.id, 'approved'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('APPROVE'),
                ),
                ElevatedButton(
                  onPressed: () => updateRequestStatus(request.id, 'declined'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('DECLINE'),
                ),
                ElevatedButton(
                  onPressed: () => _deleteRequest(request.id),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text('DELETE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(Map<String, dynamic> location) {
    String address = location['address'] as String? ?? 'N/A';
    double latitude = location['latitude'] as double? ?? 0.0;
    double longitude = location['longitude'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(address),
        Text('Lat: ${latitude.toStringAsFixed(6)}'),
        Text('Long: ${longitude.toStringAsFixed(6)}'),
      ],
    );
  }

  Widget _buildProfilePicture(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return CircleAvatar(child: Icon(Icons.person));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String profilePicUrl = userData['profile_picture'] as String? ?? '';
        return CircleAvatar(
          backgroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
          child: profilePicUrl.isEmpty ? Icon(Icons.person) : null,
        );
      },
    );
  }

  void _deleteRequest(String docId) {
    FirebaseFirestore.instance.collection('TRANSPORTATION_REQUESTS').doc(docId).delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request deleted successfully')),
      );
      _fetchRequests();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete request: $error')),
      );
    });
  }

  void updateRequestStatus(String docId, String status) {
    FirebaseFirestore.instance
        .collection('TRANSPORTATION_REQUESTS')
        .doc(docId)
        .update({'status': status}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request status updated to $status')),
      );
      _fetchRequests();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    });
  }
}