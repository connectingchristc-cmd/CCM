import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/notification_service.dart';

class AddSongScreen extends StatefulWidget {
  const AddSongScreen({super.key});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
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

  final _engTitleController = TextEditingController();

  final _telTitleController = TextEditingController();

  final _lyricsController = TextEditingController();

  final _keyController = TextEditingController();

  final _chordsController = TextEditingController();

  String? _category;

  bool _isSubmitting = false;
  bool _sendNotification = false;

  Future<void> _submitSong() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final titleEng = _engTitleController.text.trim();

      final titleTel = _telTitleController.text.trim();

      await FirebaseFirestore.instance.collection('songs').add({
        'title_english': titleEng,
        'title_telugu': titleTel,
        'lyrics': _lyricsController.text.trim(),
        'key': _keyController.text.trim(),
        'chords': _chordsController.text.trim(),
        'category': _category,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (_sendNotification) {
        await sendNotificationRecord(
          title: 'New Song Added',
          body: '$titleEng ($titleTel) is now available in CCM App.',
          category: 'song',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding song: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Song',
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
                // ================= ENGLISH TITLE =================

                TextFormField(
                  controller: _engTitleController,

                  decoration: InputDecoration(
                    labelText: 'Title in English',

                    hintText: 'e.g., Aaradhana Neeke',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmRed, width: 2),
                    ),

                    prefixIcon: const Icon(Icons.title, color: ccmRed),
                  ),

                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                // ================= KEY =================
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

                // ================= CATEGORY =================
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

                // ================= CHORDS =================
                TextFormField(
                  controller: _chordsController,

                  maxLines: 5,

                  decoration: InputDecoration(
                    labelText: 'Chords (optional)',

                    hintText:
                        'Paste chord notation here, for example: G  D  Em  C',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 16),

                // ================= TELUGU TITLE =================
                TextFormField(
                  controller: _telTitleController,

                  decoration: InputDecoration(
                    labelText: 'Title in Telugu',

                    hintText: 'e.g., ఆరాధన నీకే',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmRed, width: 2),
                    ),

                    prefixIcon: const Icon(Icons.language, color: ccmRed),
                  ),

                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                // ================= LYRICS =================
                TextFormField(
                  controller: _lyricsController,

                  maxLines: 12,

                  decoration: InputDecoration(
                    labelText: 'Song Lyrics',

                    hintText: 'Enter song lyrics in Telugu script...',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmRed, width: 2),
                    ),

                    alignLabelWithHint: true,
                  ),

                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                // ================= NOTIFICATION =================
                CheckboxListTile(
                  value: _sendNotification,

                  onChanged: (val) {
                    setState(() {
                      _sendNotification = val ?? false;
                    });
                  },

                  title: const Text('Send notification to members'),

                  activeColor: ccmRed,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= SAVE BUTTON =================
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

                    onPressed: _isSubmitting ? null : _submitSong,

                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,

                              valueColor: const AlwaysStoppedAnimation<Color>(
                                ccmWhite,
                              ),
                            ),
                          )
                        : const Icon(Icons.save),

                    label: Text(
                      _isSubmitting ? 'Saving...' : 'Save & Publish Song',

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

  @override
  void dispose() {
    _engTitleController.dispose();
    _telTitleController.dispose();
    _lyricsController.dispose();
    _keyController.dispose();
    _chordsController.dispose();

    super.dispose();
  }
}
