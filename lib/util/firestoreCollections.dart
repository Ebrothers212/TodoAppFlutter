import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:flutter/material.dart';
import '../util/userController.dart';

class FirestoreCollections {

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String users = 'users';
  static const String tasks = 'tasks';

  static Future<bool> saveUser(User user, BuildContext context) async {
    final usernames = await _firestore.collection(users).get();
    if (usernames.docs.any((doc) => doc.data()['username'] == user.username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username already exists'),
        ),
      );
      return false;
    }
    await _firestore.collection(users).doc(user.id).set(user.toJson());
    return true;
  }

  static Future<User?> getUser(String username, String password, BuildContext context) async {
    final user = await _firestore.collection(users).where('username', isEqualTo: username).where('password', isEqualTo: password).get();
    if (user.docs.isNotEmpty) {
      UserController.setUserSession(User.fromJson(user.docs.first.data()));
      return User.fromJson(user.docs.first.data());
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid username or password'),
        ),
      );
    }
    return null;
  }
}

