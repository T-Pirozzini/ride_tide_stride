import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


  Future<String> getUserNameString(String email) async {
    // Check if email is "Empty Slot", and avoid fetching from Firestore
    if (email == "Empty Slot") {
      return email;
    }

    // Proceed with fetching the username
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Users').doc(email).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return email;
    }
    var data = snapshot.data() as Map<String, dynamic>;
    return data['username'] ?? email;
  }