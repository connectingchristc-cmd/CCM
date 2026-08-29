import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class TestimonialsScreen extends StatelessWidget {
  const TestimonialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Testimonials')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('testimonials')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load testimonials: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ccmRed),
            );
          }
          final docs =
              [...?snapshot.data?.docs]
                  .where((doc) => doc.data()['enabled'] != false)
                  .toList()
                ..sort(
                  (a, b) => ((a.data()['sortOrder'] ?? 0) as num).compareTo(
                    (b.data()['sortOrder'] ?? 0) as num,
                  ),
                );
          if (docs.isEmpty) {
            return const Center(child: Text('No testimonials available yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _TestimonialCard(data: docs[index].data()),
          );
        },
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TestimonialCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final photo =
        data['photoUrl']?.toString() ?? data['imageUrl']?.toString() ?? '';
    final testimony =
        data['testimony']?.toString() ??
        data['details']?.toString() ??
        data['subtitle']?.toString() ??
        '';
    return Card(
      elevation: 5,
      shadowColor: const Color(0x55493828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.white.withValues(alpha: .75)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: ccmRed.withValues(alpha: .12),
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? const Icon(Icons.person_outline, color: ccmRed)
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title']?.toString() ?? 'Testimony',
                    style: const TextStyle(
                      color: ccmInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data['name'] ?? ''}${data['category'] == null || data['category'].toString().isEmpty ? '' : ' • ${data['category']}'}',
                    style: const TextStyle(color: ccmMutedInk, fontSize: 12),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    testimony.isEmpty ? 'No testimony provided.' : testimony,
                    style: const TextStyle(
                      color: ccmMutedInk,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if ((data['videoUrl']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: ccmRed,
                          size: 19,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Video testimony available',
                          style: TextStyle(
                            color: ccmRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
