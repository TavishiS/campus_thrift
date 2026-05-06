import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();

  // Helper method to properly encode spaces and special characters for mailto links
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _sendFeedback() async {
    final feedbackText = _feedbackController.text.trim();
    
    if (feedbackText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write some feedback first!')),
      );
      return;
    }

    // Get the current user's email
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'Unknown User';

    const String targetEmail = 'tavishi.srivastava2004@gmail.com'; 

    // NATIVE MAILTO LINK
    // This tells the phone's OS to open the default mail app (like Gmail)
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: targetEmail,
      query: encodeQueryParameters(<String, String>{
        'subject': 'CampusThrift App Feedback',
        'body': 'User Email: $userEmail\n\nFeedback:\n$feedbackText',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        _feedbackController.clear(); // Clear the form
      } else {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your email app.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We value your feedback!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'Found a bug? Have a feature request? Or just want to say hi? Let us know below. This will open your email app directly to send a message to the developer.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Your Feedback',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                hintText: 'Type your suggestions or issues here...',
              ),
              maxLines: 6, 
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: _sendFeedback,
                icon: const Icon(Icons.send),
                label: const Text('Send to Developer', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}