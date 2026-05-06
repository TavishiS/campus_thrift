import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'add_item_screen.dart';
import 'about_screen.dart';
import 'creator_screen.dart';
import 'feedback_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Filter variables
  String? _selectedCategoryFilter;
  String? _selectedSortOrder;

  final List<String> _baseCategories = ['Books', 'Stationery', 'Electronics', 'Utensils', 'Mattress', 'Toiletries', 'Cycle/Vehicle'];

  // Filter Dialog Box Logic
  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Sort'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sort by Price', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    RadioListTile<String?>(
                      title: const Text('None'),
                      value: null,
                      groupValue: _selectedSortOrder,
                      onChanged: (v) { setDialogState(() => _selectedSortOrder = v); setState((){}); },
                    ),
                    RadioListTile<String?>(
                      title: const Text('Low to High'),
                      value: 'asc',
                      groupValue: _selectedSortOrder,
                      onChanged: (v) { setDialogState(() => _selectedSortOrder = v); setState((){}); },
                    ),
                    RadioListTile<String?>(
                      title: const Text('High to Low'),
                      value: 'desc',
                      groupValue: _selectedSortOrder,
                      onChanged: (v) { setDialogState(() => _selectedSortOrder = v); setState((){}); },
                    ),
                    const Divider(),
                    const Text('Filter by Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedCategoryFilter,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Categories')),
                        ..._baseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        const DropdownMenuItem(value: 'Other', child: Text('Other (Custom Categories)')),
                      ],
                      onChanged: (v) { setDialogState(() => _selectedCategoryFilter = v); setState((){}); },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedSortOrder = null;
                      _selectedCategoryFilter = null;
                    });
                    setState(() {});
                  }, 
                  child: const Text('Clear All', style: TextStyle(color: Colors.red))
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  child: const Text('Apply Filter')
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusThrift Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: (_selectedCategoryFilter != null || _selectedSortOrder != null) ? Colors.yellowAccent : Colors.white),
            onPressed: _openFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text('CampusThrift', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About the App'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('From the Creator'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatorScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Submit Feedback'),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
              },
            ),
          ],
        ),
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

          List<Map<String, dynamic>> items = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            return data;
          }).toList();

          if (_selectedCategoryFilter != null) {
            if (_selectedCategoryFilter == 'Other') {
              items = items.where((item) => !_baseCategories.contains(item['category'])).toList();
            } else {
              items = items.where((item) => item['category'] == _selectedCategoryFilter).toList();
            }
          }

          if (_selectedSortOrder == 'asc') {
            items.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
          } else if (_selectedSortOrder == 'desc') {
            items.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
          }

          if (items.isEmpty) {
            return const Center(child: Text('No items found matching your filters.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ItemCard(
                itemData: items[index],
                docId: items[index]['docId'],
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

class ItemCard extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final String docId;
  final String currentUserId;

  const ItemCard({
    super.key, 
    required this.itemData, 
    required this.docId, 
    required this.currentUserId,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  int _currentImageIndex = 0; 

  // Helper method to encode query parameters
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // NATIVE MAILTO SYSTEM: Reliable way to open native email apps
  Future<void> _emailSeller(BuildContext context) async {
    final String email = widget.itemData['sellerEmail'] ?? '';
    final String title = widget.itemData['title'] ?? 'an item';
    
    // Create the mailto URI
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email, // Seller's email ID
      query: encodeQueryParameters(<String, String>{
        'subject': 'Interested in buying your item: $title',
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw Exception('Could not launch email app');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your email app.')),
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
      String? error = await DatabaseService().deleteItem(widget.docId, widget.itemData);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMyItem = widget.currentUserId == widget.itemData['sellerId'];
    
    List<dynamic> displayImages = [];
    if (widget.itemData['imageUrls'] != null && (widget.itemData['imageUrls'] as List).isNotEmpty) {
      displayImages = widget.itemData['imageUrls'];
    } else if (widget.itemData['imageUrl'] != null) {
      displayImages = [widget.itemData['imageUrl']];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MULTI-IMAGE SECTION
          Container(
            height: 250, 
            width: double.infinity,
            color: Colors.grey[800],
            child: displayImages.isNotEmpty
                ? Stack(
                    children: [
                      PageView.builder(
                        itemCount: displayImages.length,
                        onPageChanged: (index) => setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) {
                          return Image.network(
                            displayImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: Colors.teal));
                            },
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                      if (displayImages.length > 1)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              displayImages.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index ? Colors.teal : Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
                        widget.itemData['title'] ?? 'No Title',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${widget.itemData['price']?.toString() ?? '0'}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.itemData['category'] ?? 'Category', style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.itemData['description'] ?? 'No description provided.', 
                  style: const TextStyle(color: Colors.grey, fontSize: 14), 
                  maxLines: 3, 
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
                        widget.itemData['sellerName'] ?? 'Unknown Seller',
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
                        widget.itemData['sellerEmail'] ?? 'No email provided',
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
                      label: const Text('Contact Seller'),
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