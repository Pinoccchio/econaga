  import 'package:flutter/material.dart';

  class ApprovalDialog extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.all(16.0),
        backgroundColor: Colors.green[50], // Light green background for the dialog
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon section with green background
            Container(
              width: 80, // Adjust size as needed
              height: 80, // Adjust size as needed
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green, // Background color
              ),
              child: Center(
                child: Icon(
                  Icons.access_time, // Clock icon
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'PENDING APPROVAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.green[800], // Darker green for text
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Waste management ensures environmental waste collection',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87), // Dark text for better readability
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.green[800]), // Darker green for button text
            ),
          ),
        ],
      );
    }
  }
