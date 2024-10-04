import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GarbageServiceRequest extends StatelessWidget {
  final List<Map<String, String>> requests = [
    {
      'name': 'Maria Isidro',
      'details': 'Naga, Camarines Sur, 1 Bag of Recyclable Trash',
      'initials': 'MI',
      'color': '0xFF7ED957',
    },
    {
      'name': 'Mary Ann Gavarra',
      'details': 'Naga, Camarines Norte',
      'initials': 'MA',
      'color': '0xFFFF69B4',
    },
    {
      'name': 'Joyce Macaubay',
      'details': 'Nabua, Camarines Sur',
      'initials': 'JM',
      'color': '0xFF1E90FF',
    },
    {
      'name': 'Alejandro Sicad',
      'details': 'Camaligan',
      'initials': 'AS',
      'color': '0xFFFFA500',
    },
    {
      'name': 'Alma Cresidio',
      'details': 'Iriga',
      'initials': 'AC',
      'color': '0xFF32CD32',
    },
  ];

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
              'Garbage Collection Service',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: requests.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final request = requests[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(int.parse(request['color']!)),
                    child: Text(
                      request['initials']!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    request['name']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    request['details']!,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}