import 'package:flutter/material.dart';

class UserDetails {
  const UserDetails({
    required this.username,
    required this.email,    
    required this.role,
    required this.dateCreated,
    required this.color,
  });

  final String username;
  final String email;  
  final String role;
  final DateTime dateCreated;
  final String color;
}