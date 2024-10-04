import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminGarbageCollectionRequest extends StatefulWidget {
  @override
  _AdminGarbageCollectionRequestState createState() => _AdminGarbageCollectionRequestState();
}

class _AdminGarbageCollectionRequestState extends State<AdminGarbageCollectionRequest> {
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
        .collection('GARBAGE_REQUESTS')
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
        final fullName = '${data['first_name']} ${data['last_name']}'.toLowerCase();
        return fullName.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200, // Adjust the scrolling distance
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200, // Adjust the scrolling distance
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Garbage Collection Requests'),
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRequests, // Refresh button action
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRequestsHeader(filteredRequests.length),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: _scrollLeft,
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  child: _buildDataTable(filteredRequests),
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: _scrollRight,
              ),
            ],
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

  Widget _buildDataTable(List<DocumentSnapshot> filteredRequests) {
    return DataTable(
      columnSpacing: 16,
      headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
      columns: [
        DataColumn(label: _buildHeaderText('Profile Picture')),
        DataColumn(label: _buildHeaderText('Name')),
        DataColumn(label: _buildHeaderText('Request Date')),
        DataColumn(label: _buildHeaderText('Email')),
        DataColumn(label: _buildHeaderText('Contact Number')),
        DataColumn(label: _buildHeaderText('Address')),
        DataColumn(label: _buildHeaderText('Note')),
        DataColumn(label: _buildHeaderText('Status')),
        DataColumn(label: _buildHeaderText('Actions')),
      ],
      rows: filteredRequests.map((request) {
        final data = request.data() as Map<String, dynamic>;
        String userId = data['user_id'];

        return DataRow(
          cells: [
            DataCell(_buildProfilePicture(userId)),
            DataCell(_buildUserCell('${data['first_name']} ${data['last_name']}')),
            DataCell(Text(DateFormat('MM/dd/yyyy').format((data['created_at'] as Timestamp).toDate()))),
            DataCell(Text(data['email'])),
            DataCell(Text(data['contact_number'])),
            DataCell(Text(data['location']['address'])),
            DataCell(
              Container(
                width: 150, // Set a width for the note cell
                child: Text(
                  data['note'] ?? 'N/A',
                  maxLines: 2, // Limit the number of lines
                  overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                ),
              ),
            ),
            DataCell(Text(data['status'] ?? 'pending')),
            DataCell(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => updateRequestStatus(request.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('APPROVE'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => updateRequestStatus(request.id, 'declined'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('DECLINE'),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProfilePicture(String userId) {
    // Fetch the user's profile picture from Firestore
    Future<DocumentSnapshot> fetchUserProfile(String userId) async {
      return await FirebaseFirestore.instance.collection('USERS_ACCOUNTS').doc(userId).get();
    }

    // Use a FutureBuilder to handle the asynchronous fetch
    return FutureBuilder<DocumentSnapshot>(
      future: fetchUserProfile(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Icon(Icons.person);
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String profilePicUrl = userData['profile_picture'] ?? '';
        return CircleAvatar(
          backgroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
          child: profilePicUrl.isEmpty ? Icon(Icons.person) : null,
        );
      },
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.green,
        fontSize: 16,
      ),
    );
  }

  Widget _buildUserCell(String name) {
    return Container(
      width: 150, // Set a width for the name cell
      child: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1, // Limit the number of lines
        overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
      ),
    );
  }

  void updateRequestStatus(String docId, String status) {
    FirebaseFirestore.instance
        .collection('GARBAGE_REQUESTS')
        .doc(docId)
        .update({'status': status}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request status updated to $status')),
      );
      _fetchRequests(); // Refresh the list after updating the status
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request: $error')),
      );
    });
  }
}
