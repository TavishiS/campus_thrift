import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About CampusThrift')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome to CampusThrift!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 16),
            const Text(
              'CampusThrift is a dedicated marketplace app designed exclusively for college students. '
              'The purpose of this platform is to bridge the gap between senior students looking to declutter '
              'and junior students who need essential items at affordable prices.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text('How to use the app:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 12),
            const Text('• Sellers: Tap the "Sell" button, upload images, set a fair price, and list your items. Items can include books, cycles, mattresses, electronics, and more.', style: TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 8),
            const Text('• Buyers: Browse the feed or use filters to find what you need. Click "Contact Seller" to immediately open an email draft with the seller\'s email pre-filled.', style: TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 8),
            const Text('• Manage: Once an item is sold, the seller can simply click "Mark as Sold (Delete)" to remove it from the feed.', style: TextStyle(fontSize: 15, height: 1.4)),
            const Text('\n\nAdditionally, buyers can make use of filters at the top right corner to sort by price or category of items.', style: TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }
}