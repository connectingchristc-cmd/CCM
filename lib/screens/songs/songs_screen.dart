import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_colors.dart';
import '../../core/app_feature_store.dart';
import 'add_song_screen.dart';
import 'edit_song_screen.dart';
import 'lyric_view_screen.dart';

class SongsScreen extends StatefulWidget {
  final bool isAdmin;

  const SongsScreen({super.key, required this.isAdmin});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  String _searchQuery = '';
  bool _favoritesOnly = false;

  static const List<_GlowPalette> _songCardPalette = [
    _GlowPalette(
      border: Color(0xFFF2A8B9),
      glow: Color(0x66F2A8B9),
      noteTint: Color(0x665D2C37),
      bgTop: Color(0xFFFFDCE4),
      bgBottom: Color(0xFFF9C7D3),
    ),
    _GlowPalette(
      border: Color(0xFFF2C67D),
      glow: Color(0x66F2C67D),
      noteTint: Color(0x6660461D),
      bgTop: Color(0xFFFFE8C3),
      bgBottom: Color(0xFFF8D79A),
    ),
    _GlowPalette(
      border: Color(0xFFEDAE8A),
      glow: Color(0x66EDAE8A),
      noteTint: Color(0x66553728),
      bgTop: Color(0xFFFFE0CF),
      bgBottom: Color(0xFFF8C9AA),
    ),
    _GlowPalette(
      border: Color(0xFFC9D978),
      glow: Color(0x66C9D978),
      noteTint: Color(0x66515A24),
      bgTop: Color(0xFFEDF6CB),
      bgBottom: Color(0xFFDCEAA2),
    ),
    _GlowPalette(
      border: Color(0xFFE1A9C2),
      glow: Color(0x66E1A9C2),
      noteTint: Color(0x66553646),
      bgTop: Color(0xFFFEE0EE),
      bgBottom: Color(0xFFF6C9DD),
    ),
    _GlowPalette(
      border: Color(0xFF94BFF0),
      glow: Color(0x6694BFF0),
      noteTint: Color(0x66304761),
      bgTop: Color(0xFFDDEEFF),
      bgBottom: Color(0xFFC6DFF9),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B1D),
      body: AnimatedBuilder(
        animation: appFeatureStore,
        builder: (context, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D1633), Color(0xFF070C20)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeroHeader(),
                  Expanded(
                    child: Firebase.apps.isEmpty
                        ? _buildCachedSongs()
                        : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('songs')
                                .orderBy('title_english')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return _buildCachedSongs();
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final docs = snapshot.data?.docs ?? const [];
                              if (docs.isNotEmpty) {
                                appFeatureStore.cacheSongs(docs);
                              }

                              final filtered = docs.where((doc) {
                                final data = doc.data();
                                final eng =
                                    (data['title_english'] ?? '').toString().toLowerCase();
                                final tel =
                                    (data['title_telugu'] ?? '').toString().toLowerCase();
                                final lyrics =
                                    (data['lyrics'] ?? '').toString().toLowerCase();

                                return (eng.contains(_searchQuery) ||
                                        tel.contains(_searchQuery) ||
                                        lyrics.contains(_searchQuery)) &&
                                    (!_favoritesOnly ||
                                        appFeatureStore.isFavorite(doc.id));
                              }).toList();

                              final songList = filtered
                                  .map(
                                    (doc) => <String, dynamic>{
                                      'id': doc.id,
                                      ...doc.data(),
                                    },
                                  )
                                  .toList();

                              return _buildSongList(
                                count: filtered.length,
                                emptyText: 'No songs found',
                                itemCount: filtered.length,
                                favoritesFiltered: _favoritesOnly,
                                itemBuilder: (context, index) {
                                  final songDoc = filtered[index];
                                  return _buildSongCard(
                                    index: index,
                                    songId: songDoc.id,
                                    song: songDoc.data(),
                                    playlist: songList,
                                    currentIndex: index,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: ccmRed,
              foregroundColor: ccmWhite,
              elevation: 10,
              icon: const Icon(Icons.add, color: ccmWhite),
              label: const Text(
                'Add Song',
                style: TextStyle(
                  color: ccmWhite,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: ccmWhite.withValues(alpha: 0.55),
                  width: 1.2,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSongScreen(),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildHeroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Column(
        children: [
          Container(
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2B1D50), Color(0xFF0F2F61), Color(0xFF1A0E2F)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF90C8FF).withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -20,
                  top: -24,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 58,
                    color: const Color(0xFFFFD67A).withValues(alpha: 0.34),
                  ),
                ),
                Positioned(
                  right: -18,
                  bottom: -12,
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 70,
                    color: const Color(0xFFFFD67A).withValues(alpha: 0.18),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      'Songs',
                      style: GoogleFonts.cinzelDecorative(
                        color: const Color(0xFFFFC85A),
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(
                            color: Color(0xFF3A2500),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                          Shadow(color: Color(0xAAFFE09A), blurRadius: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _favoritesOnly = !_favoritesOnly;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                        padding: const EdgeInsets.all(4),
                      child: Icon(
                        _favoritesOnly ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFEED89B),
                          size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.42),
          width: 1.1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF121D3F), Color(0xFF0A1129)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD67A).withValues(alpha: 0.30),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFF8D36B), Color(0xFF4A3516)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD67A).withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.search, color: Color(0xFF2C1C06)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search songs (Telugu or English)...',
                hintStyle: TextStyle(color: Color(0xFFB7BDD4), fontSize: 17),
                border: InputBorder.none,
                filled: false,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildSongList({
    required int count,
    required String emptyText,
    required int itemCount,
    required bool favoritesFiltered,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _buildCountChip(count, favoritesFiltered),
        ),
        Expanded(
          child: itemCount == 0
              ? Center(
                  child: Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                  itemCount: itemCount,
                  separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                  itemBuilder: itemBuilder,
                ),
        ),
      ],
    );
  }

  Widget _buildCountChip(int count, bool favoritesFiltered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3D27A).withValues(alpha: 0.72)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2A36), Color(0xFF101523)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD67A).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  RadialGradient(colors: [Color(0xFFF9DA84), Color(0xFF684B16)]),
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'Total Songs: $count',
            style: const TextStyle(
              color: Color(0xFFF4E1B0),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          if (favoritesFiltered)
            const Text(
              'Favorites',
              style: TextStyle(color: Color(0xFFD8BCD0), fontSize: 12),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.equalizer_rounded,
            color: const Color(0xFFECC764).withValues(alpha: 0.95),
            size: 29,
          ),
        ],
      ),
    );
  }

  Widget _buildCachedSongs() {
    final cached = appFeatureStore.cachedSongs.values.where((song) {
      final query = _searchQuery;
      final eng = (song['title_english'] ?? '').toString().toLowerCase();
      final tel = (song['title_telugu'] ?? '').toString().toLowerCase();
      final lyrics = (song['lyrics'] ?? '').toString().toLowerCase();

      return (eng.contains(query) || tel.contains(query) || lyrics.contains(query)) &&
          (!_favoritesOnly || appFeatureStore.isFavorite(song['id'].toString()));
    }).toList();

    return _buildSongList(
      count: cached.length,
      emptyText: 'No cached songs available.',
      itemCount: cached.length,
      favoritesFiltered: _favoritesOnly,
      itemBuilder: (context, index) {
        final song = cached[index];
        final id = song['id'].toString();
        return _buildSongCard(
          index: index,
          songId: id,
          song: song,
          playlist: cached,
          currentIndex: index,
        );
      },
    );
  }

  Widget _buildSongCard({
    required int index,
    required String songId,
    required Map<String, dynamic> song,
    required List<Map<String, dynamic>> playlist,
    required int currentIndex,
  }) {
    final palette = _songCardPalette[index % _songCardPalette.length];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 1.6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgTop, palette.bgBottom],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.glow,
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 7),
          ),
          const BoxShadow(
            color: Color(0x2A1E202B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 24,
            top: 12,
            child: Icon(Icons.music_note_rounded, size: 30, color: palette.noteTint),
          ),
          Positioned(
            right: 58,
            bottom: 12,
            child: Icon(Icons.music_note_rounded, size: 22, color: palette.noteTint),
          ),
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    palette.border.withValues(alpha: 0.86),
                    const Color(0xFF8D6E38),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              song['title_telugu'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF24162C),
              ),
            ),
            subtitle: Text(
              song['title_english'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF544668),
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            trailing: Icon(
              appFeatureStore.isFavorite(songId)
                  ? Icons.favorite
                  : Icons.chevron_right_rounded,
              color:
                  appFeatureStore.isFavorite(songId) ? const Color(0xFFB6386A) : const Color(0xFF3E3251),
              size: 26,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LyricViewScreen(
                    songId: songId,
                    song: song,
                    playlist: playlist,
                    currentIndex: currentIndex,
                  ),
                ),
              );
            },
            onLongPress: widget.isAdmin
                ? () => _showSongOptions(
                      context,
                      songId,
                      song,
                    )
                : null,
          ),
        ],
      ),
    );
  }

  void _showSongOptions(
    BuildContext context,
    String songId,
    Map<String, dynamic> song,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              song['title_english'] ?? 'Song',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: ccmBlue),
              title: const Text('Edit Song'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditSongScreen(songId: songId, song: song),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Song'),
              onTap: () {
                Navigator.pop(context);
                _deleteSong(context, songId, song['title_english'] ?? 'Song');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSong(BuildContext context, String songId, String songTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "$songTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('songs')
                    .doc(songId)
                    .delete();

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Song deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting song: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _GlowPalette {
  final Color border;
  final Color glow;
  final Color noteTint;
  final Color bgTop;
  final Color bgBottom;

  const _GlowPalette({
    required this.border,
    required this.glow,
    required this.noteTint,
    required this.bgTop,
    required this.bgBottom,
  });
}
