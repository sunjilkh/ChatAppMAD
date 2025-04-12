import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user_profile.dart';
import '../models/message.dart';
import '../services/user_service.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final UserProfile otherUser;

  const ChatScreen({Key? key, required this.otherUser}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isOtherUserTyping = false;
  late String _chatId;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _chatId = _getChatId(currentUser.uid, widget.otherUser.uid);
      _loadMessages();
      _markMessagesAsSeen();
      _listenToTypingStatus();
    }
  }

  void _listenToTypingStatus() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final isTyping = data['isTyping'] ?? false;
        final typingUserId = data['typingUserId'] as String?;
        
        if (mounted) {
          setState(() {
            _isOtherUserTyping = isTyping && typingUserId == widget.otherUser.uid;
          });
        }
      }
    });
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .set({
        'isTyping': isTyping,
        'typingUserId': isTyping ? currentUser.uid : null,
      }, SetOptions(merge: true));
    }
  }

  void _onTextChanged(String text) {
    // Cancel previous timer
    _typingTimer?.cancel();
    
    // Update typing status to true
    _updateTypingStatus(true);
    
    // Set a timer to update typing status to false after 2 seconds of no typing
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _updateTypingStatus(false);
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Listen to messages in real-time
        FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          setState(() {
            _messages = snapshot.docs
                .map((doc) => Message.fromMap(doc.data()))
                .toList();
          });
          // Mark new messages as seen
          _markMessagesAsSeen();
        });

        // Add user to chat history
        await _userService.addUserToChatList(currentUser.uid, widget.otherUser.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markMessagesAsSeen() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final messages = await FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: MessageStatus.delivered.index)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in messages.docs) {
          batch.update(doc.reference, {'status': MessageStatus.seen.index});
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  String _getChatId(String uid1, String uid2) {
    final sortedIds = [uid1, uid2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final message = Message(
          senderId: currentUser.uid,
          receiverId: widget.otherUser.uid,
          content: _messageController.text.trim(),
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
        );

        final docRef = await FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .add(message.toMap());

        // Update status to delivered after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          docRef.update({'status': MessageStatus.delivered.index});
        });

        _messageController.clear();
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageStatus(Message message) {
    if (message.senderId != FirebaseAuth.instance.currentUser?.uid) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.seen:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMe = message.senderId == currentUser?.uid;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            _buildMessageStatus(message),
          ],
        ),
      ),
    );
  }

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

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'typing',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildAvatar(widget.otherUser.photoUrl, widget.otherUser.username),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUser.username),
                Text(
                  _isOtherUserTyping ? 'typing...' : '@${widget.otherUser.username}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length + (_isOtherUserTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _isOtherUserTyping) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildTypingIndicator(),
                          ),
                        );
                      }
                      final messageIndex = _isOtherUserTyping ? index - 1 : index;
                      return _buildMessageBubble(_messages[messageIndex]);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _updateTypingStatus(false);
    super.dispose();
  }
} 