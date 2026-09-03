import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_colors.dart';

class DailyDevotionPage extends StatelessWidget {
  final bool isAdmin;
  const DailyDevotionPage({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Devotion', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: (isAdmin
          ? FirebaseFirestore.instance.collection('daily_devotions')
          : FirebaseFirestore.instance
              .collection('daily_devotions')
              .where('enabled', isEqualTo: true))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load daily devotion: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: ccmRed));
          }

          final docs = [...?snapshot.data?.docs]
            ..sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              final aOrder = (aData['sortOrder'] ?? 9999) as num;
              final bOrder = (bData['sortOrder'] ?? 9999) as num;
              if (aOrder != bOrder) return aOrder.compareTo(bOrder);
              final aCreated = aData['created_at'];
              final bCreated = bData['created_at'];
              if (aCreated is Timestamp && bCreated is Timestamp) {
                return bCreated.compareTo(aCreated);
              }
              return 0;
            });

          final visible = docs.where((doc) {
            final data = doc.data();
            if (isAdmin) return true;
            return data['enabled'] != false;
          }).take(5).toList();

          if (visible.isEmpty) {
            return const Center(
              child: Text('Coming Soon', style: TextStyle(color: ccmMutedInk, fontWeight: FontWeight.w600)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
            itemCount: visible.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = visible[index].data();
              final imageUrl = data['imageUrl']?.toString() ?? '';
              final devotionDate = data['devotionDate']?.toString() ?? '';

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.73,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const ColoredBox(
                                      color: Color(0xff2b2632),
                                      child: Center(
                                        child: Icon(Icons.broken_image_outlined, color: ccmWhite),
                                      ),
                                    ),
                                  )
                                : const ColoredBox(
                                    color: Color(0xff2b2632),
                                    child: Center(
                                      child: Icon(Icons.auto_stories_outlined, color: ccmWhite, size: 46),
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black.withValues(alpha: .30),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _share(imageUrl, devotionDate),
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.share_outlined, color: ccmWhite, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (devotionDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        child: Text(
                          devotionDate,
                          style: const TextStyle(
                            color: ccmInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _share(String imageUrl, String devotionDate) async {
    final text = [
      'Daily Devotion',
      if (devotionDate.isNotEmpty) devotionDate,
      if (imageUrl.isNotEmpty) imageUrl,
    ].join('\n');
    await Share.share(text, subject: 'CCM Daily Devotion');
  }
}
