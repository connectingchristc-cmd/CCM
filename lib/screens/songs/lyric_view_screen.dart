import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class LyricViewScreen extends StatefulWidget {
  final Map<String, dynamic> song;
  final String songId;
  final List<Map<String, dynamic>>? playlist;
  final int? currentIndex;
  final int? paletteIndex;

  const LyricViewScreen({
    super.key,
    required this.songId,
    required this.song,
    this.playlist,
    this.currentIndex,
    this.paletteIndex,
  });

  @override
  State<LyricViewScreen> createState() => _LyricViewScreenState();
}

class _LyricViewScreenState extends State<LyricViewScreen> {
  late double _fontSize;

  int _transpose = 0;

  late Map<String, dynamic> _currentSong;

  int? _currentIndex;

  static const List<_LyricPalette> _palettes = [
    _LyricPalette(
      border: Color(0xFFF2A8B9),
      glow: Color(0x66F2A8B9),
      appBarTop: Color(0xFFF7C3D1),
      appBarBottom: Color(0xFFED9CB3),
      bodyTop: Color(0xFFFFEAF1),
      bodyBottom: Color(0xFFFFD8E5),
      accent: Color(0xFF3F2332),
      text: Color(0xFF23161C),
    ),
    _LyricPalette(
      border: Color(0xFFF2C67D),
      glow: Color(0x66F2C67D),
      appBarTop: Color(0xFFF5DAB2),
      appBarBottom: Color(0xFFF0C267),
      bodyTop: Color(0xFFFFF1D8),
      bodyBottom: Color(0xFFF9E3B8),
      accent: Color(0xFF513B1C),
      text: Color(0xFF2A2014),
    ),
    _LyricPalette(
      border: Color(0xFFEDAE8A),
      glow: Color(0x66EDAE8A),
      appBarTop: Color(0xFFF6D0B6),
      appBarBottom: Color(0xFFF0AE7A),
      bodyTop: Color(0xFFFFF0E8),
      bodyBottom: Color(0xFFF9D8C0),
      accent: Color(0xFF4B3124),
      text: Color(0xFF251A17),
    ),
    _LyricPalette(
      border: Color(0xFFC9D978),
      glow: Color(0x66C9D978),
      appBarTop: Color(0xFFE7F0AF),
      appBarBottom: Color(0xFFCCD978),
      bodyTop: Color(0xFFF4F9D9),
      bodyBottom: Color(0xFFE5F0B0),
      accent: Color(0xFF344022),
      text: Color(0xFF1C2611),
    ),
    _LyricPalette(
      border: Color(0xFFE1A9C2),
      glow: Color(0x66E1A9C2),
      appBarTop: Color(0xFFF5D1E2),
      appBarBottom: Color(0xFFDF9BB8),
      bodyTop: Color(0xFFFFEEF7),
      bodyBottom: Color(0xFFFAE1EE),
      accent: Color(0xFF4A2E3E),
      text: Color(0xFF2D1D28),
    ),
    _LyricPalette(
      border: Color(0xFF94BFF0),
      glow: Color(0x6694BFF0),
      appBarTop: Color(0xFFD8EAFF),
      appBarBottom: Color(0xFF8EBAF1),
      bodyTop: Color(0xFFEAF4FF),
      bodyBottom: Color(0xFFCFE7FF),
      accent: Color(0xFF1F3652),
      text: Color(0xFF182330),
    ),
  ];

