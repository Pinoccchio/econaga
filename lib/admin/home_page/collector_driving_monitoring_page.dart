import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorDriverMonitoringPage extends StatefulWidget {
  @override
  _CollectorDriverMonitoringPageState createState() =>
      _CollectorDriverMonitoringPageState();
}

class _CollectorDriverMonitoringPageState
    extends State<CollectorDriverMonitoringPage> {
  List<Map<String, dynamic>> filteredCollectors = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCollectors(String query) {
    setState(() {
      // Optional: If you want to filter locally
      filteredCollectors = filteredCollectors.where((collector) {
        return collector['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          onChanged: _filterCollectors,
          decoration: InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            fillColor: Colors.grey.shade200,
            filled: true,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('USERS_ACCOUNTS')
            .where('role', isEqualTo: 'collector')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          filteredCollectors = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': '${data['last_name']}, ${data['first_name']}',
              'availability': data['availability'] ?? 'Not Available',
              'image': data['selfieImageUrl'],
            };
          }).toList();

          // Apply search filter
          if (_searchController.text.isNotEmpty) {
            filteredCollectors = filteredCollectors.where((collector) {
              return collector['name'].toLowerCase().contains(_searchController.text.toLowerCase());
            }).toList();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text('Collector', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text('Availability', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredCollectors.length,
                    separatorBuilder: (context, index) => SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final collector = filteredCollectors[index];
                      return CollectorCard(
                        name: collector['name'],
                        availability: collector['availability'],
                        image: collector['image'],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CollectorCard extends StatelessWidget {
  final String name;
  final String availability;
  final String image;

  CollectorCard({
    required this.name,
    required this.availability,
    required this.image,
  });

  Color get availabilityColor {
    switch (availability) {
      case 'Available':
        return Colors.green;
      case 'Used':
        return Colors.red;
      case 'Not Available':
        return Colors.black;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
      ),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                  child: image.isEmpty ? Icon(Icons.person) : null,
                  radius: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                decoration: BoxDecoration(
                  color: availabilityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  availability.toUpperCase(),
                  style: TextStyle(color: availabilityColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
