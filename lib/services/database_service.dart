import 'dart:typed_data'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; 

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // UPDATED: Now uploads multiple images and returns a list of URLs
  Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    List<String> urls = [];
    for (var imageFile in imageFiles) {
      try {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
        Reference ref = _storage.ref().child('item_images').child(fileName);
        
        Uint8List imageBytes = await imageFile.readAsBytes();
        UploadTask uploadTask = ref.putData(imageBytes);
        TaskSnapshot snapshot = await uploadTask;
        
        String url = await snapshot.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
    return urls;
  }

  // UPDATED: Saves an array of image URLs
  Future<String?> addMarketplaceItem({
    required String title,
    required double price,
    required String description,
    required String category,
    required List<String> imageUrls, 
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return "Error: User not logged in";

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      String sellerName = 'Unknown Seller';
      
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        sellerName = data['name'] ?? 'Unknown Seller';
      }

      if (sellerName == 'Unknown Seller' && user.email != null) {
        sellerName = user.email!.split('@')[0]; 
      }

      await _firestore.collection('items').add({
        'title': title,
        'price': price,
        'description': description,
        'category': category,
        'sellerId': user.uid,
        'sellerEmail': user.email,
        'sellerName': sellerName, 
        'imageUrls': imageUrls, // Store as an array
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return null; 
    } catch (e) {
      return e.toString(); 
    }
  }

  Stream<QuerySnapshot> getMarketplaceItems() {
    return _firestore
        .collection('items')
        .orderBy('createdAt', descending: true) 
        .snapshots(); 
  }

  // UPDATED: Deletes multiple images when deleting a post
  Future<String?> deleteItem(String docId, Map<String, dynamic> itemData) async {
    try {
      await _firestore.collection('items').doc(docId).delete();
      
      List<dynamic> urlsToDelete = [];
      // Support for new items with multiple images
      if (itemData['imageUrls'] != null) {
        urlsToDelete = itemData['imageUrls'] as List<dynamic>;
      } 
      // Backward compatibility for your older test items
      else if (itemData['imageUrl'] != null) {
        urlsToDelete = [itemData['imageUrl']];
      }

      for (String url in urlsToDelete) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (e) {
          print("Note: Could not delete image from storage: $e");
        }
      }
      return null; 
    } catch (e) {
      return e.toString();
    }
  }
}