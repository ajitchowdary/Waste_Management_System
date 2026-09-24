import 'package:flutter/material.dart';

class UserSession {
  final String id;
  final String username;
  final String fullName;
  final String role; // 'ADMIN', 'DRIVER', 'PLANT_OPERATOR'
  final String? driverId;
  final Map<String, dynamic>? driver;
  final String? token;

  UserSession({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.driverId,
    this.driver,
    this.token,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isDriver => role == 'DRIVER';
  bool get isOperator => role == 'PLANT_OPERATOR';

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'DRIVER',
      driverId: json['driverId'],
      driver: json['driver'],
      token: json['token'],
    );
  }
}

class AuthManager {
  static UserSession? currentUser;

  static bool get isLoggedIn => currentUser != null;

  static void login(UserSession session) {
    currentUser = session;
  }

  static void logout() {
    currentUser = null;
  }
}
