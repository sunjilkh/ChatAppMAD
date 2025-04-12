import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'models/user_profile.dart';
import 'models/message.dart';
import 'services/user_service.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  return const HomeScreen();
                }
                return const LoginScreen();
              },
            ),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  Map<String, int> _unreadCounts = {};
  List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _listenToUnreadMessages();
  }

  @override
  void dispose() {
    // Cancel all subscriptions when the widget is disposed
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _listenToUnreadMessages() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final chatSubscription = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        for (var doc in snapshot.docs) {
          final chatId = doc.id;
          final participants = List<String>.from(doc['participants'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => '',
          );

          if (otherUserId.isNotEmpty) {
            final messageSubscription = FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .where('receiverId', isEqualTo: currentUser.uid)
                .where('status', isEqualTo: MessageStatus.delivered.index)
                .snapshots()
                .listen((messages) {
              if (mounted) {
                setState(() {
                  _unreadCounts[otherUserId] = messages.docs.length;
                });
              }
            });
            _subscriptions.add(messageSubscription);
          }
        }
      });
      _subscriptions.add(chatSubscription);
    }
  }

  Future<void> _signOut() async {
    // Cancel all subscriptions before signing out
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildAvatar(String? photoUrl, String username) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          username[0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    // For SVG avatars from DiceBear
    if (photoUrl.contains('api.dicebear.com')) {
      return CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: SvgPicture.network(
            photoUrl,
            width: 40,
            height: 40,
            placeholderBuilder: (context) => Text(
              username[0].toUpperCase(),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    // For regular image URLs
    return CircleAvatar(
      backgroundImage: NetworkImage(photoUrl),
      onBackgroundImageError: (exception, stackTrace) {},
      child: Text(
        username[0].toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildUserListItem(UserProfile user) {
    final unreadCount = _unreadCounts[user.uid] ?? 0;
    
    return ListTile(
      leading: _buildAvatar(user.photoUrl, user.username),
      title: Text(user.username),
      subtitle: Text('@${user.username}'),
      trailing: unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(otherUser: user),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: Stream.fromFuture(UserService().getAvailableUsers()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users available'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserListItem(user);
            },
          );
        },
      ),
    );
  }
}
