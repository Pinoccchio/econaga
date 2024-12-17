import 'package:econaga_prj/user/collector/collector_home_screen/approve_service_screen/transporation_and_burial_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:geolocator/geolocator.dart';

class TransportationAndBurialServiceScreen extends StatefulWidget {
  final String userId;

  const TransportationAndBurialServiceScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<TransportationAndBurialServiceScreen> createState() => _TransportationAndBurialServiceScreenState();
}

class _TransportationAndBurialServiceScreenState extends State<TransportationAndBurialServiceScreen> {
  String _filterOption = 'Within Zone'; // Update 1
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

  List<QueryDocumentSnapshot> _filterRequests(List<QueryDocumentSnapshot> requests) {
    return requests.where((request) {
      final data = request.data() as Map<String, dynamic>;
      if (data['pickup_location'] == null ||
          data['pickup_location']['latitude'] == null ||
          data['pickup_location']['longitude'] == null) {
        return false;
      }

      double requestLat = data['pickup_location']['latitude'];
      double requestLng = data['pickup_location']['longitude'];

      if (_collectionZone == null) {
        return false;
      }

      double distance = Geolocator.distanceBetween(
        _collectionZone!.latitude,
        _collectionZone!.longitude,
        requestLat,
        requestLng,
      );

      return distance <= 1000; // Within 1 km // Update 3
    }).toList();
  }

  Widget _buildFilterDropdown() { // Update 2
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
        backgroundColor: Colors.green[600],
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
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.green[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transportation and Burial Service Requests',
                  style: GoogleFonts.poppins(
                    color: Colors.green[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Requests:',
                      style: GoogleFonts.poppins(
                        color: Colors.green[600],
                        fontSize: 14,
                      ),
                    ),
                    _buildFilterDropdown(),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QuerySnapshot>>(
              stream: Rx.combineLatest2(
                FirebaseFirestore.instance
                    .collection('TRANSPORTATION_REQUESTS')
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                FirebaseFirestore.instance
                    .collection('BURIAL_REQUESTS')
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                    (QuerySnapshot a, QuerySnapshot b) => [a, b],
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.green[600]));
                }
                if (!snapshot.hasData || snapshot.data!.every((qs) => qs.docs.isEmpty)) {
                  return Center(
                    child: Text(
                      'No approved requests found.',
                      style: GoogleFonts.poppins(color: Colors.green[800]),
                    ),
                  );
                }

                List<QueryDocumentSnapshot> allRequests = [];
                snapshot.data!.forEach((qs) => allRequests.addAll(qs.docs));

                final filteredRequests = _filterRequests(allRequests);

                if (filteredRequests.isEmpty) { // Update 4
                  return Center(
                    child: Text(
                      'No requests found within the zone.',
                      style: GoogleFonts.poppins(color: Colors.green[800]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredRequests.length,
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    final data = request.data() as Map<String, dynamic>;
                    data['request_id'] = request.id;
                    data['request_type'] = request.reference.parent.id == 'TRANSPORTATION_REQUESTS'
                        ? 'Transportation'
                        : 'Burial';
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

  Widget _buildRequestTile(Map<String, dynamic> data, BuildContext context) {
    final initials = '${data['first_name'][0]}${data['last_name'][0]}';
    final pickupLocation = data['pickup_location']?['address'] ?? 'Pickup location not available';
    final destinationLocation = data['destination_location']?['address'] ?? 'Destination location not available';
    final contact = data['contact_number'] ?? 'No contact available';
    final serviceType = data['service_type'] ?? 'No service type specified';
    final note = data['note'] != null ? 'Note: ${data['note']}' : 'No additional notes';

    final details = '${data['request_type']} Request\nPickup: $pickupLocation\nDestination: $destinationLocation\nService: $serviceType\nContact: $contact\n$note';

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

  Widget _buildListTile(
      String initials,
      Map<String, dynamic> data,
      String details,
      BuildContext context,
      String? profilePicture,
      ) {
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
                  builder: (context) => TransportationAndBurialMapScreen(userData: data),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 'Details',
                child: Text('Details', style: GoogleFonts.poppins(color: Colors.green[800])),
              ),
              PopupMenuItem(
                value: 'Visit',
                child: Text('Visit', style: GoogleFonts.poppins(color: Colors.green[800])),
              ),
            ];
          },
          icon: Icon(Icons.more_vert, color: Colors.green[600]),
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
                      TextSpan(text: 'Request Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['request_type']}\n'),
                      TextSpan(text: 'Email: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['email']}\n'),
                      TextSpan(text: 'Contact: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['contact_number']}\n'),
                      TextSpan(text: 'Pickup Location: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['pickup_location']?['address'] ?? 'No pickup location'}\n'),
                      TextSpan(text: 'Destination Location: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: '${data['destination_location']?['address'] ?? 'No destination location'}\n'),
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

