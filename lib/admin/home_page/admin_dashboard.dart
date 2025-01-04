import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class DashboardContent extends StatefulWidget {
  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    _DashboardPage(),
    _SecondPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToNextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPageIndex++;
      });
    }
  }

  void _navigateToPreviousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPageIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: _pages,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Row(
            children: [
              if (_currentPageIndex > 0)
                _buildNavigationArrow(
                  icon: Icons.arrow_back,
                  onTap: _navigateToPreviousPage,
                ),
              SizedBox(width: 10),
              if (_currentPageIndex < _pages.length - 1)
                _buildNavigationArrow(
                  icon: Icons.arrow_forward,
                  onTap: _navigateToNextPage,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/components/assets/images/admin_home_page_bg.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Promoting a cleaner and greener environment in the city of Naga',
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(2.0, 2.0),
                        blurRadius: 3.0,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Solid Waste Management Office-LGU Naga',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                Text(
                  'www.naga.gov.ph',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<_SecondPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ServiceRequest>> _events = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (_) => _loadEvents());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    Map<DateTime, List<ServiceRequest>> newEvents = {};

    DateTime now = DateTime.now();
    DateTime startDate = now.add(Duration(days: 3));
    DateTime endDate = now.add(Duration(days: 365)); // Fetch events for up to a year

    // Load Garbage Requests
    QuerySnapshot garbageSnapshot = await FirebaseFirestore.instance
        .collection('GARBAGE_REQUESTS')
        .where('status', isEqualTo: 'approved')
        .where('requested_date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('requested_date_time', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    for (var doc in garbageSnapshot.docs) {
      await _addEventToMap(newEvents, doc, 'Garbage Collection');
    }

    // Load Transportation Requests
    QuerySnapshot transportationSnapshot = await FirebaseFirestore.instance
        .collection('TRANSPORTATION_REQUESTS')
        .where('status', isEqualTo: 'approved')
        .where('requested_date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('requested_date_time', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    for (var doc in transportationSnapshot.docs) {
      await _addEventToMap(newEvents, doc, 'Transportation');
    }

    // Load Burial Requests
    QuerySnapshot burialSnapshot = await FirebaseFirestore.instance
        .collection('BURIAL_REQUESTS')
        .where('status', isEqualTo: 'approved')
        .where('requested_date_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('requested_date_time', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    for (var doc in burialSnapshot.docs) {
      await _addEventToMap(newEvents, doc, 'Burial');
    }

    setState(() {
      _events = newEvents;
    });
  }

  Future<void> _addEventToMap(Map<DateTime, List<ServiceRequest>> eventMap,
      QueryDocumentSnapshot doc, String serviceType) async {
    var data = doc.data() as Map<String, dynamic>;
    DateTime? requestDate;
    String pickupAddress = '';
    String destinationAddress = '';
    String note = '';

    if (serviceType == 'Garbage Collection') {
      var requestedDateTime = data['requested_date_time'] as Timestamp?;
      if (requestedDateTime != null) {
        requestDate = requestedDateTime.toDate();
      }
      var location = data['location'] as Map<String, dynamic>? ?? {};
      pickupAddress = location['address'] as String? ?? '';
      note = data['note'] as String? ?? '';
    } else {
      var requestedDateTime = data['requested_date_time'] as Timestamp?;
      if (requestedDateTime != null) {
        requestDate = requestedDateTime.toDate();
      }
      var pickupLocation = data['pickup_location'] as Map<String, dynamic>?;
      var destinationLocation = data['destination_location'] as Map<String, dynamic>?;
      if (pickupLocation != null) {
        pickupAddress = pickupLocation['address'] as String? ?? '';
      }
      if (destinationLocation != null) {
        destinationAddress = destinationLocation['address'] as String? ?? '';
      }
      note = data['note'] as String? ?? '';
    }

    if (requestDate != null) {
      DateTime normalizedDate = DateTime(requestDate.year, requestDate.month, requestDate.day);

      // Fetch user profile data
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(data['user_id'])
          .get();

      String profilePicture = '';
      if (userSnapshot.exists) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        profilePicture = userData['selfieImageUrl'] as String? ?? '';
      }

      ServiceRequest request = ServiceRequest(
        type: serviceType,
        requestorName: '${data['first_name']} ${data['last_name']}',
        time: DateFormat('h:mm a').format(requestDate),
        details: note,
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        userId: data['user_id'],
        profilePicture: profilePicture,
        contactNumber: data['contact_number'] as String? ?? '',
        email: data['email'] as String? ?? '',
        createdAt: (data['created_at'] as Timestamp?)?.toDate(),
        userType: data['user_type'] as String? ?? '',
      );

      if (eventMap[normalizedDate] == null) {
        eventMap[normalizedDate] = [];
      }
      eventMap[normalizedDate]!.add(request);
    }
  }

  List<ServiceRequest> _getEventsForDay(DateTime day) {
    DateTime now = DateTime.now();
    DateTime thresholdDate = now.add(Duration(days: 3));
    if (day.isBefore(thresholdDate)) {
      return [];
    }
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade900.withOpacity(0.8),
            Colors.green.shade700.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Service Requests Calendar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Card(
              margin: EdgeInsets.all(20.0),
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.now().subtract(Duration(days: 365)),
                    lastDay: DateTime.now().add(Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.green.shade300,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.green.shade800,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonDecoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      formatButtonTextStyle: TextStyle(color: Colors.white),
                      titleCentered: true,
                    ),
                    enabledDayPredicate: (day) {
                      return day.isAfter(DateTime.now().add(Duration(days: 2)));
                    },
                  ),
                  Expanded(
                    child: _selectedDay == null
                        ? Center(
                      child: Text(
                        'Select a day to view requests',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : _buildEventList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    List<ServiceRequest> events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Text(
          'No requests for this day',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: _getServiceColor(event.type),
              backgroundImage: event.profilePicture.isNotEmpty
                  ? CachedNetworkImageProvider(event.profilePicture)
                  : null,
              child: event.profilePicture.isEmpty
                  ? Icon(
                _getServiceIcon(event.type),
                color: Colors.white,
              )
                  : null,
            ),
            title: Text(
              event.requestorName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('${event.type} - ${event.time}'),
                SizedBox(height: 2),
                if (event.type == 'Garbage Collection')
                  Text('Address: ${event.pickupAddress}')
                else ...[
                  Text('Pickup: ${event.pickupAddress}'),
                  Text('Destination: ${event.destinationAddress}'),
                ],
                if (event.details.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text('Note: ${event.details}'),
                ],
              ],
            ),
            trailing: Icon(
              _getServiceIcon(event.type),
              color: _getServiceColor(event.type),
            ),
            isThreeLine: true,
            onTap: () => _showDetailDialog(context, event),
          ),
        );
      },
    );
  }

  void _showDetailDialog(BuildContext context, ServiceRequest event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: _getServiceColor(event.type),
                      backgroundImage: event.profilePicture.isNotEmpty
                          ? CachedNetworkImageProvider(event.profilePicture)
                          : null,
                      child: event.profilePicture.isEmpty
                          ? Icon(
                        _getServiceIcon(event.type),
                        color: Colors.white,
                        size: 50,
                      )
                          : null,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildDetailRow('Name', event.requestorName),
                  _buildDetailRow('Service Type', event.type),
                  _buildDetailRow('Time', event.time),
                  if (event.type == 'Garbage Collection')
                    _buildDetailRow('Address', event.pickupAddress)
                  else ...[
                    _buildDetailRow('Pickup Address', event.pickupAddress),
                    _buildDetailRow('Destination Address', event.destinationAddress),
                  ],
                  _buildDetailRow('Contact Number', event.contactNumber),
                  _buildDetailRow('Email', event.email),
                  _buildDetailRow('User Type', event.userType),
                  _buildDetailRow('Created At', event.createdAt != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(event.createdAt!)
                      : 'N/A'),
                  if (event.details.isNotEmpty)
                    _buildDetailRow('Note', event.details),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getServiceColor(String serviceType) {
    switch (serviceType) {
      case 'Transportation':
        return Colors.blue;
      case 'Burial':
        return Colors.purple;
      case 'Garbage Collection':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'Transportation':
        return Icons.directions_bus;
      case 'Burial':
        return Icons.church;
      case 'Garbage Collection':
        return Icons.delete;
      default:
        return Icons.event;
    }
  }
}

class ServiceRequest {
  final String type;
  final String requestorName;
  final String time;
  final String details;
  final String pickupAddress;
  final String destinationAddress;
  final String userId;
  final String profilePicture;
  final String contactNumber;
  final String email;
  final DateTime? createdAt;
  final String userType;

  ServiceRequest({
    required this.type,
    required this.requestorName,
    required this.time,
    required this.details,
    required this.pickupAddress,
    this.destinationAddress = '',
    required this.userId,
    required this.profilePicture,
    required this.contactNumber,
    required this.email,
    this.createdAt,
    required this.userType,
  });
}