  static const _chordNames = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  @override
  void initState() {
    super.initState();

    _currentSong = widget.song;
    _currentIndex = widget.currentIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 350) {
      _fontSize = 16.0;
    } else if (screenWidth < 600) {
      _fontSize = 18.0;
    } else {
      _fontSize = 22.0;
    }
  }

  String _transposeChords(String chords) {
    if (_transpose == 0 || chords.trim().isEmpty) {
      return chords;
    }

    return chords.replaceAllMapped(
      RegExp(r'(?<![A-Za-z])([A-G](?:#|b)?)(m|sus|7|add|dim|aug)?'),
      (match) {
        final root = match.group(1)!;

        final suffix = match.group(2) ?? '';

        final normalized = root.replaceAll('b', '#');

        final index = _chordNames.indexOf(normalized);

        if (index == -1) {
          return match.group(0)!;
        }

        return '${_chordNames[(index + _transpose) % _chordNames.length]}$suffix';
      },
    );
  }

  void _navigateSong(int delta) {
    if (widget.playlist == null || _currentIndex == null) {
      return;
    }

    final newIndex = _currentIndex! + delta;

    if (newIndex >= 0 && newIndex < widget.playlist!.length) {
      final nextSong = widget.playlist![newIndex];

      setState(() {
        _currentIndex = newIndex;

        _currentSong = nextSong;

        _transpose = 0;
      });
    }
  }

  _LyricPalette get _palette {
    final paletteIndex = widget.paletteIndex ??
        (widget.songId.hashCode.abs() % _palettes.length);
    return _palettes[paletteIndex % _palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasPlaylist = widget.playlist != null && widget.playlist!.length > 1;
    final palette = _palette;

    final canGoPrevious = hasPlaylist && (_currentIndex ?? 0) > 0;

    final canGoNext =
        hasPlaylist && (_currentIndex ?? 0) < widget.playlist!.length - 1;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,

        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentSong['title_telugu'] ?? 'Lyrics',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: palette.accent,
              ),
            ),
            Text(
              _currentSong['title_english'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: palette.accent.withValues(alpha: 0.8)),
            ),
          ],
        ),

        backgroundColor: palette.appBarTop,
        foregroundColor: palette.accent,

        actions: [
          if (hasPlaylist) ...[
            IconButton(
              tooltip: 'Previous Song',

              icon: const Icon(Icons.arrow_back_ios, size: 18),

              onPressed: canGoPrevious ? () => _navigateSong(-1) : null,
            ),

            IconButton(
              tooltip: 'Next Song',

              icon: const Icon(Icons.arrow_forward_ios, size: 18),

              onPressed: canGoNext ? () => _navigateSong(1) : null,
            ),
          ],

          IconButton(
            icon: const Icon(Icons.text_decrease),

            onPressed: () {
              setState(() {
                _fontSize = (_fontSize - 2).clamp(14.0, 32.0);
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.text_increase),

            onPressed: () {
              setState(() {
                _fontSize = (_fontSize + 2).clamp(14.0, 32.0);
              });
            },
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.bodyTop, palette.bodyBottom],
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                _currentSong['title_telugu'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _currentSong['title_english'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: palette.accent.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),

              if ((_currentSong['chords'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: 16),

                Row(
                  children: [
                    Text(
                      'Key: ${_currentSong['key'] ?? 'Original'}',

                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const Spacer(),

                    IconButton(
                      tooltip: 'Transpose down',

                      onPressed: () {
                        setState(() {
                          _transpose = (_transpose - 1).clamp(-11, 11);
                        });
                      },

                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),

                    Text(
                      '${_transpose >= 0 ? '+' : ''}$_transpose',

                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    IconButton(
                      tooltip: 'Transpose up',

                      onPressed: () {
                        setState(() {
                          _transpose = (_transpose + 1).clamp(-11, 11);
                        });
                      },

                      icon: const Icon(Icons.keyboard_arrow_up),
                    ),
                  ],
                ),

                SelectableText(
                  _transposeChords(_currentSong['chords'].toString()),

                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 1.8,
                    color: ccmBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              SelectableText(
                _currentSong['lyrics'] ?? '',

                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.8,
                  color: const Color(0xFF1a1a1a),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: palette.appBarBottom,
        foregroundColor: palette.accent,

        onPressed: () {
          Navigator.pop(context);
        },

        child: const Icon(Icons.arrow_back, color: ccmWhite),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _LyricPalette {
  final Color border;
  final Color glow;
  final Color appBarTop;
  final Color appBarBottom;
  final Color bodyTop;
  final Color bodyBottom;
  final Color accent;
  final Color text;

  const _LyricPalette({
    required this.border,
    required this.glow,
    required this.appBarTop,
    required this.appBarBottom,
    required this.bodyTop,
    required this.bodyBottom,
    required this.accent,
    required this.text,
  });
}
