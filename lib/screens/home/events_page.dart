import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_colors.dart';

class EventsPage extends StatelessWidget {
  final bool isAdmin;
  const EventsPage({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upcoming Events',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: (isAdmin
          ? FirebaseFirestore.instance.collection('homepage_events')
          : FirebaseFirestore.instance
              .collection('homepage_events')
              .where('enabled', isEqualTo: true))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load events: ${snapshot.error}'),
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
            return data['enabled'] != false && data['displayEvents'] != false;
          }).toList();

          if (visible.isEmpty) {
            return const Center(
              child: Text(
                'No Upcoming Events',
                style: TextStyle(color: ccmMutedInk, fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
            itemCount: visible.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = visible[index].data();
              final imageUrl = data['imageUrl']?.toString() ?? '';
              final title = data['title']?.toString() ?? 'Upcoming Event';
              final details = data['subtitle']?.toString() ?? data['details']?.toString() ?? '';
              final eventType = data['eventType']?.toString() ?? '';
              final eventDate = data['eventDate']?.toString() ?? '';
              final eventTime = data['eventTime']?.toString() ?? '';

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 1.73,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                                  color: Color(0xff2b2632),
                                  child: Center(
                                    child: Icon(Icons.broken_image_outlined, color: ccmWhite),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _ShareChip(
                                onTap: () => _shareEvent(title, details, imageUrl),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: ccmInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              details,
                              style: const TextStyle(color: ccmMutedInk, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              if (eventType.isNotEmpty)
                                _MetaPill(icon: Icons.category_outlined, text: eventType),
                              if (eventDate.isNotEmpty)
                                _MetaPill(icon: Icons.calendar_today_outlined, text: eventDate),
                              if (eventTime.isNotEmpty)
                                _MetaPill(icon: Icons.schedule_outlined, text: eventTime),
                            ],
                          ),
                        ],
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

  Future<void> _shareEvent(String title, String details, String imageUrl) async {
    final text = [title, if (details.isNotEmpty) details, if (imageUrl.isNotEmpty) imageUrl].join('\n');
    await Share.share(text, subject: 'CCM Upcoming Event');
  }
}

class _ShareChip extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(Icons.share_outlined, color: ccmWhite, size: 18),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ccmSandDark.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ccmInk),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(color: ccmInk, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
