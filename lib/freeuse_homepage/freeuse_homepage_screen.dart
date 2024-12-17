import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';

import '../user/login_as_screen/login_as_screen.dart';

class FreeUseHomePage extends StatelessWidget {
  const FreeUseHomePage({Key? key}) : super(key: key);

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 300,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.exit_to_app,
                  size: 48,
                  color: Color(0xFF4CAF50),
                ).animate().scale(duration: 300.ms, curve: Curves.easeInOut),
                SizedBox(height: 20),
                Text(
                  'Exit App?',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to exit the app?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        exit(0); // This will exit the app
                      },
                      child: Text('Exit'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context);
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    SizedBox(height: 24),
                    _buildAppInfo(),
                    SizedBox(height: 24),
                    _buildCarousel(),
                    SizedBox(height: 24),
                    _buildFeatures(),
                    SizedBox(height: 24),
                    _buildUserExpectations(),
                    SizedBox(height: 40),
                    Center(child: _buildSignInButton(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'EcoNaga',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade300,
                Colors.green.shade700,
              ],
            ),
          ),
          child: Image.asset(
            'lib/components/assets/images/official_logo.png',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.2),
            colorBlendMode: BlendMode.darken,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 300)),
        SlideEffect(begin: Offset(-0.2, 0), end: Offset.zero, duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 300)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to EcoNaga',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your eco-friendly waste management solution',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 500)),
        ScaleEffect(begin: Offset(0.8, 0.8), end: Offset(1, 1), duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 500)),
      ],
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About EcoNaga',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'EcoNaga is a comprehensive solid waste management app designed to make waste disposal easy and environmentally friendly. Join us in creating a cleaner, greener future!',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Our mission is to revolutionize waste management through technology and community engagement. Together, we can make a significant impact on our environment.',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    final List<String> imagePaths = [
      'lib/components/assets/images/truck-green-1.png',
      'lib/components/assets/images/truck-green-2.png',
      'lib/components/assets/images/truck-green-3.png',
      'lib/components/assets/images/truck-green-4.png',
      'lib/components/assets/images/truck-green-5.png',
    ];

    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 800), delay: Duration(milliseconds: 600)),
        ScaleEffect(begin: Offset(0.9, 0.9), end: Offset(1, 1), duration: Duration(milliseconds: 800), delay: Duration(milliseconds: 600)),
      ],
      child: CarouselSlider.builder(
        itemCount: imagePaths.length,
        itemBuilder: (context, index, realIndex) {
          return GestureDetector(
            onTap: () => _showImageDialog(context, imagePaths[index]),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePaths[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
        options: CarouselOptions(
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 3),
          autoPlayAnimationDuration: Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          viewportFraction: 0.8,
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatures() {
    final features = [
      {'icon': Icons.schedule, 'title': 'Easy Scheduling', 'description': 'Book waste collection at your convenience'},
      {'icon': Icons.eco, 'title': 'Eco-Friendly', 'description': 'Promoting sustainable waste management practices'},
      {'icon': Icons.track_changes, 'title': 'Real-time Tracking', 'description': 'Track your waste collection in real-time'},
      {'icon': Icons.recycling, 'title': 'Recycling Support', 'description': 'Get guidance on proper waste segregation and recycling'},
    ];

    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 800), delay: Duration(milliseconds: 700)),
        SlideEffect(begin: Offset(0, 0.2), end: Offset.zero, duration: Duration(milliseconds: 800), delay: Duration(milliseconds: 700)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Features',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 16),
          ...features.map((feature) => _buildFeatureItem(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature['icon'] as IconData, color: Colors.green.shade600, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  feature['description'] as String,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserExpectations() {
    final expectations = [
      {'icon': Icons.eco, 'title': 'Eco-Friendly Solutions', 'description': 'Contribute to a cleaner environment with our sustainable waste management practices.'},
      {'icon': Icons.access_time, 'title': 'Convenient Scheduling', 'description': 'Book waste collection services at times that suit your schedule.'},
      {'icon': Icons.track_changes, 'title': 'Real-Time Tracking', 'description': 'Monitor the status of your waste collection requests in real-time.'},
    ];

    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 800), delay: Duration(milliseconds: 800)),
        SlideEffect(begin: Offset(0, 0.2), end: Offset.zero, duration: Duration(milliseconds: 800), delay: Duration(milliseconds: 800)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Our Users Can Expect',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 16),
          ...expectations.map((expectation) => _buildExpectationItem(expectation)),
        ],
      ),
    );
  }

  Widget _buildExpectationItem(Map<String, dynamic> expectation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(expectation['icon'] as IconData, color: Colors.green.shade600, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expectation['title'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    expectation['description'] as String,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 900)),
        ScaleEffect(begin: Offset(0.8, 0.8), end: Offset(1, 1), duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 900)),
      ],
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginAsScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          elevation: 8,
        ),
        child: Text(
          'Begin Request',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

