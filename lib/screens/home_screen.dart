import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'add_item_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusThrift Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          )
        ],
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService().getMarketplaceItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No items for sale yet.\nBe the first to sell something!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              var itemData = items[index].data() as Map<String, dynamic>;
              String docId = items[index].id; 
              
              return ItemCard(
                itemData: itemData,
                docId: docId,
                currentUserId: currentUserId,
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen()));
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Sell'),
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final String docId;
  final String currentUserId;

  const ItemCard({
    super.key, 
    required this.itemData, 
    required this.docId, 
    required this.currentUserId,
  });

  // UPDATED FIX: 100% reliable Gmail composer link
  Future<void> _emailSeller(BuildContext context) async {
    final String email = itemData['sellerEmail'] ?? '';
    final String title = itemData['title'] ?? 'an item';
    
    // Properly encode parameters
    final String encodedSubject = Uri.encodeComponent('Interested in buying your item: $title');
    
    // This specific URL forces the browser/app to handle it as a Gmail compose window.
    // On mobile, it will prompt to open natively in the Gmail App with fields filled!
    final Uri gmailWebUri = Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=$encodedSubject');

    try {
      await launchUrl(
        gmailWebUri, 
        mode: LaunchMode.externalApplication, // Ensures it leaves the app to open the intent
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Gmail.')),
        );
      }
    }
  }

  Future<void> _deleteItem(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Sold?'),
        content: const Text('This will permanently delete the item from the feed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      String? error = await DatabaseService().deleteItem(docId, itemData['imageUrl'] ?? '');
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMyItem = currentUserId == itemData['sellerId'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE SECTION
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[800],
            child: itemData['imageUrl'] != null
                ? Image.network(
                    itemData['imageUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Colors.teal));
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  )
                : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
          ),
          
          // TEXT DETAILS SECTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        itemData['title'] ?? 'No Title',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${itemData['price']?.toString() ?? '0'}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(itemData['category'] ?? 'Category', style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Text(
                  itemData['description'] ?? 'No description provided.', 
                  style: const TextStyle(color: Colors.grey, fontSize: 14), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 12),

                // SELLER INFO SECTION
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        itemData['sellerName'] ?? 'Unknown Seller',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        itemData['sellerEmail'] ?? 'No email provided',
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // ACTION BUTTONS
                isMyItem 
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteItem(context),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Mark as Sold (Delete)', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _emailSeller(context),
                      icon: const Icon(Icons.email),
                      label: const Text('Contact Seller on Gmail'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}