import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to create a user with Firebase Auth
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  // Function to upload an image to Firebase Storage
  Future<String> uploadImageToFirebase(File imageFile, String storagePath) async {
    Reference storageReference = FirebaseStorage.instance.ref().child(storagePath);
    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // Function to save user data to Firestore
  Future<void> saveUserData(String userId, Map<String, dynamic> userData) async {
    await FirebaseFirestore.instance
        .collection('USERS_ACCOUNTS')
        .doc(userId)
        .set(userData);
  }

  // Function to send email verification to the currently signed-in user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}
