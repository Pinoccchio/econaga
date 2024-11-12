import 'package:econaga_prj/user/collector/collector_home_screen/approve_service_screen/transporation_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_screen.dart'; // Import the new MapScreen

class TransportationServiceRequest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Approved Requests',
          style: GoogleFonts.poppins(
            color: Colors.black,
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
            child: Text(
              'Transportation Service Request',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('TRANSPORTATION_REQUESTS')
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

                return ListView.separated(
                  itemCount: requests.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;
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

    final pickupLatitude = data['pickup_location']?['latitude'];
    final pickupLongitude = data['pickup_location']?['longitude'];
    final destinationLatitude = data['destination_location']?['latitude'];
    final destinationLongitude = data['destination_location']?['longitude'];

    final details = 'Pickup: $pickupLocation\nDestination: $destinationLocation\nService: $serviceType\nContact: $contact\n$note';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('USERS_ACCOUNTS')
          .doc(data['user_id'])
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildListTile(initials, data, details, context, null, pickupLatitude, pickupLongitude, destinationLatitude, destinationLongitude);
        }

        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final profilePicture = userData['profile_picture'];
          return _buildListTile(initials, data, details, context, profilePicture, pickupLatitude, pickupLongitude, destinationLatitude, destinationLongitude);
        } else {
          return _buildListTile(initials, data, details, context, null, pickupLatitude, pickupLongitude, destinationLatitude, destinationLongitude);
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
      double? pickupLatitude,
      double? pickupLongitude,
      double? destinationLatitude,
      double? destinationLongitude,
      ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
        backgroundColor: profilePicture == null ? Colors.grey : Colors.transparent,
        child: profilePicture == null
            ? Text(
          initials,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        )
            : null,
      ),
      title: Text(
        '${data['first_name']} ${data['last_name']}',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        details,
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'Details') {
            _showDetailsDialog(context, data, profilePicture);
          } else if (value == 'Visit') {
            // Pass pickup and destination coordinates to MapScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransportationMapScreen(userData: data),
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
        icon: Icon(Icons.more_vert),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> data, String? profilePicture) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${data['first_name']} ${data['last_name']}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
                    backgroundColor: profilePicture == null ? Colors.grey : Colors.transparent,
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
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                    children: [
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
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
