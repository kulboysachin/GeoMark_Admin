import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<User?> registerAdmin(
      String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Save user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': 'admin',
          'status': 'active',
        });

        // Initialize user presence in Realtime Database
        DatabaseReference userRef =
            _database.ref().child('user_locations/${user.uid}');
        userRef.set({'timestamp': ServerValue.timestamp});
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print("Registration Error: $e");
      }
      return null;
    }
  }

  Future<User?> loginAdmin(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Update user presence in Realtime Database
        DatabaseReference userRef =
            _database.ref().child('user_locations/${user.uid}');
        userRef.set({'timestamp': ServerValue.timestamp});
      }

      return user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  Future<void> logout() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Remove user presence from Realtime Database
      DatabaseReference userRef =
          _database.ref().child('user_locations/${user.uid}');
      await userRef.remove();
    }
    await _auth.signOut();
  }
}