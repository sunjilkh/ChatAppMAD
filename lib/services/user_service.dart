import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new user profile
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
    } catch (e) {
      print('Error creating user profile: $e');
      throw Exception('Failed to create user profile');
    }
  }

  // Get user profile by ID
  Future<UserProfile> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      throw Exception('User profile not found');
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to get user profile');
    }
  }

  // Search users by username
  Future<List<UserProfile>> searchUsers(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: username)
          .where('username', isLessThanOrEqualTo: username + '\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  // Add user to chat list
  Future<void> addUserToChatList(String currentUserId, String otherUserId) async {
    try {
      final batch = _firestore.batch();
      
      // Add to current user's chat list
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'chatUsers': FieldValue.arrayUnion([otherUserId])
      });

      // Add to other user's chat list
      final otherUserRef = _firestore.collection('users').doc(otherUserId);
      batch.update(otherUserRef, {
        'chatUsers': FieldValue.arrayUnion([currentUserId])
      });

      await batch.commit();
    } catch (e) {
      print('Error adding user to chat list: $e');
      rethrow;
    }
  }

  Future<List<UserProfile>> getAvailableUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data()))
        .where((user) => user.uid != currentUser.uid)
        .toList();
  }

  Future<void> createOrUpdateChat(String currentUserId, String otherUserId) async {
    try {
      final chatId = [currentUserId, otherUserId]..sort();
      await _firestore.collection('chats').doc(chatId.join('_')).set({
        'participants': [currentUserId, otherUserId],
        'lastMessage': null,
        'lastMessageTime': null,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating chat: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).update(profile.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }
} 