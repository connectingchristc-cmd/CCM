import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/notification_service.dart';

class EditSongScreen extends StatefulWidget {
  final String songId;
  final Map<String, dynamic> song;

  const EditSongScreen({super.key, required this.songId, required this.song});

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
  final _formKey = GlobalKey<FormState>();

  static const _categories = [
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

  late final TextEditingController _engTitleController;
  late final TextEditingController _telTitleController;
  late final TextEditingController _lyricsController;
  late final TextEditingController _keyController;
  late final TextEditingController _chordsController;

  String? _category;

  bool _isSubmitting = false;
  bool _sendNotification = false;

  @override
  void initState() {
    super.initState();

    _engTitleController = TextEditingController(
      text: widget.song['title_english'] ?? '',
    );

    _telTitleController = TextEditingController(
      text: widget.song['title_telugu'] ?? '',
    );

    _lyricsController = TextEditingController(
      text: widget.song['lyrics'] ?? '',
    );

    _keyController = TextEditingController(text: widget.song['key'] ?? '');

    _chordsController = TextEditingController(
      text: widget.song['chords'] ?? '',
    );

    final savedCategory = widget.song['category'];
    _category = _categories.contains(savedCategory)
        ? savedCategory as String
        : null;
  }

  Future<void> _updateSong() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final titleEng = _engTitleController.text.trim();

      final titleTel = _telTitleController.text.trim();

      await FirebaseFirestore.instance
          .collection('songs')
          .doc(widget.songId)
          .update({
            'title_english': titleEng,
            'title_telugu': titleTel,
            'lyrics': _lyricsController.text.trim(),
            'key': _keyController.text.trim(),
            'chords': _chordsController.text.trim(),
            'category': _category,
            'updated_at': FieldValue.serverTimestamp(),
          });

      if (_sendNotification) {
        await sendNotificationRecord(
          title: 'Song Updated',
          body: '$titleEng ($titleTel) has been updated in CCM App.',
          category: 'song',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating song: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _engTitleController.dispose();
    _telTitleController.dispose();
    _lyricsController.dispose();
    _keyController.dispose();
    _chordsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Song',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ccmSandDark,
        foregroundColor: ccmInk,
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
          padding: const EdgeInsets.all(16.0),

          child: Form(
            key: _formKey,

            child: Column(
              children: [
                TextFormField(
                  controller: _engTitleController,

                  decoration: InputDecoration(
                    labelText: 'Title in English',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmRed, width: 2),
                    ),

                    prefixIcon: const Icon(Icons.title, color: ccmRed),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category, color: ccmRed),
                  ),
                  hint: const Text('Select a category'),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _category = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _keyController,

                  decoration: InputDecoration(
                    labelText: 'Original key (optional)',

                    hintText: 'e.g., G',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    prefixIcon: const Icon(Icons.music_note, color: ccmRed),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _chordsController,

                  maxLines: 5,

                  decoration: InputDecoration(
                    labelText: 'Chords (optional)',

                    hintText: 'Paste chord notation here...',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _telTitleController,

                  decoration: InputDecoration(
                    labelText: 'Title in Telugu',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmRed, width: 2),
                    ),

                    prefixIcon: const Icon(Icons.language, color: ccmRed),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _lyricsController,

                  maxLines: 12,

                  decoration: InputDecoration(
                    labelText: 'Song Lyrics',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmRed, width: 2),
                    ),

                    alignLabelWithHint: true,
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                CheckboxListTile(
                  value: _sendNotification,

                  onChanged: (value) {
                    setState(() {
                      _sendNotification = value ?? false;
                    });
                  },

                  title: const Text('Send notification to members'),

                  activeColor: ccmRed,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ccmRed,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    onPressed: _isSubmitting ? null : _updateSong,

                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: ccmWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),

                    label: Text(
                      _isSubmitting ? 'Updating...' : 'Update Song',

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ccmWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
