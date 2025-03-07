import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import 'approve_service_screen/garbage_service_request.dart';
import 'completed_collections_viewer.dart';

class CollectorHomePage extends StatefulWidget {
  final String userId;

  CollectorHomePage({required this.userId});

  @override
  _CollectorHomePageState createState() => _CollectorHomePageState();
}

class _CollectorHomePageState extends State<CollectorHomePage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  late SharedPreferences prefs;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  GeoPoint? _collectorLocation;
  final double _maxDistance = 1000.0; // Maximum distance in meters (1 km)

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initSharedPreferences();
    _loadCollectorLocation();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _loadCollectorLocation() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final collectionZone = userData['collection_zone'] as Map<String, dynamic>?;
      if (collectionZone != null) {
        setState(() {
          _collectorLocation = collectionZone['coordinates'] as GeoPoint;
        });
        _loadEvents();
      }
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'new_requests',
      'New Requests',
      channelDescription: 'Notifications for new approved requests',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> _updateLastFetchedCount(int newCount) async {
    await prefs.setInt('lastFetchedCount', newCount);
  }

  void _handleApprovedRequests(int currentCount) async {
    int lastFetchedCount = prefs.getInt('lastFetchedCount') ?? 0;

    if (currentCount > lastFetchedCount) {
      int newRequests = currentCount - lastFetchedCount;
      _showNotification(
        'New Approved Request(s)',
        'You have $newRequests new approved request(s) in your collection zone.',
      );
    } else if (currentCount < lastFetchedCount) {
      _showNotification(
        'Requests Updated',
        'Some approved requests have been updated or removed.',
      );
    }

    _updateLastFetchedCount(currentCount);
  }

  Future<void> _loadEvents() async {
    if (_collectorLocation == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('GARBAGE_REQUESTS')
        .where('status', isEqualTo: 'approved')
        .get();

    setState(() {
      _events.clear();
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final location = data['location'] as Map<String, dynamic>?;
        if (location != null && location['latitude'] != null && location['longitude'] != null) {
          final requestLat = location['latitude'] as double;
          final requestLng = location['longitude'] as double;

          final distance = Geolocator.distanceBetween(
            _collectorLocation!.latitude,
            _collectorLocation!.longitude,
            requestLat,
            requestLng,
          );

          if (distance <= _maxDistance) {
            final requestDate = (data['requested_date_time'] as Timestamp).toDate();
            final event = {
              'type': 'GARBAGE_REQUESTS',
              'address': location['address'],
              'name': '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
              'requestData': data,
            };
            final dateKey = DateTime(requestDate.year, requestDate.month, requestDate.day);
            if (_events[dateKey] == null) {
              _events[dateKey] = [event];
            } else {
              _events[dateKey]!.add(event);
            }
          }
        }
      }
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildMainBanner(),
                  SizedBox(height: 24),
                  _buildCalendar(),
                  SizedBox(height: 24),
                  _buildStatisticsRow(context),
                  SizedBox(height: 24),
                  _buildManageCollectionSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String name = '${userData['first_name'] ?? ''} ${userData['middle_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
        String selfieImageUrl = userData['selfieImageUrl'] ?? '';

        return Row(
          children: [
            GestureDetector(
              onTap: () => _showProfileDialog(context, selfieImageUrl),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: selfieImageUrl.isNotEmpty
                      ? NetworkImage(selfieImageUrl)
                      : AssetImage('lib/components/assets/images/default_profile_pic.jpg') as ImageProvider,
                ),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Collector',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context, String profileImageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : AssetImage('lib/components/assets/images/default_profile_pic.jpg') as ImageProvider,
              ),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainBanner() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clean Environment,\nHappy Community',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your role in keeping our city clean',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Image.asset(
            'lib/components/assets/images/truck-green-collector.png',
            height: 100,
            width: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TableCalendar(
        firstDay: firstDay,
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!selectedDay.isBefore(firstDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: _getEventsForDay,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.green.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.deepOrange,
            shape: BoxShape.circle,
          ),
          disabledTextStyle: TextStyle(color: Colors.grey.shade400),
        ),
        enabledDayPredicate: (day) => !day.isBefore(firstDay),
      ),
    );
  }

  IconData _getIconForEventType(String type) {
    switch (type) {
      case 'GARBAGE_REQUESTS':
        return Icons.delete;
      case 'TRANSPORTATION_REQUESTS':
        return Icons.local_shipping;
      case 'BURIAL_REQUESTS':
        return Icons.church;
      default:
        return Icons.event;
    }
  }

  Widget _buildStatisticsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'GARBAGE_REQUESTS',
            'approved',
            'Approved\nRequests',
            'lib/components/assets/images/trashcan-collector.png',
            GarbageServiceRequest(userId: widget.userId),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'GARBAGE_REQUESTS',
            'completed',
            'Completed\nCollections',
            'lib/components/assets/images/trashcan-collector2.png',
            CompletedCollectionsViewer(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String collection, String status,
      String label, String imagePath, Widget destinationPage) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return _buildStatCardContent('...', label, imagePath);
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        var collectionZone = userData['collection_zone']?['coordinates'] as GeoPoint?;

        if (collectionZone == null) {
          return _buildStatCardContent('N/A', label, imagePath);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collection)
              .where('status', isEqualTo: status)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildStatCardContent('...', label, imagePath);
            }
            if (snapshot.hasError) {
              return _buildStatCardContent('Error', label, imagePath);
            }

            int count = snapshot.data?.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              if (data['location'] == null ||
                  data['location']['latitude'] == null ||
                  data['location']['longitude'] == null) {
                return false;
              }

              double requestLat = data['location']['latitude'];
              double requestLng = data['location']['longitude'];

              double distance = Geolocator.distanceBetween(
                collectionZone.latitude,
                collectionZone.longitude,
                requestLat,
                requestLng,
              );

              return distance <= _maxDistance;
            }).length ?? 0;

            if (status == 'approved') {
              _handleApprovedRequests(count);
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => destinationPage),
                );
              },
              child: _buildStatCardContent(count.toString(), label, imagePath),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCardContent(String number, String label, String imagePath) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                color: Colors.white.withOpacity(0.1),
                colorBlendMode: BlendMode.srcATop,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  number,
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageCollectionSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Collections',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Access real-time updates and optimize your route',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GarbageServiceRequest(userId: widget.userId),
                ),
              );
            },
            icon: Icon(Icons.visibility, color: Color(0xFF2E7D32)),
            label: Text(
              'View Approved Requests',
              style: GoogleFonts.poppins(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

