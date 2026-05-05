import 'dart:typed_data'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; 

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('item_images').child(fileName);
      
      Uint8List imageBytes = await imageFile.readAsBytes();
      
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> addMarketplaceItem({
    required String title,
    required double price,
    required String description,
    required String category,
    required String imageUrl, 
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

      // NEW FIX: Fallback to email prefix if name is missing in database
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
        'imageUrl': imageUrl, 
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

  Future<String?> deleteItem(String docId, String imageUrl) async {
    try {
      await _firestore.collection('items').doc(docId).delete();
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (e) {
        print("Note: Could not delete image from storage: $e");
      }
      return null; 
    } catch (e) {
      return e.toString();
    }
  }
}