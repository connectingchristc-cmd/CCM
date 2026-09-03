import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/media_upload_service.dart';
import '../../core/notification_service.dart';

class DailyDevotionManageScreen extends StatelessWidget {
  const DailyDevotionManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Daily Devotion', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('daily_devotions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load devotions: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: ccmRed));
          }

          final docs = [...?snapshot.data?.docs]
            ..sort((a, b) => ((a.data()['sortOrder'] ?? 0) as num)
                .compareTo((b.data()['sortOrder'] ?? 0) as num));

          return Stack(
            children: [
              if (docs.isEmpty)
                const Center(child: Text('No Daily Devotion yet. Tap + to add.'))
              else
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 88),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _DevotionTile(
                    doc: docs[index],
                    canMoveUp: index > 0,
                    canMoveDown: index < docs.length - 1,
                    onMoveUp: () => _moveOrder(docs[index], docs[index - 1]),
                    onMoveDown: () => _moveOrder(docs[index], docs[index + 1]),
                  ),
                ),
              Positioned(
                right: 18,
                bottom: 18,
                child: FloatingActionButton(
                  backgroundColor: ccmRed,
                  foregroundColor: ccmWhite,
                  onPressed: () => DailyDevotionEditorDialog.show(context),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _moveOrder(
    DocumentSnapshot<Map<String, dynamic>> current,
    DocumentSnapshot<Map<String, dynamic>> target,
  ) async {
    final currentOrder = (current.data()?['sortOrder'] ?? 0) as num;
    final targetOrder = (target.data()?['sortOrder'] ?? 0) as num;

    final batch = FirebaseFirestore.instance.batch();
    batch.update(current.reference, {'sortOrder': targetOrder});
    batch.update(target.reference, {'sortOrder': currentOrder});
    await batch.commit();
  }
}

class _DevotionTile extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _DevotionTile({
    required this.doc,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    final date = data['devotionDate']?.toString() ?? 'No date';
    final enabled = data['enabled'] != false;

    return Card(
      child: ListTile(
        title: Text('Daily Devotion - $date', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(enabled ? 'Enabled' : 'Disabled'),
        trailing: SizedBox(
          width: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: canMoveUp ? onMoveUp : null,
                icon: const Icon(Icons.keyboard_arrow_up, color: ccmRed),
              ),
              IconButton(
                onPressed: canMoveDown ? onMoveDown : null,
                icon: const Icon(Icons.keyboard_arrow_down, color: ccmRed),
              ),
              IconButton(
                onPressed: () => DailyDevotionEditorDialog.show(context, doc: doc),
                icon: const Icon(Icons.edit_outlined, color: ccmRed),
              ),
              IconButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete daily devotion?'),
                          content: const Text('This will delete it from database.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (!ok) return;
                  await doc.reference.delete();
                },
                icon: const Icon(Icons.delete_outline, color: ccmRed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DailyDevotionEditorDialog {
  static Future<void> show(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final data = doc?.data() ?? <String, dynamic>{};
    final date = TextEditingController(text: data['devotionDate']?.toString() ?? '');
    var imageUrl = data['imageUrl']?.toString() ?? '';

    var enabled = data['enabled'] != false;
    var notifyMembers = data['notifyMembers'] == true;
    var isUploadingImage = false;

    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(doc == null ? 'Add Daily Devotion' : 'Edit Daily Devotion'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: date,
                      decoration: const InputDecoration(labelText: 'Dailydevotion Date *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: imageUrl.isEmpty
                            ? 'Upload image from mobile *'
                            : 'Image uploaded',
                        suffixIcon: isUploadingImage
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
                                  setState(() => isUploadingImage = true);
                                  try {
                                    final uploadedUrl = await MediaUploadService.pickAndUploadImage(
                                      folder: 'daily_devotions',
                                    );
                                    if (uploadedUrl != null) {
                                      setState(() => imageUrl = uploadedUrl);
                                    }
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Image upload failed: $error'),
                                      ),
                                    );
                                  } finally {
                                    setState(() => isUploadingImage = false);
                                  }
                                },
                                icon: const Icon(Icons.file_upload_outlined),
                              ),
                      ),
                    ),
                    if (imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    SwitchListTile(
                      value: enabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable / Disable'),
                      onChanged: (value) => setState(() => enabled = value),
                    ),
                    CheckboxListTile(
                      value: notifyMembers,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notify Members'),
                      onChanged: (value) => setState(() => notifyMembers = value ?? false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                if (imageUrl.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please upload an image')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final payload = <String, dynamic>{
      'devotionDate': date.text.trim(),
      'imageUrl': imageUrl.trim(),
      'enabled': enabled,
      'notifyMembers': notifyMembers,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (doc == null) {
      final existing = await FirebaseFirestore.instance.collection('daily_devotions').get();
      payload['sortOrder'] = existing.docs.length;
      payload['created_at'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('daily_devotions').add(payload);
    } else {
      await doc.reference.update(payload);
    }

    if (notifyMembers) {
      await sendNotificationRecord(
        title: 'Daily Devotion Updated',
        body: 'Daily devotion for ${date.text.trim()} is available now.',
        category: 'daily_devotion',
      );
    }
  }
}
