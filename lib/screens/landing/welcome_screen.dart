import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../auth/admin_login_screen.dart';
import '../main_app.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _openMember(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInAnonymously();

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainApp(
            isAdmin: false,
            rememberMe: false,
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Member sign-in failed: '
            '${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ccmRed.withValues(alpha: 0.9),
              ccmBlue.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 28),

                        Text(
                          'CONNECTING CHRIST\nMINISTRIES',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ccmWhite,
                                fontSize: 30,
                              ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'A place for worship, prayer, and fellowship.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color:
                                    ccmWhite.withValues(alpha: 0.9),
                              ),
                        ),

                        const SizedBox(height: 48),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ccmWhite,
                              foregroundColor: ccmRed,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminLoginScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: const Text(
                              'CCM Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ccmWhite,
                              side: const BorderSide(
                                color: ccmWhite,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _openMember(context),
                            icon: const Icon(
                              Icons.person_outline,
                            ),
                            label: const Text(
                              'CCM Member',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  bottom: 16.0,
                ),
                child: Column(
                  children: [
                    Text(
                      'All rights reserved to CCM',
                      style: TextStyle(
                        color:
                            ccmWhite.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Copyrights @2026',
                      style: TextStyle(
                        color:
                            ccmWhite.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
}