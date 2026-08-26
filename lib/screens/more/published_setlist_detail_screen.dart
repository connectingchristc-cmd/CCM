import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/app_feature_store.dart';
import '../songs/lyric_view_screen.dart';

class PublishedSetlistDetailScreen extends StatelessWidget {
  final int setlistIndex;

  const PublishedSetlistDetailScreen({
    super.key,
    required this.setlistIndex,
  });

  @override
  Widget build(BuildContext context) {
    final setlist =
        appFeatureStore.setlists[setlistIndex];

    final songIds =
        (setlist['songIds'] as List<dynamic>?)
                ?.cast<String>() ??
            <String>[];

    final songs = songIds
        .map(
          (id) => appFeatureStore.cachedSongs[id],
        )
        .whereType<Map<String, dynamic>>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          setlist['name'] ?? 'Published Setlist',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ccmRed,
      ),

      body: songs.isEmpty
          ? const Center(
              child: Text(
                'No songs available in this setlist.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: songs.length,

              separatorBuilder:
                  (context, index) =>
                      const Divider(),

              itemBuilder: (context, index) {
                final song = songs[index];

                final songId =
                    song['id']?.toString() ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ccmRed,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: ccmWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  title: Text(
                    song['title_english'] ??
                        'Song',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: Text(
                    song['title_telugu'] ?? '',
                  ),

                  trailing: const Icon(
                    Icons.chevron_right,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LyricViewScreen(
                          songId: songId,
                          song: song,
                          playlist: songs,
                          currentIndex: index,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}