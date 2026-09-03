import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_colors.dart';
import '../main_app.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool('admin_remember_me') ?? false;

    if (remember) {
      final email = prefs.getString('admin_email') ?? '';

      final password = prefs.getString('admin_password') ?? '';

      if (!mounted) return;

      setState(() {
        _rememberMe = true;
        _usernameController.text = email;
        _passwordController.text = password;
      });
    }
  }

  Future<void> _handleRememberMe() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setBool('admin_remember_me', true);

      await prefs.setString('admin_email', _usernameController.text.trim());

      await prefs.setString('admin_password', _passwordController.text);
    } else {
      await prefs.setBool('admin_remember_me', false);

      await prefs.remove('admin_email');
      await prefs.remove('admin_password');
    }
  }

  void _login() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _signInAdmin();
  }

  Future<void> _signInAdmin() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final token = await credential.user?.getIdTokenResult(true);
      final user = credential.user;
      final hasClaimAdmin = token?.claims?['admin'] == true;
      final hasFirestoreAdmin =
          user != null && await _hasFirestoreAdminAccess(user.uid);

      if (!hasClaimAdmin && !hasFirestoreAdmin) {
        await FirebaseAuth.instance.signOut();

        throw FirebaseAuthException(
          code: 'not-admin',
          message:
              'This account does not have admin access. Set custom claim admin=true, '
              'or create admins/{uid} (or users/{uid} with role=admin/isAdmin=true).',
        );
      }

      await _handleRememberMe();
  await _saveAdminProfile(user);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainApp(isAdmin: true, rememberMe: _rememberMe),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin sign-in failed: ${_friendlyAuthError(error)}',
          ),
        ),
      );
    }
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a minute and try again.';
      case 'network-request-failed':
        return 'Network error. Check internet and try again.';
      case 'not-admin':
        return error.message ?? 'This account is not an administrator.';
      default:
        final message = error.message;
        if (message != null && message.isNotEmpty) {
          return '$message (${error.code})';
        }
        return error.code;
    }
  }

  Future<bool> _hasFirestoreAdminAccess(String uid) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final adminDoc = await firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        return true;
      }
    } catch (_) {
      // Ignore and continue with other admin marker checks.
    }

    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data();
      return data?['role'] == 'admin' || data?['isAdmin'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveAdminProfile(User? user) async {
    if (user == null) {
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final adminRef = firestore.collection('admins').doc(user.uid);
    final snapshot = await userRef.get();
    final adminSnapshot = await adminRef.get();
    final data = snapshot.data() ?? adminSnapshot.data();
    final email = user.email ?? _usernameController.text.trim();
    final existingName = (data?['fullName'] ?? data?['name'] ?? '').toString().trim();
    final displayName = existingName.isNotEmpty
        ? existingName
        : _displayNameFromEmail(email);

    final profileData = {
      'fullName': displayName,
      'name': displayName,
      'email': email,
      'role': 'admin',
      'isAdmin': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      if (!snapshot.exists && !adminSnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
    };

    await Future.wait([
      userRef.set(profileData, SetOptions(merge: true)),
      adminRef.set(profileData, SetOptions(merge: true)),
    ]);
  }

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'ADMIN';
    }

    final cleaned = localPart.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    final words = cleaned.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final titleCased = words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ')
        .trim();

    return titleCased.isEmpty ? localPart.toUpperCase() : titleCased;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCM Admin Login'),
        backgroundColor: ccmSandDark,
        foregroundColor: ccmInk,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ccmRed.withValues(alpha: 0.05),
              ccmBlue.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ccmRed.withValues(alpha: 0.1),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 72,
                      color: ccmRed,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Admin Access',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: ccmRed),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Admin email',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: ccmRed,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ccmRed, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter admin email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Admin Password',

                      prefixIcon: const Icon(Icons.lock_outline, color: ccmRed),

                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: ccmRed,
                        ),
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ccmRed, width: 2),
                      ),
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter admin password';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  CheckboxListTile(
                    value: _rememberMe,

                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },

                    title: const Text('Remember Me'),

                    activeColor: ccmRed,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ccmRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      onPressed: _login,

                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ccmWhite,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(color: ccmRed),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
