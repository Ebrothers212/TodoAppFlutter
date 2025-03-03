import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:flutter/material.dart';

class UserController {
  static User? _userSession;

  static void setUserSession(User user) {
    _userSession = user;
  }

  static void clearUserSession() {
    _userSession = null;
  }
  
  
}