import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  String? _selectedAvatar;
  
  // List of avatar URLs using different styles
  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/personas/svg?seed=Digital&backgroundColor=0ea5e9&hair=short&accessories=round&clothing=shirt&clothingColor=0f172a',
    'https://api.dicebear.com/7.x/personas/svg?seed=Tech&backgroundColor=6366f1&hair=short&accessories=round&clothing=shirt&clothingColor=1e293b',
    'https://api.dicebear.com/7.x/personas/svg?seed=Modern&backgroundColor=8b5cf6&hair=short&accessories=round&clothing=shirt&clothingColor=0f172a',
    'https://api.dicebear.com/7.x/personas/svg?seed=Innovation&backgroundColor=ec4899&hair=short&accessories=round&clothing=shirt&clothingColor=1e293b',
    'https://api.dicebear.com/7.x/personas/svg?seed=Future&backgroundColor=14b8a6&hair=short&accessories=round&clothing=shirt&clothingColor=0f172a',
    'https://api.dicebear.com/7.x/personas/svg?seed=Smart&backgroundColor=f59e0b&hair=short&accessories=round&clothing=shirt&clothingColor=1e293b',
    'https://api.dicebear.com/7.x/personas/svg?seed=Digital&backgroundColor=0ea5e9&hair=short&accessories=round&clothing=shirt&clothingColor=0f172a&gender=female',
    'https://api.dicebear.com/7.x/personas/svg?seed=Tech&backgroundColor=6366f1&hair=short&accessories=round&clothing=shirt&clothingColor=1e293b&gender=female',
    'https://api.dicebear.com/7.x/personas/svg?seed=Modern&backgroundColor=8b5cf6&hair=short&accessories=round&clothing=shirt&clothingColor=0f172a&gender=female',
    'https://api.dicebear.com/7.x/personas/svg?seed=Innovation&backgroundColor=ec4899&hair=short&accessories=round&clothing=shirt&clothingColor=1e293b&gender=female',
    'https://api.dicebear.com/7.x/personas/svg?seed=Future&backgroundColor=14b8a6&hair=short&accessories=round&clothing=shirt&clothingColor=0f172a&gender=female',
    'https://api.dicebear.com/7.x/personas/svg?seed=Smart&backgroundColor=f59e0b&hair=short&accessories=round&clothing=shirt&clothingColor=1e293b&gender=female',
  ];

  @override
  void initState() {
    super.initState();
    // Set a default avatar
    _selectedAvatar = _avatars[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatarSelector(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Register'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return Column(
      children: [
        const Text(
          'Choose Avatar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: SvgPicture.network(
              _selectedAvatar!,
              height: 100,
              width: 100,
              placeholderBuilder: (context) => const CircularProgressIndicator(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final avatar = _avatars[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedAvatar == avatar
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: SvgPicture.network(
                      avatar,
                      height: 50,
                      width: 50,
                      placeholderBuilder: (context) =>
                          const CircularProgressIndicator(),
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create Firebase Auth user
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // Create user profile
        final userProfile = UserProfile(
          uid: userCredential.user!.uid,
          email: _emailController.text,
          username: _usernameController.text,
          photoUrl: _selectedAvatar!,
          status: "Hey there! I'm using Chat App",
          createdAt: DateTime.now(),
        );

        await _userService.createUserProfile(userProfile);
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'An error occurred: ${e.message}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 