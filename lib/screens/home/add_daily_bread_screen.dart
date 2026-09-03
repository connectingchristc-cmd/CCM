import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/media_upload_service.dart';
import '../../core/notification_service.dart';

class AddDailyBreadScreen extends StatefulWidget {
  const AddDailyBreadScreen({super.key});

  @override
  State<AddDailyBreadScreen> createState() => _AddDailyBreadScreenState();
}

class _AddDailyBreadScreenState extends State<AddDailyBreadScreen> {
  final _formKey = GlobalKey<FormState>();

  final _verseController = TextEditingController();

  final _referenceController = TextEditingController();

  final _imageUrlController = TextEditingController();

  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  bool _sendNotification = false;

  Future<void> _submitDailyBread() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final verse = _verseController.text.trim();

      final ref = _referenceController.text.trim();

      await FirebaseFirestore.instance.collection('daily_bread').add({
        'verse': verse,
        'reference': ref,
        'imageUrl': _imageUrlController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (_sendNotification) {
        await sendNotificationRecord(
          title: 'Daily Bread Updated',
          body: '$ref: "$verse"',
          category: 'daily_bread',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily Bread added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding Daily Bread: $e'),
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
    _verseController.dispose();
    _referenceController.dispose();
    _imageUrlController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Daily Bread',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ccmBlue,
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ccmBlue.withValues(alpha: 0.05), ccmWhite],
          ),
        ),

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),

          child: Form(
            key: _formKey,

            child: Column(
              children: [
                TextFormField(
                  controller: _verseController,

                  maxLines: 6,

                  decoration: InputDecoration(
                    labelText: 'Bible Verse',

                    hintText: 'Enter the bible verse text...',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmBlue, width: 2),
                    ),

                    alignLabelWithHint: true,
                  ),

                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _referenceController,

                  decoration: InputDecoration(
                    labelText: 'Bible Reference',

                    hintText: 'e.g., John 3:16',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmBlue, width: 2),
                    ),

                    prefixIcon: const Icon(Icons.book, color: ccmBlue),
                  ),

                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _imageUrlController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: _imageUrlController.text.isEmpty
                        ? 'Upload image from mobile'
                        : 'Image uploaded',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),

                      borderSide: const BorderSide(color: ccmBlue, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.image, color: ccmBlue),
                    suffixIcon: _isUploadingImage
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            onPressed: () async {
                              setState(() => _isUploadingImage = true);
                              try {
                                final uploadedUrl = await MediaUploadService.pickAndUploadImage(
                                  folder: 'daily_bread_images',
                                );
                                if (uploadedUrl != null) {
                                  setState(() {
                                    _imageUrlController.text = uploadedUrl;
                                  });
                                }
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Image upload failed: $error'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isUploadingImage = false);
                                }
                              }
                            },
                            icon: const Icon(Icons.file_upload_outlined),
                          ),
                  ),
                ),

                if (_imageUrlController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _imageUrlController.text,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                CheckboxListTile(
                  value: _sendNotification,

                  onChanged: (val) {
                    setState(() {
                      _sendNotification = val ?? false;
                    });
                  },

                  title: const Text('Send notification to members'),

                  activeColor: ccmBlue,

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
                      backgroundColor: ccmBlue,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    onPressed: _isSubmitting ? null : _submitDailyBread,

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
                      _isSubmitting ? 'Saving...' : 'Add Daily Bread',

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
