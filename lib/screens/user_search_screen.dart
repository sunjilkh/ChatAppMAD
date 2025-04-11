import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  List<UserProfile> _chatHistory = [];
  bool _isLoading = false;

  Widget _buildAvatar(String? photoUrl, String username) {
    if (photoUrl == null) {
      return CircleAvatar(
        child: Text(username[0].toUpperCase()),
      );
    }
    
    return CircleAvatar(
      child: ClipOval(
        child: SvgPicture.network(
          photoUrl,
          width: 40,
          height: 40,
          placeholderBuilder: (context) => const CircularProgressIndicator(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _userService._auth.currentUser;
      if (currentUser != null) {
        final chatUsers = await _userService.getChatHistoryUsers(currentUser.uid);
        setState(() => _chatHistory = chatUsers);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chat history: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _userService.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search users: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUserList(List<UserProfile> users, {bool isChatHistory = false}) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          isChatHistory ? 'No chat history' : 'No users found',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: _buildAvatar(user.photoUrl, user.username),
          title: Text(user.username),
          subtitle: Text('@${user.username}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(otherUser: user),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Users'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Search'),
              Tab(text: 'Chat History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Search Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: _searchUsers,
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildUserList(_searchResults),
                ),
              ],
            ),
            // Chat History Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildUserList(_chatHistory, isChatHistory: true),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 