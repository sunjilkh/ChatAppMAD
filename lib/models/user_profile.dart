import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl;
  final String? status;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    this.photoUrl,
    this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      photoUrl: map['photoUrl'] as String?,
      status: map['status'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? username,
    String? photoUrl,
    String? status,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 