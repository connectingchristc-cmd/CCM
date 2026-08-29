import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import 'add_daily_bread_screen.dart';

class DailyBreadScreen extends StatelessWidget {
  final bool isAdmin;
  const DailyBreadScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Bread',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Add Daily Bread',
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDailyBreadScreen()),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('daily_bread')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load Daily Bread: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ccmRed),
            );
          }
          final docs = [...?snapshot.data?.docs]
            ..sort((a, b) {
              final aDate = a.data()['created_at'];
              final bDate = b.data()['created_at'];
              if (aDate is Timestamp && bDate is Timestamp)
                return bDate.compareTo(aDate);
              return 0;
            });
          if (docs.isEmpty)
            return const Center(child: Text('No Daily Bread available yet.'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) =>
                _BreadCard(data: docs[index].data()),
          );
        },
      ),
    );
  }
}

class _BreadCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BreadCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl']?.toString() ?? '';
    return Card(
      elevation: 5,
      shadowColor: const Color(0x55493828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.white.withValues(alpha: .75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bible Verse',
                  style: TextStyle(
                    color: ccmRed,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '“${data['verse']?.toString() ?? 'No verse text'}”',
                  style: const TextStyle(
                    color: ccmInk,
                    fontSize: 17,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data['reference']?.toString() ?? '',
                  style: const TextStyle(
                    color: ccmMutedInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
