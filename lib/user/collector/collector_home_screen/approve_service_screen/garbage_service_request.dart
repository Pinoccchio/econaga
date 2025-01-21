import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'garbage_map_screen.dart';

class GarbageServiceRequest extends StatefulWidget {
  final String userId;

  GarbageServiceRequest({required this.userId});

  @override
  _GarbageServiceRequestState createState() => _GarbageServiceRequestState();
}

class _GarbageServiceRequestState extends State<GarbageServiceRequest> {
  String _filterOption = 'Within Zone';
  GeoPoint? _collectionZone;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCollectionZone();
    _getCurrentLocation();
  }

  Future<void> _loadCollectionZone() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      var userData = userDoc.data() as Map<String, dynamic>;
      if (userData['collection_zone'] != null &&
          userData['collection_zone']['coordinates'] != null) {
        setState(() {
          _collectionZone = userData['collection_zone']['coordinates'];
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Text(
        _filterOption,
        style: GoogleFonts.poppins(color: Colors.green[700], fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Approved Requests',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garbage Collection Service',
                  style: GoogleFonts.poppins(
                    color: Colors.green[800],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                _buildFilterDropdown(),
                SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('GARBAGE_REQUESTS')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No approved requests found.'));
                }

                final requests = snapshot.data!.docs;
                final filteredRequests = _filterRequests(requests);

                if (filteredRequests.isEmpty) {
                  return Center(child: Text('No requests found within the zone.'));
                }

                return ListView.builder(
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    final data = request.data() as Map<String, dynamic>;
                    data['request_id'] = request.id;
                    return _buildRequestTile(data, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  List<QueryDocumentSnapshot> _filterRequests(List<QueryDocumentSnapshot> requests) {
    return requests.where((request) {
      final data = request.data() as Map<String, dynamic>;
      if (data['location'] == null ||
          data['location']['latitude'] == null ||
          data['location']['longitude'] == null) {
        return false;
      }

      double requestLat = data['location']['latitude'];
      double requestLng = data['location']['longitude'];

      if (_collectionZone == null) {
        return false;
      }

      double distance = Geolocator.distanceBetween(
        _collectionZone!.latitude,
        _collectionZone!.longitude,
        requestLat,
        requestLng,
      );

      return distance <= 2000; // Within 1 km
    }).toList();
  }

  Widget _buildRequestTile(Map<String, dynamic> data, BuildContext context) {
    final initials = '${data['first_name'][0]}${data['last_name'][0]}';
    final location = data['location']['address'];
    final note = data['note'] != null ? 'Note: ${data['note']}' : 'No additional notes';
    final details = '$location\n$note';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(data['user_id'])
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildListTile(initials, data, details, context, null);
        }

        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final profilePicture = userData['selfieImageUrl'];
          return _buildListTile(initials, data, details, context, profilePicture);
        } else {
          return _buildListTile(initials, data, details, context, null);
        }
      },
    );
  }

  Widget _buildListTile(String initials, Map<String, dynamic> data, String details, BuildContext context, String? profilePicture) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
          backgroundColor: profilePicture == null ? Colors.green[300] : Colors.transparent,
          child: profilePicture == null
              ? Text(
            initials,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          )
              : null,
        ),
        title: Text(
          '${data['first_name']} ${data['last_name']}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.green[800],
          ),
        ),
        subtitle: Text(
          details,
          style: GoogleFonts.poppins(
            color: Colors.green[600],
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'Details') {
              _showDetailsDialog(context, data, profilePicture);
            } else if (value == 'Visit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GarbageMapScreen(userData: data),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 'Details',
                child: Text('Details', style: GoogleFonts.poppins()),
              ),
              PopupMenuItem(
                value: 'Visit',
                child: Text('Visit', style: GoogleFonts.poppins()),
              ),
            ];
          },
          icon: Icon(Icons.more_vert, color: Colors.green[700]),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data, String? profilePicture) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '${data['first_name']} ${data['last_name']}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.green[800],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
                    backgroundColor: profilePicture == null ? Colors.green[300] : Colors.transparent,
                    child: profilePicture == null
                        ? Text(
                      '${data['first_name'][0]}${data['last_name'][0]}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                ),
                SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.green[800]),
                    children: [
                      TextSpan(text: 'Email: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['email']}\n'),
                      TextSpan(text: 'Contact: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['contact_number']}\n'),
                      TextSpan(text: 'Location: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['location']['address']}\n'),
                      TextSpan(text: 'Latitude: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['location']['latitude']}\n'),
                      TextSpan(text: 'Longitude: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['location']['longitude']}\n'),
                      TextSpan(text: 'Note: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['note'] ?? 'No additional notes'}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}