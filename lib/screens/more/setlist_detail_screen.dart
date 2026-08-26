import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/app_feature_store.dart';
import '../songs/lyric_view_screen.dart';

class SetlistDetailScreen extends StatefulWidget {
  final int setlistIndex;

  const SetlistDetailScreen({
    super.key,
    required this.setlistIndex,
  });

  @override
  State<SetlistDetailScreen> createState() =>
      _SetlistDetailScreenState();
}

class _SetlistDetailScreenState
    extends State<SetlistDetailScreen> {
  Map<String, dynamic> get _setlist =>
      appFeatureStore.setlists[widget.setlistIndex];

  Future<void> _addSong() async {
    final songs =
        appFeatureStore.cachedSongs.values.toList();

    if (songs.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open the Songs tab once to cache songs for offline setlists.',
          ),
        ),
      );

      return;
    }

    final selectedSongId =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Song'),

          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];

                final id =
                    song['id']?.toString() ?? '';

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: ccmRed,
                    child: Icon(
                      Icons.music_note,
                      color: ccmWhite,
                    ),
                  ),

                  title: Text(
                    song['title_english'] ??
                        'Song',
                  ),

                  subtitle: Text(
                    song['title_telugu'] ?? '',
                  ),

                  onTap: () {
                    Navigator.pop(
                      context,
                      id,
                    );
                  },
                );
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedSongId == null) {
      return;
    }

    final songIds =
        (_setlist['songIds']
                as List<dynamic>?)
            ?.cast<String>() ??
        <String>[];

    if (!songIds.contains(selectedSongId)) {
      songIds.add(selectedSongId);

      _setlist['songIds'] = songIds;

      await appFeatureStore.saveSetlists();

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _removeSong(
    String songId,
  ) async {
    final songIds =
        (_setlist['songIds']
                as List<dynamic>?)
            ?.cast<String>() ??
        <String>[];

    songIds.remove(songId);

    _setlist['songIds'] = songIds;

    await appFeatureStore.saveSetlists();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _publishSetlist() async {
    _setlist['published'] = true;

    await appFeatureStore.saveSetlists();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Setlist published successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {});
  }

  Future<void> _unpublishSetlist() async {
    _setlist['published'] = false;

    await appFeatureStore.saveSetlists();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Setlist unpublished.',
        ),
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final songIds =
        (_setlist['songIds']
                as List<dynamic>?)
            ?.cast<String>() ??
        <String>[];

    final songs = songIds
        .map(
          (id) =>
              appFeatureStore.cachedSongs[id],
        )
        .whereType<Map<String, dynamic>>()
        .toList();

    final isPublished =
        _setlist['published'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _setlist['name'] ??
              'Setlist',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: ccmRed,

        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'publish') {
                _publishSetlist();
              }

              if (value == 'unpublish') {
                _unpublishSetlist();
              }
            },

            itemBuilder: (context) {
              return [
                if (!isPublished)
                  const PopupMenuItem(
                    value: 'publish',
                    child: Row(
                      children: [
                        Icon(
                          Icons.public,
                          color: ccmBlue,
                        ),
                        SizedBox(width: 8),
                        Text('Publish'),
                      ],
                    ),
                  ),

                if (isPublished)
                  const PopupMenuItem(
                    value: 'unpublish',
                    child: Row(
                      children: [
                        Icon(
                          Icons.public_off,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text('Unpublish'),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),

      body: Column(
        children: [
          if (isPublished)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color:
                  ccmBlue.withValues(
                alpha: 0.1,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.public,
                    color: ccmBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'This setlist is published',
                    style: TextStyle(
                      color: ccmBlue,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text(
                      'No songs in this setlist yet.\nTap "Add Song" to begin.',
                      textAlign:
                          TextAlign.center,
                    ),
                  )
                : ReorderableListView.builder(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 8,
                    ),

                    itemCount: songs.length,

                    onReorder:
                        (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }

                      final movedId =
                          songIds.removeAt(
                        oldIndex,
                      );

                      songIds.insert(
                        newIndex,
                        movedId,
                      );

                      _setlist['songIds'] =
                          songIds;

                      await appFeatureStore
                          .saveSetlists();

                      if (mounted) {
                        setState(() {});
                      }
                    },

                    itemBuilder:
                        (context, index) {
                      final song =
                          songs[index];

                      final id =
                          song['id']
                                  ?.toString() ??
                              '';

                      return ListTile(
                        key: ValueKey(id),

                        leading:
                            Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons
                                  .drag_handle,
                              color:
                                  Colors.grey,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            CircleAvatar(
                              backgroundColor:
                                  ccmRed,
                              child: Text(
                                '${index + 1}',
                                style:
                                    const TextStyle(
                                  color:
                                      ccmWhite,
                                ),
                              ),
                            ),
                          ],
                        ),

                        title: Text(
                          song[
                                  'title_english'] ??
                              'Song',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        subtitle: Text(
                          song[
                                  'title_telugu'] ??
                              '',
                        ),

                        trailing:
                            IconButton(
                          icon:
                              const Icon(
                            Icons
                                .remove_circle_outline,
                            color:
                                Colors.red,
                          ),
                          tooltip:
                              'Remove song',
                          onPressed: () =>
                              _removeSong(
                            id,
                          ),
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      LyricViewScreen(
                                songId: id,
                                song: song,
                                playlist:
                                    songs,
                                currentIndex:
                                    index,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: ccmRed,

        onPressed: _addSong,

        icon: const Icon(
          Icons.add,
          color: ccmWhite,
        ),

        label: const Text(
          'Add Song',
          style: TextStyle(
            color: ccmWhite,
          ),
        ),
      ),
    );
  }
}