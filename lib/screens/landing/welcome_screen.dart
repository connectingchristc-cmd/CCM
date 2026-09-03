import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../auth/admin_login_screen.dart';
import '../auth/member_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _openMember(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MemberLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccmSand,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -95,
              right: -70,
              child: _softOrb(const Color(0xffffdca8), 230),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _softOrb(const Color(0xffd9c1dc), 250),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                      decoration: BoxDecoration(
                        color: ccmWhite.withValues(alpha: .62),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: ccmWhite.withValues(alpha: .8),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1f412817),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 138,
                            height: 138,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ccmWhite,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3f412817),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xffd2a04d),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/WhatsApp Image 2026-08-25 at 00.38.49.jpeg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'CONNECTING CHRIST\nMINISTRIES',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ccmInk,
                              fontSize: 27,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .5,
                            ),
                          ),
                          const SizedBox(height: 13),
                          const Text(
                            'A place for worship, prayer,\nand fellowship.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ccmMutedInk,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildButton(
                            context,
                            label: 'CCM Member',
                            icon: Icons.person_outline_rounded,
                            filled: true,
                            onPressed: () => _openMember(context),
                          ),
                          const SizedBox(height: 12),
                          _buildButton(
                            context,
                            label: 'CCM Admin',
                            icon: Icons.admin_panel_settings_outlined,
                            filled: false,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminLoginScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 15,
                          color: ccmRed.withValues(alpha: .7),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Worship • Prayer • Fellowship',
                          style: TextStyle(
                            color: ccmMutedInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.auto_awesome,
                          size: 15,
                          color: ccmRed.withValues(alpha: .7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '© 2026 Connecting Christ Ministries',
                      style: TextStyle(color: ccmMutedInk, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onPressed,
  }) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: ccmRed,
            foregroundColor: ccmWhite,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: ccmRed,
            side: const BorderSide(color: ccmRed, width: 1.5),
          );
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: filled
          ? ElevatedButton.icon(
              style: style,
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : OutlinedButton.icon(
              style: style,
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  Widget _softOrb(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .32),
    ),
  );
}
