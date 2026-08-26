import 'package:firebase_auth/firebase_auth.dart';
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

    final remember =
        prefs.getBool('admin_remember_me') ?? false;

    if (remember) {
      final email =
          prefs.getString('admin_email') ?? '';

      final password =
          prefs.getString('admin_password') ?? '';

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
      await prefs.setBool(
        'admin_remember_me',
        true,
      );

      await prefs.setString(
        'admin_email',
        _usernameController.text.trim(),
      );

      await prefs.setString(
        'admin_password',
        _passwordController.text,
      );
    } else {
      await prefs.setBool(
        'admin_remember_me',
        false,
      );

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
      final credential =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final token =
          await credential.user?.getIdTokenResult(true);

      if (token?.claims?['admin'] != true) {
        await FirebaseAuth.instance.signOut();

        throw FirebaseAuthException(
          code: 'not-admin',
          message:
              'This account is not an administrator.',
        );
      }

      await _handleRememberMe();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainApp(
            isAdmin: true,
            rememberMe: _rememberMe,
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin sign-in failed: '
            '${error.message ?? error.code}',
          ),
        ),
      );
    }
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
        backgroundColor: ccmRed,
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
                      color:
                          ccmRed.withValues(alpha: 0.1),
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
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ccmRed,
                        ),
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
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(
                          color: ccmRed,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
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

                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: ccmRed,
                      ),

                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
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
                        borderRadius:
                            BorderRadius.circular(12),
                      ),

                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(
                          color: ccmRed,
                          width: 2,
                        ),
                      ),
                    ),

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
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
                        _rememberMe =
                            value ?? false;
                      });
                    },

                    title:
                        const Text('Remember Me'),

                    activeColor: ccmRed,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor: ccmRed,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
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
                      style: TextStyle(
                        color: ccmRed,
                      ),
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