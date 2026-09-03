import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class MyPrayerRequestsScreen extends StatefulWidget {
  const MyPrayerRequestsScreen({super.key});

  @override
  State<MyPrayerRequestsScreen> createState() => _MyPrayerRequestsScreenState();
}

class _MyPrayerRequestsScreenState extends State<MyPrayerRequestsScreen> {
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? <String, dynamic>{};
      final phone = (data['phoneNumber'] ?? user.phoneNumber ?? '').toString().trim();
      if (!mounted) {
        return;
      }
      setState(() => _phone = phone);
    } catch (_) {
      _phone = user.phoneNumber ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prayer Requests'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Submitted Prayer Requests', 'prayer_requests', uid),
          const SizedBox(height: 12),
          _section('Requested Callbacks', 'prayer_callbacks', uid),
          const SizedBox(height: 12),
          _section('Prayer Cell Requests', 'prayer_cell', uid),
        ],
      ),
    );
  }

  Widget _section(String title, String collection, String uid) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ccmInk,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(collection)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }

                final docs = [...?snapshot.data?.docs].where((doc) {
                  final data = doc.data();
                  final ownerUid = (data['memberUid'] ?? '').toString();
                  final ownerPhone = (data['memberPhone'] ?? data['phone'] ?? '').toString();
                  if (ownerUid.isNotEmpty && ownerUid == uid) {
                    return true;
                  }
                  if (_phone.isNotEmpty && ownerPhone == _phone) {
                    return true;
                  }
                  return false;
                }).toList();

                if (docs.isEmpty) {
                  return const Text(
                    'No requests yet.',
                    style: TextStyle(color: ccmMutedInk),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final details = data['prayerRequest']?.toString().trim().isNotEmpty == true
                        ? data['prayerRequest'].toString()
                        : (data['callbackDetails']?.toString().trim().isNotEmpty == true
                            ? data['callbackDetails'].toString()
                            : (data['place']?.toString() ?? data['details']?.toString() ?? ''));
                    final readState = data['isRead'] == true ? 'Read' : 'Pending';

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        data['isRead'] == true ? Icons.mark_email_read_outlined : Icons.schedule,
                        color: data['isRead'] == true ? ccmBlue : ccmRed,
                      ),
                      title: Text(
                        details.isEmpty ? 'Request submitted' : details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(readState),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
