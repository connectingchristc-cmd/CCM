import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/app_feature_store.dart';
import '../songs/lyric_view_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appFeatureStore,
      builder: (context, _) {
        final favorites = appFeatureStore.favoriteSongIds
            .map((id) => appFeatureStore.cachedSongs[id])
            .whereType<Map<String, dynamic>>()
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Favorites',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: ccmSandDark,
            foregroundColor: ccmInk,
          ),

          body: favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No favorite songs yet.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: favorites.length,

                  onReorder: (oldIndex, newIndex) async {
                    await appFeatureStore.reorderFavorites(oldIndex, newIndex);
                  },

                  itemBuilder: (context, index) {
                    final song = favorites[index];

                    final songId = song['id']?.toString() ?? '';

                    return Card(
                      key: ValueKey(songId),
                      margin: const EdgeInsets.only(bottom: 8),

                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: ccmRed,

                          child: Icon(Icons.music_note, color: ccmWhite),
                        ),

                        title: Text(
                          song['title_telugu'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        subtitle: Text(song['title_english'] ?? ''),

                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: ccmRed),

                          tooltip: 'Remove from favorites',

                          onPressed: () async {
                            await appFeatureStore.toggleFavorite(songId);
                          },
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LyricViewScreen(
                                songId: songId,
                                song: song,
                                playlist: favorites,
                                currentIndex: index,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
