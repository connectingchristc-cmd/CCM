import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/app_feature_store.dart';
import 'add_song_screen.dart';
import 'edit_song_screen.dart';
import 'lyric_view_screen.dart';

class SongsScreen extends StatefulWidget {
  final bool isAdmin;

  const SongsScreen({
    super.key,
    required this.isAdmin,
  });

  @override
  State<SongsScreen> createState() =>
      _SongsScreenState();
}

class _SongsScreenState
    extends State<SongsScreen> {
  String _searchQuery = '';
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Songs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: ccmRed,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Show favorites',
            icon: Icon(
              _favoritesOnly
                  ? Icons.favorite
                  : Icons.favorite_outline,
            ),
            onPressed: () {
              setState(() {
                _favoritesOnly =
                    !_favoritesOnly;
              });
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appFeatureStore,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search songs (Telugu or English)...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: ccmRed,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(
                        color: ccmRed,
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(
                        color: ccmRed,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: ccmLightGray,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery =
                          value.trim().toLowerCase();
                    });
                  },
                ),
              ),

              Expanded(
                child: Firebase.apps.isEmpty
                    ? _buildCachedSongs()
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore
                            .instance
                            .collection('songs')
                            .orderBy(
                              'title_english',
                            )
                            .snapshots(),
                        builder: (
                          context,
                          snapshot,
                        ) {
                          if (snapshot.hasError) {
                            return _buildCachedSongs();
                          }

                          if (snapshot
                                  .connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          final docs =
                              snapshot.data?.docs ?? [];

                          if (docs.isNotEmpty) {
                            appFeatureStore
                                .cacheSongs(docs);
                          }

                          final filtered =
                              docs.where((doc) {
                            final data =
                                doc.data()
                                    as Map<String, dynamic>;

                            final eng =
                                (data[
                                            'title_english'] ??
                                        '')
                                    .toString()
                                    .toLowerCase();

                            final tel =
                                (data[
                                            'title_telugu'] ??
                                        '')
                                    .toString()
                                    .toLowerCase();

                            final lyrics =
                                (data['lyrics'] ??
                                        '')
                                    .toString()
                                    .toLowerCase();

                            return (
                                  eng.contains(
                                    _searchQuery,
                                  ) ||
                                  tel.contains(
                                    _searchQuery,
                                  ) ||
                                  lyrics.contains(
                                    _searchQuery,
                                  )
                                ) &&
                                (
                                  !_favoritesOnly ||
                                  appFeatureStore
                                      .isFavorite(
                                    doc.id,
                                  )
                                );
                          }).toList();

                          final songList =
                              filtered.map((doc) {
                            return <String, dynamic>{
                              'id': doc.id,
                              ...(doc.data()
                                  as Map<String, dynamic>),
                            };
                          }).toList();

                          return Column(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                color:
                                    ccmRed.withValues(
                                  alpha: 0.1,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Text(
                                      'Total Songs: ${filtered.length}',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        color: ccmRed,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (_favoritesOnly)
                                      const Text(
                                        '(Filtered Favorites)',
                                        style:
                                            TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: filtered.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No songs found',
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount:
                                            filtered.length,
                                        separatorBuilder:
                                            (
                                          context,
                                          index,
                                        ) =>
                                            const Divider(
                                          height: 1,
                                        ),
                                        itemBuilder:
                                            (
                                          context,
                                          index,
                                        ) {
                                          final songDoc =
                                              filtered[index];

                                          final song =
                                              songDoc.data()
                                                  as Map<
                                                      String,
                                                      dynamic>;

                                          final isFav =
                                              appFeatureStore
                                                  .isFavorite(
                                            songDoc.id,
                                          );

                                          return ListTile(
                                            leading:
                                                CircleAvatar(
                                              backgroundColor:
                                                  ccmRed,
                                              child:
                                                  Text(
                                                (song[
                                                            'title_english'] ??
                                                        'A')
                                                    .toString()
                                                    .isNotEmpty
                                                    ? (song[
                                                                'title_english'] ??
                                                            'A')
                                                        .toString()[0]
                                                        .toUpperCase()
                                                    : 'A',
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color:
                                                      ccmWhite,
                                                ),
                                              ),
                                            ),

                                            title: Text(
                                              song[
                                                      'title_telugu'] ??
                                                  '',
                                              style:
                                                  const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),

                                            subtitle: Text(
                                              song[
                                                      'title_english'] ??
                                                  '',
                                            ),

                                            trailing:
                                                IconButton(
                                              icon: Icon(
                                                isFav
                                                    ? Icons
                                                        .favorite
                                                    : Icons
                                                        .favorite_outline,
                                                color: isFav
                                                    ? ccmRed
                                                    : Colors.grey,
                                              ),
                                              onPressed:
                                                  () {
                                                appFeatureStore
                                                    .toggleFavorite(
                                                  songDoc.id,
                                                );
                                              },
                                            ),

                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                    context,
                                                  ) =>
                                                      LyricViewScreen(
                                                    songId:
                                                        songDoc.id,
                                                    song:
                                                        song,
                                                    playlist:
                                                        songList,
                                                    currentIndex:
                                                        index,
                                                  ),
                                                ),
                                              );
                                            },

                                            onLongPress:
                                                widget.isAdmin
                                                    ? () =>
                                                        _showSongOptions(
                                                          context,
                                                          songDoc.id,
                                                          song,
                                                        )
                                                    : null,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: ccmRed,
              icon: const Icon(Icons.add),
              label: const Text('Add Song'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AddSongScreen(),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildCachedSongs() {
    final cached =
        appFeatureStore.cachedSongs.values
            .where((song) {
      final query = _searchQuery;

      final eng =
          (song['title_english'] ?? '')
              .toString()
              .toLowerCase();

      final tel =
          (song['title_telugu'] ?? '')
              .toString()
              .toLowerCase();

      final lyrics =
          (song['lyrics'] ?? '')
              .toString()
              .toLowerCase();

      return (
            eng.contains(query) ||
            tel.contains(query) ||
            lyrics.contains(query)
          ) &&
          (
            !_favoritesOnly ||
            appFeatureStore.isFavorite(
              song['id'].toString(),
            )
          );
    }).toList();

    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
          color:
              ccmRed.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Songs: ${cached.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ccmRed,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: cached.isEmpty
              ? const Center(
                  child: Text(
                    'No cached songs available.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: cached.length,

                  separatorBuilder:
                      (
                    context,
                    index,
                  ) =>
                          const Divider(
                    height: 1,
                  ),

                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final song =
                        cached[index];

                    final id =
                        song['id'].toString();

                    final isFav =
                        appFeatureStore
                            .isFavorite(id);

                    return ListTile(
                      leading:
                          const CircleAvatar(
                        backgroundColor:
                            ccmRed,
                        child: Icon(
                          Icons.music_note,
                          color: ccmWhite,
                        ),
                      ),

                      title: Text(
                        song[
                                'title_telugu'] ??
                            '',
                      ),

                      subtitle: Text(
                        song[
                                'title_english'] ??
                            '',
                      ),

                      trailing:
                          IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite
                              : Icons
                                  .favorite_outline,
                          color: isFav
                              ? ccmRed
                              : Colors.grey,
                        ),
                        onPressed: () {
                          appFeatureStore
                              .toggleFavorite(id);
                        },
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (
                              context,
                            ) =>
                                LyricViewScreen(
                              songId: id,
                              song: song,
                              playlist: cached,
                              currentIndex: index,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showSongOptions(
    BuildContext context,
    String songId,
    Map<String, dynamic> song,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              song['title_english'] ??
                  'Song',
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(
                Icons.edit,
                color: ccmBlue,
              ),
              title:
                  const Text('Edit Song'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditSongScreen(
                      songId: songId,
                      song: song,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title:
                  const Text('Delete Song'),
              onTap: () {
                Navigator.pop(context);

                _deleteSong(
                  context,
                  songId,
                  song['title_english'] ??
                      'Song',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSong(
    BuildContext context,
    String songId,
    String songTitle,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
        title:
            const Text('Delete Song'),

        content: Text(
          'Are you sure you want to delete "$songTitle"?',
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
                const Text('Cancel'),
          ),

          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore
                    .instance
                    .collection('songs')
                    .doc(songId)
                    .delete();

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Song deleted successfully!',
                    ),
                    backgroundColor:
                        Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting song: $e',
                    ),
                    backgroundColor:
                        Colors.red,
                  ),
                );
              }
            },

            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}