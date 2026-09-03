import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_colors.dart';
import '../main_app.dart';

class MemberFirstTimeDetailsScreen extends StatefulWidget {
  final String userUid;
  final String phoneNumber;

  const MemberFirstTimeDetailsScreen({
    super.key,
    required this.userUid,
    required this.phoneNumber,
  });

  @override
  State<MemberFirstTimeDetailsScreen> createState() =>
      _MemberFirstTimeDetailsScreenState();
}

class _MemberFirstTimeDetailsScreenState extends State<MemberFirstTimeDetailsScreen> {
  static const String _mockRegisteredMembersKey = 'mock_registered_members';
  static const String _mockActiveMemberPhoneKey = 'active_member_phone';
  static const String _mockActiveMemberNameKey = 'active_member_name';
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _placeController = TextEditingController();

  DateTime? _selectedDob;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDob = picked;
      _dobController.text = _formatDate(picked);
    });
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd-$mm-$yyyy';
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.userUid.startsWith('mock:')) {
        await _saveMockProfileAndContinue();
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userUid)
          .set({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'dob': _dobController.text.trim(),
            'place': _placeController.text.trim(),
            'phoneNumber': widget.phoneNumber,
            'role': 'member',
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      await _showWelcomePopupAndEnterApp();
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save details: ${error.message ?? error.code}'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save details: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveMockProfileAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = widget.phoneNumber;

    final registered = prefs.getStringList(_mockRegisteredMembersKey) ?? <String>[];
    if (!registered.contains(phone)) {
      registered.add(phone);
      await prefs.setStringList(_mockRegisteredMembersKey, registered);
    }

    final profileKey = 'mock_profile_$phone';
    await prefs.setStringList(profileKey, <String>[
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
      _dobController.text.trim(),
      _placeController.text.trim(),
    ]);

    final fullName = [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ').trim();
    await prefs.setString(_mockActiveMemberPhoneKey, phone);
    if (fullName.isNotEmpty) {
      await prefs.setString(_mockActiveMemberNameKey, fullName);
    }

    if (!mounted) {
      return;
    }

    await _showWelcomePopupAndEnterApp();
  }

  Future<void> _showWelcomePopupAndEnterApp() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final width = MediaQuery.sizeOf(dialogContext).width;
        final popupWidth = width > 460 ? 420.0 : width - 28;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Container(
            width: popupWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1830),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2B740), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: .45),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.asset(
                      'assets/welcome_popup.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _welcomeFallbackCard(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE4C341),
                          Color(0xFFF6E381),
                          Color(0xFFC46A1D),
                        ],
                      ),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: const Color(0xFF111D35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.favorite_border, size: 22),
                      label: const Text(
                        "Let's Get Started",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainApp(isAdmin: false, rememberMe: false),
      ),
      (route) => false,
    );
  }

  Widget _welcomeFallbackCard() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 0.95,
          colors: [Color(0xFF2A365B), Color(0xFF121B34)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        children: [
          Container(
            width: 108,
            height: 108,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4C341), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/WhatsApp Image 2026-08-25 at 00.38.49.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Welcome!',
            style: TextStyle(
              color: Color(0xFFF5D65A),
              fontSize: 46,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "You're In!",
            style: TextStyle(
              color: ccmWhite,
              fontSize: 44,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Thank you for being part of Connecting Christ Ministries.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ccmWhite.withValues(alpha: .92),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get ready for an uplifting journey\nfilled with faith, community, and God\'s love.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ccmWhite.withValues(alpha: .82),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1022),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Container(
              width: 760,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151E34),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF4B4A43)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'First Time Member Details',
                      style: TextStyle(
                        color: ccmWhite,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please fill all mandatory details to continue.',
                      style: TextStyle(
                        color: ccmWhite.withValues(alpha: .72),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('First Name *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _firstNameController,
                      hintText: 'Enter first name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Last Name *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _lastNameController,
                      hintText: 'Enter last name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('DOB (DD-MM-YYYY) *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDob,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'DOB is required';
                        }
                        return null;
                      },
                      style: const TextStyle(color: ccmWhite, fontSize: 17),
                      decoration: _fieldDecoration('Select date of birth').copyWith(
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFFE4C341),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Place *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _placeController,
                      hintText: 'Enter your place',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Place is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Phone Number'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222C43),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF59543A)),
                      ),
                      child: Text(
                        widget.phoneNumber,
                        style: const TextStyle(
                          color: ccmWhite,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ccmRed,
                          foregroundColor: ccmWhite,
                          disabledBackgroundColor: const Color(0xFF2A334A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
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
                                'Save',
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

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFF7DE71),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: ccmWhite, fontSize: 17),
      decoration: _fieldDecoration(hintText),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: ccmWhite.withValues(alpha: .5)),
      filled: true,
      fillColor: const Color(0xFF222C43),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF59543A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4C341), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}
