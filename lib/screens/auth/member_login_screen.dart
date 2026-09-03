import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main_app.dart';
import 'admin_login_screen.dart';
import 'member_first_time_details_screen.dart';

class MemberLoginScreen extends StatefulWidget {
  const MemberLoginScreen({super.key});

  @override
  State<MemberLoginScreen> createState() => _MemberLoginScreenState();
}

class _MemberLoginScreenState extends State<MemberLoginScreen> {
  static const bool _useMockOtp = true;
  static const String _mockOtp = '1234';
  static const String _mockRegisteredMembersKey = 'mock_registered_members';
  static const String _mockActiveMemberPhoneKey = 'active_member_phone';
  static const String _mockActiveMemberNameKey = 'active_member_name';
  static const int _otpLength = 4;
  static const int _smsAutoRetrieveTimeoutSeconds = 120;
  static const int _otpTtlSeconds = 180;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isSubmittingOtp = false;
  bool _otpRequested = false;

  int _secondsLeft = 0;
  Timer? _timer;

  String? _verificationId;
  int? _resendToken;
  String? _errorText;

  bool get _isPhoneValid =>
      RegExp(r'^[0-9]{10}$').hasMatch(_phoneController.text.trim());

  bool get _isOtpValid =>
      RegExp(r'^[0-9]{4}$').hasMatch(_otpController.text.trim());

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp({bool resend = false}) async {
    if (!_isPhoneValid || _isSendingOtp) {
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorText = null;
    });

    final phone = _phoneController.text.trim();

