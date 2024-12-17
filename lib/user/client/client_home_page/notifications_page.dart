import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class NotificationPage extends StatefulWidget {
  final String userId;

  const NotificationPage({Key? key, required this.userId}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, BehaviorSubject<List<Map<String, dynamic>>>> _subjects = {
    'pending': BehaviorSubject<List<Map<String, dynamic>>>.seeded([]),
    'approved': BehaviorSubject<List<Map<String, dynamic>>>.seeded([]),
    'declined': BehaviorSubject<List<Map<String, dynamic>>>.seeded([]),
    'completed': BehaviorSubject<List<Map<String, dynamic>>>.seeded([]),
  };

  // Modern green color scheme
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFAED581);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color accentGreen = Color(0xFF69F0AE);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _subjects.keys.forEach((status) => _listenToRequests(status));
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _listenToRequests(_subjects.keys.elementAt(_tabController.index));
    }
  }

  void _listenToRequests(String status) {
    final subject = _subjects[status]!;
    subject.add([]); // Clear the subject before adding new data

    void addData(List<Map<String, dynamic>> newData) {
      if (subject.hasValue) {
        final currentData = subject.value;
        final updatedData = [...currentData, ...newData]
          ..sort((a, b) => (b['created_at'] as Timestamp?)?.compareTo(a['created_at'] as Timestamp? ?? Timestamp(0, 0)) ?? 0);
        subject.add(updatedData);
      } else {
        subject.add(newData);
      }
    }

    final collections = ['GARBAGE_REQUESTS', 'BURIAL_REQUESTS', 'TRANSPORTATION_REQUESTS'];
    for (var collection in collections) {
      FirebaseFirestore.instance
          .collection(collection)
          .where('user_id', isEqualTo: widget.userId)
          .where('status', isEqualTo: status)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => {
        'type': _getRequestType(collection),
        ...doc.data(),
        'id': doc.id,
      })
          .toList())
          .listen(addData);
    }
  }

  String _getRequestType(String collection) {
    switch (collection) {
      case 'GARBAGE_REQUESTS':
        return 'Garbage Collection';
      case 'BURIAL_REQUESTS':
        return 'Burial Service';
      case 'TRANSPORTATION_REQUESTS':
        return 'Lipat Bahay Service';
      default:
        return 'Unknown';
    }
  }

  Future<void> _refreshData() async {
    _listenToRequests(_subjects.keys.elementAt(_tabController.index));
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _subjects.values.forEach((subject) => subject.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: primaryGreen,
        colorScheme: ColorScheme.light(primary: primaryGreen, secondary: accentGreen),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryGreen,
          elevation: 0,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Requests',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            tabs: [
              _buildTab('Pending', _subjects['pending']!, Colors.orange),
              _buildTab('Approved', _subjects['approved']!, Colors.blue),
              _buildTab('Declined', _subjects['declined']!, Colors.red),
              _buildTab('Done', _subjects['completed']!, lightGreen),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _subjects.values.map((subject) => _buildRequestStream(subject)).toList(),
        ),
      ),
    );
  }

  Widget _buildTab(String title, BehaviorSubject<List<Map<String, dynamic>>> subject, Color color) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: subject,
      builder: (context, snapshot) {
        int count = snapshot.data?.length ?? 0;
        return Tab(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
              SizedBox(height: 2),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryGreen)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No requests found', style: TextStyle(color: darkGreen)));
        }
        return RefreshIndicator(
          onRefresh: _refreshData,
          color: primaryGreen,
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
    Color statusColor = _getStatusColor(request['status']);
    final createdAt = request['created_at'] as Timestamp?;
    final formattedDateTime = createdAt != null
        ? DateFormat('MM/dd/yyyy hh:mm a').format(createdAt.toDate())
        : 'N/A';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          request['type'],
          style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Status: ${request['status']}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 2),
            Text(
              'Date & Time: $formattedDateTime',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: primaryGreen),
        onTap: () => _showRequestDetails(request),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      case 'completed':
        return lightGreen;
      default:
        return Colors.grey;
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    final createdAt = request['created_at'] as Timestamp?;
    final formattedDateTime = createdAt != null
        ? DateFormat('MM/dd/yyyy hh:mm a').format(createdAt.toDate())
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailHeader(request),
                Divider(height: 24, color: lightGreen),
                _buildDetailItem('Request Date', formattedDateTime),
                _buildDetailItem('Status', request['status'], color: _getStatusColor(request['status'])),
                _buildDetailItem('User Type', request['user_type'] ?? 'N/A'),
                _buildDetailItem('Name', '${request['first_name']} ${request['last_name']}'),
                _buildDetailItem('Email', request['email'] ?? 'N/A'),
                _buildDetailItem('Contact', request['contact_number'] ?? 'N/A'),
                _buildAddressInformation(request),
                _buildNoteSection(request),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close', style: TextStyle(color: primaryGreen)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader(Map<String, dynamic> request) {
    return Row(
      children: [
        Icon(_getRequestTypeIcon(request['type']), color: primaryGreen, size: 28),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            request['type'],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
        ),
      ],
    );
  }

  IconData _getRequestTypeIcon(String type) {
    switch (type) {
      case 'Garbage Collection':
        return Icons.delete;
      case 'Burial Service':
        return Icons.church;
      case 'Lipat Bahay Service':
        return Icons.home;
      default:
        return Icons.assignment;
    }
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInformation(Map<String, dynamic> request) {
    if (request['type'] == 'Burial Service' || request['type'] == 'Lipat Bahay Service') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailItem('Pickup', request['pickup_location']?['address'] ?? 'N/A'),
          _buildDetailItem('Destination', request['destination_location']?['address'] ?? 'N/A'),
        ],
      );
    } else {
      return _buildDetailItem('Address', request['location']?['address'] ?? 'N/A');
    }
  }

  Widget _buildNoteSection(Map<String, dynamic> request) {
    final note = request['note'];
    if (note == null || note.isEmpty) {
      return SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text('Note:', style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen)),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lightGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: lightGreen),
          ),
          child: Text(note, style: TextStyle(color: darkGreen)),
        ),
      ],
    );
  }
}


