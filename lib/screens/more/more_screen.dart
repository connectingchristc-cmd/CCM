import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../common/coming_soon_screen.dart';
import 'favorites_screen.dart';
import 'my_prayer_requests_screen.dart';
import 'setlists_screen.dart';
import 'updates_screen.dart';

class MoreScreen extends StatefulWidget {
  final bool isAdmin;

  const MoreScreen({super.key, required this.isAdmin});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'More',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: ccmSandDark,
        foregroundColor: ccmInk,
        elevation: 0,
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ccmSandDark.withValues(alpha: 0.35), ccmSand],
          ),
        ),

        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ================= FAVORITES =================

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ccmRed,
                  child: Icon(Icons.favorite, color: ccmWhite),
                ),

                title: const Text(
                  'Favorites',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: const Text('View your favorite songs'),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ================= SETLISTS =================
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ccmBlue,
                  child: Icon(Icons.playlist_play, color: ccmWhite),
                ),

                title: const Text(
                  'Worship Setlists',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: const Text('Create and manage worship setlists'),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetlistsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ccmRed,
                  child: Icon(Icons.notifications_outlined, color: ccmWhite),
                ),
                title: const Text(
                  'Updates',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Latest announcements and notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpdatesScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ================= ABOUT US =================
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ccmRed,
                  child: Icon(Icons.info_outline, color: ccmWhite),
                ),

                title: const Text(
                  'About Us',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: const Text('About Connecting Christ Ministries'),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ComingSoonScreen(title: 'About Us'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ================= PASTORAL TEAM =================
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ccmBlue,
                  child: Icon(Icons.people_outline, color: ccmWhite),
                ),

                title: const Text(
                  'Pastoral Team',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: const Text('Meet our pastoral team'),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ComingSoonScreen(title: 'Pastoral Team'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ================= CONTACT US =================
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ccmRed,
                  child: Icon(Icons.contact_phone_outlined, color: ccmWhite),
                ),

                title: const Text(
                  'Contact Us',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: const Text('Get in touch with CCM'),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ComingSoonScreen(title: 'Contact Us'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ================= PRAYER REQUEST =================
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ccmBlue,
                  child: Icon(Icons.volunteer_activism, color: ccmWhite),
                ),

                title: const Text(
                  'Prayer Request',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: const Text('Submit your prayer request'),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ComingSoonScreen(title: 'Prayer Request'),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ccmRed,
                  child: Icon(Icons.person_outline, color: ccmWhite),
                ),
                title: const Text(
                  'My Prayer Requests',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Track your submitted prayer requests'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyPrayerRequestsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
