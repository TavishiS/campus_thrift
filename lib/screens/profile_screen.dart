import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Helper method to fetch the user's name from Firestore
  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] ?? 'User';
      }
    } catch (e) {
      // If there's an error, we will just use the fallback below
    }
    
    // Fallback: Use the part of their email before the @ symbol if name isn't found
    return user.email?.split('@')[0] ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: FutureBuilder<String>(
        future: _getUserName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final String userName = snapshot.data ?? 'User';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // FittedBox ensures that the massive font doesn't break the screen layout
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Hello $userName !! 🤠",
                      style: const TextStyle(
                        fontSize: 96, // Extremely large (4x the rest)
                        fontWeight: FontWeight.bold, // Bold
                        color: Colors.teal
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48), // Replaces the \n\n\n for better spacing
                  
                  const Text(
                    "We hope you're having a great time exploring CampusThrift ....\nDo explore the sections: About App, Creator's Corner and Feedback",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24, // Slightly bigger than the previous size 20
                      fontWeight: FontWeight.bold, // Bold text
                      height: 1.5, 
                      color: Colors.teal
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}