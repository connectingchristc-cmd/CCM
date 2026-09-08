import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String _selectedCategory = '';
  final bool _favoritesOnly = false;
  bool _effectiveIsAdmin = false;

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _songCategories = [
    'Praise',
    'Worship',
    'Gospel',
    'Thanksgiving',
    'Prayer',
    'Confession / Repentance',
    'Holy Communion',
    'Wedding',
    'Christmas',
    'Good Friday',
    'Resurrection',
    'Sunday School',
    'Action Songs',
  ];

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
  void initState() {
    super.initState();
    _effectiveIsAdmin = widget.isAdmin;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      _refreshAdminStatus();
    });
    _refreshAdminStatus();
  }

  @override
  void didUpdateWidget(covariant SongsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAdmin != widget.isAdmin) {
      _effectiveIsAdmin = widget.isAdmin;
      _refreshAdminStatus();
    }
  }

  Future<void> _refreshAdminStatus() async {
    if (widget.isAdmin) {
      if (mounted) {
        setState(() => _effectiveIsAdmin = true);
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _effectiveIsAdmin = false);
      }
      return;
    }

    try {
      final token = await user.getIdTokenResult(true);
      final hasCustomClaimAdmin = token.claims?['admin'] == true;

      if (hasCustomClaimAdmin) {
        if (mounted) {
          setState(() => _effectiveIsAdmin = true);
        }
        return;
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        if (mounted) {
          setState(() => _effectiveIsAdmin = true);
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      final isAdminUser =
          data?['role'] == 'admin' || data?['isAdmin'] == true;

      if (mounted) {
        setState(() => _effectiveIsAdmin = isAdminUser);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _effectiveIsAdmin = false);
      }
    }
  }

  void _clearSearchState() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSongFilters(Map<String, dynamic> song) {
    final eng = (song['title_english'] ?? '').toString().toLowerCase();
    final tel = (song['title_telugu'] ?? '').toString().toLowerCase();
    final lyrics = (song['lyrics'] ?? '').toString().toLowerCase();
    final category = (song['category'] ?? '').toString();
    final matchesCategory =
        _selectedCategory.isEmpty || category == _selectedCategory;
    final matchesSearch =
        eng.contains(_searchQuery) || tel.contains(_searchQuery) || lyrics.contains(_searchQuery);

    return matchesCategory &&
        matchesSearch &&
        (!_favoritesOnly || appFeatureStore.isFavorite(song['id'].toString()));
  }

  @override
  Widget build(BuildContext context) {
    final showAddButton = widget.isAdmin || _effectiveIsAdmin;

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
                                final data = {'id': doc.id, ...doc.data()};
                                return _matchesSongFilters(data);
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
      floatingActionButton: showAddButton
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
            height: 82,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
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
                    size: 54,
                    color: const Color(0xFFFFD67A).withValues(alpha: 0.34),
                  ),
                ),
                Positioned(
                  right: -18,
                  bottom: -12,
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 62,
                    color: const Color(0xFFFFD67A).withValues(alpha: 0.18),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      'Songs',
                      style: GoogleFonts.cinzelDecorative(
                        color: const Color(0xFFFFC85A),
                        fontSize: 24,
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
                  top: 10,
                  right: 10,
                  child: _buildCategoryFilterButton(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterButton() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF1A294B).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEED89B).withValues(alpha: 0.65),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Filter by category',
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFFEED89B)),
        onSelected: (value) {
          setState(() {
            _selectedCategory = value;
          });
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(value: '', child: Text('All Categories')),
          ..._songCategories.map(
            (category) => PopupMenuItem<String>(
              value: category,
              child: Text(category),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
            width: 34,
            height: 34,
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
            child: const Icon(Icons.search, color: Color(0xFFB7BDD4), size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: const Color(0xFFB7BDD4),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _selectedCategory.isEmpty
                    ? 'Search songs (Telugu or English)...'
                    : 'Search in $_selectedCategory',
                hintStyle: const TextStyle(
                  color: Color(0xFFB7BDD4),
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                filled: false,
                isDense: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.clear, color: Color(0xFFB7BDD4), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  RadialGradient(colors: [Color(0xFFF9DA84), Color(0xFF684B16)]),
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
            'Total Songs: $count',
            style: const TextStyle(
              color: Color(0xFFF4E1B0),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (favoritesFiltered)
            const Text(
              'Favorites',
              style: TextStyle(color: Color(0xFFD8BCD0), fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildCachedSongs() {
    final cached = appFeatureStore.cachedSongs.values.where((song) {
      final data = {'id': song['id'].toString(), ...song};
      return _matchesSongFilters(data);
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
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF3E3251),
              size: 26,
            ),
            onTap: () async {
              _clearSearchState();

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LyricViewScreen(
                    songId: songId,
                    song: song,
                    playlist: playlist,
                    currentIndex: currentIndex,
                    paletteIndex: currentIndex % _songCardPalette.length,
                  ),
                ),
              );

              if (!mounted) {
                return;
              }

              _clearSearchState();
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