    if (_useMockOtp) {
      setState(() {
        _otpRequested = true;
        _otpController.clear();
        _errorText = null;
      });
      _startOtpTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo mode: enter OTP 1234'),
          ),
        );
      }

      setState(() {
        _isSendingOtp = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: _smsAutoRetrieveTimeoutSeconds),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (credential) async {
          final userCredential = await FirebaseAuth.instance
              .signInWithCredential(credential);
          await _onVerified(userCredential.user);
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _errorText = _friendlyAuthError(error);
          });
        },
        codeSent: (verificationId, forceResendingToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = forceResendingToken;
            _otpRequested = true;
            _otpController.clear();
            _errorText = null;
          });
          _startOtpTimer();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message ?? 'Unable to send OTP. Please try again.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = _friendlyAuthError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  Future<void> _submitOtp() async {
    if (_isSubmittingOtp || !_isOtpValid || (!_useMockOtp && _verificationId == null)) {
      return;
    }

    setState(() {
      _isSubmittingOtp = true;
      _errorText = null;
    });

    if (_useMockOtp) {
      if (_otpController.text.trim() != _mockOtp) {
        setState(() {
          _isSubmittingOtp = false;
          _errorText = 'Invalid OTP. Enter 1234 to continue.';
        });
        return;
      }

      try {
        await _completeMockSignIn();
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _errorText = 'Unable to continue in demo mode: $error';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSubmittingOtp = false;
          });
        }
      }
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      await _onVerified(userCredential.user);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = _friendlyAuthError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingOtp = false;
        });
      }
    }
  }

  Future<void> _completeMockSignIn() async {
    final phone = _phoneController.text.trim();
    final normalizedPhone = '+91$phone';
    final prefs = await SharedPreferences.getInstance();
    final registered = prefs.getStringList(_mockRegisteredMembersKey) ?? <String>[];
    final isFirstTime = !registered.contains(normalizedPhone);

    await prefs.setString(_mockActiveMemberPhoneKey, normalizedPhone);

    if (!mounted) return;

    if (isFirstTime) {
      await prefs.remove(_mockActiveMemberNameKey);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MemberFirstTimeDetailsScreen(
            userUid: 'mock:$normalizedPhone',
            phoneNumber: normalizedPhone,
          ),
        ),
      );
      return;
    }

    final profile = prefs.getStringList('mock_profile_$normalizedPhone') ?? const <String>[];
    final firstName = profile.isNotEmpty ? profile[0].trim() : '';
    final lastName = profile.length > 1 ? profile[1].trim() : '';
    final fullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();
    if (fullName.isNotEmpty) {
      await prefs.setString(_mockActiveMemberNameKey, fullName);
    }

    if (!mounted) return;

    await _maybeShowPostLoginPopups(context);
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainApp(isAdmin: false, rememberMe: false),
      ),
      (route) => false,
    );
  }

  Future<void> _onVerified(User? user) async {
    if (user == null || !mounted) {
      return;
    }

    final normalizedPhone = user.phoneNumber ?? '+91${_phoneController.text.trim()}';
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (!mounted) return;

    if (!snapshot.exists) {
      final legacyProfile = await _findLegacyProfileByPhone(normalizedPhone);
      if (!mounted) return;

      final legacyData = legacyProfile?.data();
      if (legacyData != null) {
        final existingData = <String, dynamic>{...legacyData};
        existingData['phoneNumber'] = normalizedPhone;
        existingData['updatedAt'] = FieldValue.serverTimestamp();
        existingData['lastLoginAt'] = FieldValue.serverTimestamp();
        await userRef.set(existingData, SetOptions(merge: true));
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MemberFirstTimeDetailsScreen(
              userUid: user.uid,
              phoneNumber: normalizedPhone,
            ),
          ),
        );
        return;
      }
    }

    await userRef.set({
      'lastLoginAt': FieldValue.serverTimestamp(),
      'phoneNumber': normalizedPhone,
    }, SetOptions(merge: true));

    if (!mounted) return;

    await _maybeShowPostLoginPopups(context);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainApp(isAdmin: false, rememberMe: false),
      ),
      (route) => false,
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findLegacyProfileByPhone(
    String phoneNumber,
  ) async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      if (result.docs.isEmpty) {
        return null;
      }
      final doc = result.docs.first;
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (doc.id == currentUid) {
        return null;
      }
      return doc;
    } catch (_) {
      return null;
    }
  }

  void _startOtpTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _otpTtlSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
        });
        return;
      }
      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'operation-not-allowed':
        return 'Phone sign-in is disabled for this Firebase project. Enable Phone in Firebase Console > Authentication > Sign-in method.';
      case 'invalid-verification-code':
      case 'session-expired':
        return 'Invalid OTP. Please resend OTP and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Use a valid 10-digit India number.';
      case 'quota-exceeded':
        return 'OTP quota exceeded. Please try later.';
      default:
        return error.message ?? error.code;
    }
  }

  String _clockText(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _maybeShowPostLoginPopups(BuildContext context) async {
    final configRef = FirebaseFirestore.instance.collection('app_popups');
    final keys = <String>['special_service', 'highlights'];

    for (final key in keys) {
      try {
        final doc = await configRef.doc(key).get();
        final data = doc.data();
        if (data == null || data['enabled'] != true) {
          continue;
        }

        final title = (data['title']?.toString().trim().isNotEmpty ?? false)
            ? data['title'].toString().trim()
            : (key == 'special_service' ? 'Special Service' : 'Highlights');
        final message = data['message']?.toString().trim() ?? '';

        if (!context.mounted || message.isEmpty) {
          continue;
        }

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (_) {
        // Ignore popup fetch failures and continue login.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sendEnabled =
        _isPhoneValid && !_isSendingOtp && (!_otpRequested || _secondsLeft == 0);
    final submitEnabled = _isOtpValid && !_isSubmittingOtp;
    final canResend = _otpRequested && _secondsLeft == 0 && !_isSendingOtp;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width > 820 ? 760.0 : width;
    final titleSize = width > 600 ? 54.0 : 42.0;
    final subtitleSize = width > 600 ? 40.0 : 15.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1022),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE1B640).withValues(alpha: .25),
                      blurRadius: 18,
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE1B640), width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/WhatsApp Image 2026-08-25 at 00.38.49.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Member Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fast & secure access via 10-digit Mobile OTP',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .7),
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: cardWidth,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF151E34),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF4B4A43)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mobile Number (India +91)',
                      style: TextStyle(
                        color: Color(0xFFF7DE71),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 94,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF222C43),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF59543A)),
                          ),
                          child: const Text(
                            '+91',
                            style: TextStyle(
                              color: Color(0xFFF0C93E),
                              fontWeight: FontWeight.w800,
                              fontSize: 38,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '10-digit number',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: .5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF222C43),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Color(0xFF59543A),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4C341),
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter a valid 10-digit mobile number. OTP expires in 3:00.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .62),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _goldButton(
                      label: _isSendingOtp
                          ? 'Sending OTP...'
                          : (_otpRequested ? 'Resend OTP' : 'Send OTP'),
                      icon: Icons.send_outlined,
                      onTap: sendEnabled
                          ? () => _sendOtp(resend: _otpRequested)
                          : null,
                    ),
                    if (_otpRequested) ...[
                      const SizedBox(height: 18),
                      _dashedDivider(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text(
                            'Enter 4-Digit OTP',
                            style: TextStyle(
                              color: Color(0xFFF7DE71),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _secondsLeft > 0 ? _clockText(_secondsLeft) : '00:00',
                            style: const TextStyle(
                              color: Color(0xFFE4C341),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_otpLength),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Colors.white,
                          letterSpacing: 14,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '....',
                          hintStyle: TextStyle(
                            letterSpacing: 14,
                            color: Colors.white.withValues(alpha: .35),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF222C43),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: _errorText == null
                                  ? const Color(0xFFE4C341)
                                  : Colors.redAccent,
                              width: 2.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: _errorText == null
                                  ? const Color(0xFFE4C341)
                                  : Colors.redAccent,
                              width: 2.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _goldButton(
                        label: _isSubmittingOtp ? 'Verifying...' : 'Submit OTP',
                        icon: Icons.check_circle_outline,
                        onTap: submitEnabled ? _submitOtp : null,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: canResend ? () => _sendOtp(resend: true) : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4A5064)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            canResend
                                ? 'Resend OTP'
                                : 'Resend OTP after ${_clockText(_secondsLeft)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminLoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A334A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Admin Portal Access',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 10).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(
              width: 5,
              height: 1.4,
              color: const Color(0xFF575B69),
            ),
          ),
        );
      },
    );
  }

  Widget _goldButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    if (onTap == null) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A334A),
            foregroundColor: Colors.white60,
            disabledBackgroundColor: const Color(0xFF2A334A),
            disabledForegroundColor: Colors.white60,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: Icon(icon, size: 22),
          label: Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFE4C341), Color(0xFFF6E381), Color(0xFFC46A1D)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE4C341).withValues(alpha: .18),
              blurRadius: 16,
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: const Color(0xFF3D445A),
            disabledForegroundColor: Colors.white60,
            foregroundColor: const Color(0xFF111D35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: Icon(icon, size: 22),
          label: Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
