import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/media_upload_service.dart';
import '../../core/notification_service.dart';

class UpcomingEventsManageScreen extends StatelessWidget {
  const UpcomingEventsManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Upcoming Events', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('homepage_events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load events: ${snapshot.error}'),
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
                const Center(child: Text('No Upcoming Events yet. Tap + to add.'))
              else
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 88),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _EventTile(
                    doc: docs[index],
                    index: index,
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
                  onPressed: () => EventEditorDialog.show(context),
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

class _EventTile extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final int index;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _EventTile({
    required this.doc,
    required this.index,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    final title = data['title']?.toString() ?? 'Untitled Event';
    final eventType = data['eventType']?.toString() ?? '';
    final enabled = data['enabled'] != false;
    final displayHome = data['displayHome'] != false;
    final displayEvents = data['displayEvents'] != false;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '$eventType\n${enabled ? 'Enabled' : 'Disabled'} | Home:${displayHome ? 'Y' : 'N'} | Events:${displayEvents ? 'Y' : 'N'}',
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Move up',
                onPressed: canMoveUp ? onMoveUp : null,
                icon: const Icon(Icons.keyboard_arrow_up, color: ccmRed),
              ),
              IconButton(
                tooltip: 'Move down',
                onPressed: canMoveDown ? onMoveDown : null,
                icon: const Icon(Icons.keyboard_arrow_down, color: ccmRed),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => EventEditorDialog.show(context, doc: doc),
                icon: const Icon(Icons.edit_outlined, color: ccmRed),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete event?'),
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

class EventEditorDialog {
  static const List<String> _eventTypes = [
    'Sunday Service',
    'Special Service',
    'Family Prayer',
    'Mid Week Service',
    'Adhoc',
    'Fasting Prayer',
    'Daily Prayer',
  ];

  static const List<String> _reminderTypes = [
    'Monthly',
    'Weekly',
    'Daily',
    'Specific date and time',
  ];

  static Future<void> show(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final data = doc?.data() ?? <String, dynamic>{};
    final name = TextEditingController(text: data['title']?.toString() ?? '');
    final details = TextEditingController(
      text: data['subtitle']?.toString() ?? data['details']?.toString() ?? '',
    );
    var imageUrl = data['imageUrl']?.toString() ?? '';
    final eventDate = TextEditingController(text: data['eventDate']?.toString() ?? '');
    final eventTime = TextEditingController(text: data['eventTime']?.toString() ?? '');

    var eventType = (data['eventType']?.toString().isNotEmpty ?? false)
        ? data['eventType'].toString()
        : _eventTypes.first;
    var reminderEnabled = data['reminderEnabled'] == true;
    var reminderType = (data['reminderType']?.toString().isNotEmpty ?? false)
        ? data['reminderType'].toString()
        : _reminderTypes.first;
    var reminderDateTime = data['reminderDateTime']?.toString() ?? '';
    var enabled = data['enabled'] != false;
    var notifyMembers = data['notifyMembers'] != false;
    var displayHome = data['displayHome'] != false;
    var displayEvents = data['displayEvents'] != false;
    var isUploadingImage = false;

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(doc == null ? 'Add Upcoming Event' : 'Edit Upcoming Event'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Event Name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: eventType,
                      items: _eventTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => eventType = value);
                      },
                      decoration: const InputDecoration(labelText: 'Event Type *'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: details,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Details (small text)'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: eventDate,
                      decoration: const InputDecoration(labelText: 'Event Date (optional)'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: eventTime,
                      decoration: const InputDecoration(labelText: 'Event Time'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isUploadingImage
                                ? null
                                : () async {
                                    setState(() => isUploadingImage = true);
                                    try {
                                      final uploadedUrl = await MediaUploadService.pickAndUploadImage(
                                        folder: 'homepage_events',
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
                            label: Text(
                              isUploadingImage
                                  ? 'Uploading image...'
                                  : imageUrl.isEmpty
                                  ? 'Upload image from mobile'
                                  : 'Replace uploaded image',
                            ),
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 6),
                    SwitchListTile(
                      value: reminderEnabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Set Reminder'),
                      onChanged: (value) => setState(() => reminderEnabled = value),
                    ),
                    if (reminderEnabled) ...[
                      DropdownButtonFormField<String>(
                        initialValue: reminderType,
                        items: _reminderTypes
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => reminderType = value);
                        },
                        decoration: const InputDecoration(labelText: 'Reminder Type'),
                      ),
                      if (reminderType == 'Specific date and time') ...[
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            reminderDateTime.isEmpty
                                ? 'Select specific date and time'
                                : reminderDateTime,
                          ),
                          trailing: const Icon(Icons.event_available_outlined),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (date == null || !context.mounted) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time == null) return;
                            final formatted =
                                '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year} '
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            setState(() => reminderDateTime = formatted);
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: notifyMembers,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notify Members'),
                      onChanged: (value) => setState(() => notifyMembers = value ?? true),
                    ),
                    CheckboxListTile(
                      value: displayHome,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Display in Home Page'),
                      onChanged: (value) => setState(() => displayHome = value ?? false),
                    ),
                    CheckboxListTile(
                      value: displayEvents,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Display in Events Page'),
                      onChanged: (value) => setState(() => displayEvents = value ?? false),
                    ),
                    SwitchListTile(
                      value: enabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable / Disable'),
                      onChanged: (value) => setState(() => enabled = value),
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
      'title': name.text.trim(),
      'subtitle': details.text.trim(),
      'details': details.text.trim(),
      'eventType': eventType,
      'eventDate': eventDate.text.trim(),
      'eventTime': eventTime.text.trim(),
      'imageUrl': imageUrl.trim(),
      'reminderEnabled': reminderEnabled,
      'reminderType': reminderEnabled ? reminderType : '',
      'reminderDateTime': reminderEnabled ? reminderDateTime : '',
      'enabled': enabled,
      'notifyMembers': notifyMembers,
      'displayHome': displayHome,
      'displayEvents': displayEvents,
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (doc == null) {
      final existing = await FirebaseFirestore.instance.collection('homepage_events').get();
      payload['sortOrder'] = existing.docs.length;
      payload['created_at'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('homepage_events').add(payload);
    } else {
      await doc.reference.update(payload);
    }

    if (notifyMembers) {
      await sendNotificationRecord(
        title: 'Upcoming Event: ${name.text.trim()}',
        body: details.text.trim().isEmpty
          ? '$eventType ${eventDate.text.trim()} ${eventTime.text.trim()}'.trim()
            : details.text.trim(),
        category: 'upcoming_events',
      );
    }
  }
}
