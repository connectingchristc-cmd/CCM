import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../main_app.dart';

class MemberProfileSetupScreen extends StatefulWidget {
  final String userUid;
  final String phoneNumber;

  const MemberProfileSetupScreen({
    super.key,
    required this.userUid,
    required this.phoneNumber,
  });

  @override
  State<MemberProfileSetupScreen> createState() => _MemberProfileSetupScreenState();
}

class _MemberProfileSetupScreenState extends State<MemberProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userUid)
          .set({
            'fullName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'city': _cityController.text.trim(),
            'phoneNumber': widget.phoneNumber,
            'isAdmin': false,
            'role': 'member',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainApp(isAdmin: false, rememberMe: false),
        ),
        (route) => false,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile save failed: ${error.message ?? error.code}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1022),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Complete Profile'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 640,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151E34),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF3D4763)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to CCM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'First-time login detected. Please fill your details.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('Mobile Number'),
                    const SizedBox(height: 8),
                    _readonlyField(widget.phoneNumber),
                    const SizedBox(height: 16),
                    _label('Full Name *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _nameController,
                      hint: 'Enter your full name',
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Enter a valid name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Email'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _emailController,
                      hint: 'Optional',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(text)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('City'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _cityController,
                      hint: 'Optional',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ccmRed,
                          foregroundColor: ccmWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ccmWhite,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFFF6DC6E),
      fontWeight: FontWeight.w700,
      fontSize: 16,
    ),
  );

  Widget _readonlyField(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF212A40),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF3E4864)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: .45)),
        filled: true,
        fillColor: const Color(0xFF212A40),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3E4864)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4C341), width: 2),
        ),
      ),
    );
  }
}
