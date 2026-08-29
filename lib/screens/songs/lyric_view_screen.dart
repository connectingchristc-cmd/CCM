import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class LyricViewScreen extends StatefulWidget {
  final Map<String, dynamic> song;
  final String songId;
  final List<Map<String, dynamic>>? playlist;
  final int? currentIndex;

  const LyricViewScreen({
    super.key,
    required this.songId,
    required this.song,
    this.playlist,
    this.currentIndex,
  });

  @override
  State<LyricViewScreen> createState() => _LyricViewScreenState();
}

class _LyricViewScreenState extends State<LyricViewScreen> {
  late double _fontSize;

  int _transpose = 0;

  late Map<String, dynamic> _currentSong;

  late String _currentSongId;

  int? _currentIndex;

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
    _currentSongId = widget.songId;
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

        _currentSongId = nextSong['id']?.toString() ?? '';

        _transpose = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPlaylist = widget.playlist != null && widget.playlist!.length > 1;

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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _currentSong['title_english'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),

        backgroundColor: ccmSandDark,
        foregroundColor: ccmInk,

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
            colors: [ccmSandDark.withValues(alpha: 0.35), ccmSand],
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a1a),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _currentSong['title_english'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF404040),
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
        backgroundColor: ccmSandDark,
        foregroundColor: ccmInk,

        onPressed: () {
          Navigator.pop(context);
        },

        child: const Icon(Icons.arrow_back, color: ccmWhite),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
