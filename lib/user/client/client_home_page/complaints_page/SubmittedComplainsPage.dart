import 'package:econaga_prj/designs/app_colors.dart';
import 'package:flutter/material.dart';

import 'ComplaintDetailsPage.dart';

class SubmittedComplaintsPage extends StatefulWidget {
  @override
  _SubmittedComplaintsPageState createState() =>
      _SubmittedComplaintsPageState();
}

class _SubmittedComplaintsPageState extends State<SubmittedComplaintsPage> {
  // To track the resolved status of each complaint
  List<bool> isResolvedList = [false, false, false]; // Modify size based on your data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        title: Text('SUBMITTED COMPLAINTS'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: isResolvedList.length, // Replace with dynamic count of complaints
        itemBuilder: (context, index) {
          return GestureDetector(
            onLongPress: () {
              // Show options to delete or mark as resolved
              showMenuOptions(context, index);
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(
                    'lib/components/assets/images/official_logo.png'), // Placeholder image
              ),
              title: Text('To: Admin'),
              subtitle: Text('Magandang Araw, wala pong dumaan na Garbage truck...'),
              trailing: Text('3:30 AM'),
              tileColor: isResolvedList[index] ? Colors.lightGreen[200] : null, // Change background if resolved
              onTap: () {
                // Navigate to the complaint detail page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComplaintDetailPage(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Show options on long press
  void showMenuOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.check_circle),
              title: Text(isResolvedList[index] ? 'Unmark as Resolved' : 'Mark as Resolved'),
              onTap: () {
                // Toggle resolved status and update the UI
                setState(() {
                  isResolvedList[index] = !isResolvedList[index];
                });
                Navigator.pop(context); // Close the bottom sheet
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                // Delete the item and update the UI
                setState(() {
                  isResolvedList.removeAt(index);
                });
                Navigator.pop(context); // Close the bottom sheet
              },
            ),
          ],
        );
      },
    );
  }
}
