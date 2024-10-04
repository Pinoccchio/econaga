import 'package:flutter/material.dart';
import '../../../../designs/app_colors.dart';

class ComplaintDetailPage extends StatefulWidget {
  @override
  _ComplaintDetailPageState createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  List<bool> isResolvedList = [false, false]; // Track resolved state for each message

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondaryGreen,
        title: Text('SUBMITTED COMPLAINTS'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildMessage(
                  sender: 'User',
                  text:
                  'Magandang Araw,\n\nWala pong dumaan na garbage truck kaninang umaga. Sana po ay maaksiyunan ito agad dahil nag-uumpisa nang mag-ipon ng basura sa aming lugar. Maraming salamat po.',
                  timestamp: 'July 23, 8:30 AM',
                  isUserMessage: true,
                  index: 0, // Corresponding to message index
                  avatarImage: 'lib/components/assets/images/sample-profile-pic.png', // Path to user avatar image
                ),
                _buildMessage(
                  sender: 'Admin',
                  text:
                  'Wala pong dumaan na garbage truck sa inyong lugar dahil nasiraan po ang truck na naka-assign. Pero agad naman pong gagawan ng paraan ngayong araw ang inyong reklamo. Salamat po.',
                  timestamp: 'July 23, 9:00 AM',
                  isUserMessage: false,
                  index: 1,
                  avatarImage: 'lib/components/assets/images/official_logo.png', // Path to admin avatar image
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type your message here...',
                      filled: true,
                      fillColor: Colors.grey[100], // Neutral background color
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25), // Rounded corners for a modern look
                        borderSide: BorderSide.none, // No border line
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Code to send the message
                    print('Message sent: ${_messageController.text}');
                    _messageController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(), backgroundColor: AppColors.secondaryGreen,
                    padding: EdgeInsets.all(14), // Matching the app bar color for consistency
                  ),
                  child: Icon(Icons.send, size: 28), // Larger icon
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMessage({
    required String sender,
    required String text,
    required String timestamp,
    required bool isUserMessage,
    required int index,
    required String avatarImage, // New parameter for avatar image path
  }) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          isResolvedList[index] = !isResolvedList[index]; // Toggle resolved status
        });
      },
      child: Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment:
          isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUserMessage) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(avatarImage), // Use the provided avatar image
              ),
              SizedBox(width: 8),
            ],
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: 240), // Adjusted width for avatar
              decoration: BoxDecoration(
                color: isResolvedList[index]
                    ? Colors.lightGreen[200]
                    : (isUserMessage ? Colors.lightGreen[100] : Colors.grey[300]),
                borderRadius: isUserMessage
                    ? BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                )
                    : BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUserMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    sender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUserMessage ? Colors.green[900] : Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(text),
                  SizedBox(height: 8),
                  Text(
                    timestamp,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isUserMessage) ...[
              SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(avatarImage), // Use the provided avatar image
              ),
            ],
          ],
        ),
      ),
    );
  }
}

