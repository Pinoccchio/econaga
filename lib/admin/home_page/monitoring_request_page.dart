import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class MonitoringRequestPage extends StatefulWidget {
  @override
  _MonitoringRequestPageState createState() => _MonitoringRequestPageState();
}

class _MonitoringRequestPageState extends State<MonitoringRequestPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _requestSubjects = [
    BehaviorSubject<List<Map<String, dynamic>>>(),
    BehaviorSubject<List<Map<String, dynamic>>>(),
    BehaviorSubject<List<Map<String, dynamic>>>(),
    BehaviorSubject<List<Map<String, dynamic>>>(),
  ];

  final List<String> _statuses = ['pending', 'approved', 'declined', 'completed'];
  final List<Color> _statusColors = [Colors.orange, Colors.blue, Colors.red, Colors.green];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _statuses.asMap().forEach((index, status) {
      _listenToRequests(status, _requestSubjects[index]);
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _listenToRequests(_statuses[_tabController.index], _requestSubjects[_tabController.index]);
    }
  }

  void _listenToRequests(String status, BehaviorSubject<List<Map<String, dynamic>>> subject) {
    final requestTypes = ['GARBAGE_REQUESTS', 'BURIAL_REQUESTS', 'TRANSPORTATION_REQUESTS'];
    final requests = <Map<String, dynamic>>[];

    requestTypes.forEach((type) {
      FirebaseFirestore.instance
          .collectionGroup(type)
          .where('status', isEqualTo: status)
          .snapshots()
          .listen((snapshot) {
        final newRequests = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'type': _getRequestTypeName(type),
            ...data,
          };
        }).toList();
        requests.addAll(newRequests);
        subject.add(requests);
      });
    });
  }

  String _getRequestTypeName(String type) {
    switch (type) {
      case 'GARBAGE_REQUESTS':
        return 'Garbage Collection';
      case 'BURIAL_REQUESTS':
        return 'Burial Service';
      case 'TRANSPORTATION_REQUESTS':
        return 'Lipat Bahay Service';
      default:
        return 'Unknown Service';
    }
  }

  Future<void> _refreshData() async {
    _listenToRequests(_statuses[_tabController.index], _requestSubjects[_tabController.index]);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _requestSubjects.forEach((subject) => subject.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green, // Green text color
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // Plain white background
        elevation: 0, // No shadow
        bottom: TabBar(
          controller: _tabController,
          tabs: List.generate(4, (index) => _buildTab(
            _statuses[index].capitalize(),
            _requestSubjects[index],
            _statusColors[index],
          )),
          indicatorColor: Colors.green, // Adjust the indicator color to match the text
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (index) => _buildRequestStream(_requestSubjects[index])),
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
              Text(title),
              if (count > 0)
                Container(
                  margin: EdgeInsets.only(top: 4),
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
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return Center(child: Text('No requests found'));
        }
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) => _buildRequestCard(data[index]),
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final createdAt = request['created_at'];
    final formattedDate = (createdAt is Timestamp)
        ? DateFormat('MMM dd, yyyy - HH:mm').format(createdAt.toDate())
        : 'N/A';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          request['type'] ?? 'Unknown Type',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text('${request['first_name'] ?? 'N/A'} ${request['last_name'] ?? ''}'),
            Text(request['email'] ?? 'No email provided'),
            Text(request['contact_number'] ?? 'No contact number'),
            SizedBox(height: 4),
            Text('Status: ${(request['status'] as String?)?.capitalize() ?? 'N/A'}'),
            Text('Date: $formattedDate'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () => _showRequestDetails(request),
      ),
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    final createdAt = request['created_at'];
    final formattedDate = (createdAt is Timestamp)
        ? DateFormat('MMMM dd, yyyy - HH:mm').format(createdAt.toDate())
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
                Text(
                  request['type'] ?? 'Unknown Type',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _detailItem('Name', '${request['first_name'] ?? 'N/A'} ${request['last_name'] ?? ''}'),
                _detailItem('Email', request['email'] ?? 'N/A'),
                _detailItem('Contact', request['contact_number'] ?? 'N/A'),
                _detailItem('User Type', (request['user_type'] as String?)?.capitalize() ?? 'N/A'),
                _detailItem('Status', (request['status'] as String?)?.capitalize() ?? 'N/A'),
                _detailItem('Date', formattedDate),
                if (request['type'] == 'Garbage Collection')
                  _detailItem('Location', request['location']?['address'] ?? 'N/A'),
                if (request['type'] == 'Lipat Bahay Service') ...[
                  _detailItem('Pickup', request['pickup_location']?['address'] ?? 'N/A'),
                  _detailItem('Destination', request['destination_location']?['address'] ?? 'N/A'),
                ],
                if (request['note'] != null)
                  _detailItem('Note', request['note']),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.indigo,
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

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    return this.isNotEmpty ? this[0].toUpperCase() + this.substring(1).toLowerCase() : this;
  }
}
