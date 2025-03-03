import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:flutter/material.dart';
class FirestoreCollections {

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String users = 'users';
  static const String tasks = 'tasks';

  static void saveUser(User user, BuildContext context) async {
    final usernames = await _firestore.collection(users).get();
    if (usernames.docs.any((doc) => doc.data()['username'] == user.username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username already exists'),
        ),
      );
      return;
    }
    _firestore.collection(users).doc(user.id).set(user.toJson());
    return;
  }
}

