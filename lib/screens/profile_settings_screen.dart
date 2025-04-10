import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _statusController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  UserProfile? _userProfile;
  String? _selectedAvatar;

  // List of avatar URLs using different styles
  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/personas/svg?seed=Professional&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/personas/svg?seed=Business&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/personas/svg?seed=Executive&backgroundColor=d1f4d9',
    'https://api.dicebear.com/7.x/personas/svg?seed=Corporate&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/personas/svg?seed=Manager&backgroundColor=ffd5dc',
    'https://api.dicebear.com/7.x/personas/svg?seed=Leader&backgroundColor=d1f4d9',
    'https://api.dicebear.com/7.x/personas/svg?seed=Director&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/personas/svg?seed=Officer&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/personas/svg?seed=Consultant&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/personas/svg?seed=Specialist&backgroundColor=ffd5dc',
    'https://api.dicebear.com/7.x/personas/svg?seed=Expert&backgroundColor=d1f4d9',
    'https://api.dicebear.com/7.x/personas/svg?seed=Analyst&backgroundColor=b6e3f4',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final profile = await _userService.getUserProfile(user.uid);
        setState(() {
          _userProfile = profile;
          _usernameController.text = profile.username;
          _statusController.text = profile.status ?? "Hey there! I'm using Chat App";
          _selectedAvatar = profile.photoUrl;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = _userProfile!.copyWith(
        username: _usernameController.text.trim(),
        status: _statusController.text.trim(),
        photoUrl: _selectedAvatar,
      );

      await _userService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAvatarSelector() {
    return Column(
      children: [
        const Text(
          'Choose Avatar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          child: _selectedAvatar != null
              ? SvgPicture.network(
                  _selectedAvatar!,
                  width: 80,
                  height: 80,
                )
              : const Icon(Icons.person, size: 50),
        ),
        const SizedBox(height: 16),
        Container(
          height: 100,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final avatarUrl = _avatars[index];
              final isSelected = _selectedAvatar == avatarUrl;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatarUrl),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.network(
                      avatarUrl,
                      width: 60,
                      height: 60,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarSelector(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  hintText: "What's on your mind?",
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _statusController.dispose();
    super.dispose();
  }
} 