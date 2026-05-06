import 'package:flutter/material.dart';

class CreatorScreen extends StatelessWidget {
  const CreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('From the Creator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal, 
                backgroundImage: AssetImage('assets/my_photo.jpg'), // Path to your file
              ),
            ),
            const SizedBox(height: 24),
            const Text('Hello folks!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 16),
            const Text(
              'I’m Tavishi Srivastava, currently a 4th year BTech. CSE student at IIT Jodhpur and the developer of CampusThrift 😃\n\nThis is a short note on my motivation behind building this app...\n\nCampus life becomes a lot easier when we help each other out. Yet, perfectly good items often go unused, while others are still searching for affordable essentials like books, cycles, and dorm needs.\n\nThat’s exactly why CampusThrift exists!! 🤩\n\nIt’s a simple idea — connect students who have something to give with those who need it. Save money, reduce waste, and make college life more convenient for everyone.\n\nWhether you’re looking to pass something on or find something useful, CampusThrift is here to make the process smooth, smart, and student-friendly.\n\nLet’s make our campus more connected — one exchange at a time :)\n\nI would be extremely pleased to hear from you for any suggestions/feedbacks regarding the app...\n\nFeel free to reach out through the Feedback section of the app or mail me at: tavishi.srivastava2004@gmail.com',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}