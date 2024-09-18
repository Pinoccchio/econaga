import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function for Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the Google Authentication flow
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser != null) {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication gAuth = await gUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        // Sign in with the Google credential
        final authResult = await _auth.signInWithCredential(credential);

        // Create a new user in Firestore or update the existing user
        await createUserInFirestore(authResult.user!.email!);

        return authResult;
      } else {
        throw Exception('Google Sign-In failed: User was null');
      }
    } catch (e) {
      print('Google Sign-In failed: $e');
      rethrow;
    }
  }

  // Function to create or update a user in Firestore
  Future<void> createUserInFirestore(String email) async {
    try {
      final userDoc = _firestore.collection('users').doc(email);

      final userSnapshot = await userDoc.get();
      if (!userSnapshot.exists) {
        // If the user doesn't exist, create a new document
        await userDoc.set({
          'email': email,
          'createdAt': Timestamp.now(),
          // Add any other user information you want to store
        });
      } else {
        // Optionally, update the user document if needed
        await userDoc.update({
          'lastSignIn': Timestamp.now(),
          // Update any other user information you want
        });
      }
    } catch (e) {
      print('Error creating/updating user in Firestore: $e');
      rethrow;
    }
  }

  // Function to check if the user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Function to get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Function to sign out
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }
}
