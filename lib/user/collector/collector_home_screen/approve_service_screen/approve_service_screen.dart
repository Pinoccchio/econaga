import 'package:econaga_prj/user/collector/collector_home_screen/approve_service_screen/transporation_service_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'garbage_service_request.dart';

class ApproveServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7ED957),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'APPROVE SERVICES',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: Image.asset(
                  'lib/components/assets/images/official_logo.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildServiceButton(
              'Transportation Services Requests',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TransportationServiceRequest()),
                    );
              },
            ),
            SizedBox(height: 10),
            _buildServiceButton(
              'Garbage collection Requests',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GarbageServiceRequest()),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceButton(String text, VoidCallback onPressed) {
    return Container(
      width: 300,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}