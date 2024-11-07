import 'package:flutter/foundation.dart';

class User extends ChangeNotifier {
  String? username;
  String? token;
  String? refreshToken;
  int? id;
  String? imageUrl;
  String? role;
  String? email;

  User(
      {required this.username,
      required this.id,
      required this.imageUrl,
      required this.token,
      required this.role,
      required this.email,
      required this.refreshToken});

  // Factory method to create a User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['user']['username'],
      id: json['user']['id'],
      role: json['user']['role'],
      imageUrl: json['user']['image'],
      token: json['access'],
      refreshToken: json['refresh'],
      email: json['user']['email'],
    );
  }

  // Method to update the user details and notify listeners
  void updateUser(User newUser) {
    username = newUser.username;
    id = newUser.id;
    imageUrl = newUser.imageUrl;
    token = newUser.token;
    role = newUser.role;
    email = newUser.email;
    notifyListeners(); // Notify listeners that the user has been updated
  }

  // Method to update only the token

  // Check if the user is a student
  bool isStudent() {
    return role == 'student';
  }

  // Display user information in the console (for debugging)
  void display() {
    print('Username: $username');
    print('Email: $email');
    print('Token: $token');
  }
}
