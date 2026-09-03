import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/media_upload_service.dart';
import 'daily_devotion_manage_screen.dart';
import 'upcoming_events_manage_screen.dart';
import '../songs/songs_screen.dart';

class AdminManageScreen extends StatelessWidget {
  final bool isAdmin;
  const AdminManageScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const Scaffold(body: Center(child: Text('Admin access required')));
    }
    final items = <_ManageItem>[
      _ManageItem(
        'Add Songs',
        'Manage songs with edit and delete controls',
        Icons.music_note_outlined,
        () => _go(context, const SongsScreen(isAdmin: true)),
        assetPath: 'assets/media.png',
      ),
      _ManageItem(
        'Add Slider',
        'Manage homepage slider images and text',
        Icons.view_carousel_outlined,
        () => _go(
          context,
          const ContentManagerPage(
            title: 'Sliders',
            collection: 'homepage_hero_slides',
            kind: ContentKind.slider,
          ),
        ),
        assetPath: 'assets/service.png',
      ),
      _ManageItem(
        'Add Upcoming Events',
        'Create, edit, disable and reorder upcoming events',
        Icons.event_outlined,
        () => _go(context, const UpcomingEventsManageScreen()),
        assetPath: 'assets/events.png',
      ),
      _ManageItem(
        'Homepage Cards',
        'Edit card titles, descriptions and actions',
        Icons.dashboard_customize_outlined,
        () => _go(
          context,
          const ContentManagerPage(
            title: 'Homepage Cards',
            collection: 'homepage_action_cards',
            kind: ContentKind.card,
          ),
        ),
        assetPath: 'assets/about.png',
      ),
      _ManageItem(
        'Add Media',
        'Sermons, Inspirational, Videos, Missionary, Music and Sunday School',
        Icons.perm_media_outlined,
        () => _go(context, const MediaManagerPage()),
        assetPath: 'assets/media.png',
      ),
      _ManageItem(
        'Add Testimonials',
        'Add, edit and delete testimonials',
        Icons.favorite_border,
        () => _go(
          context,
          const ContentManagerPage(
            title: 'Testimonials',
            collection: 'testimonials',
            kind: ContentKind.testimonial,
          ),
        ),
        assetPath: 'assets/testimonials.png',
      ),
      _ManageItem(
        'Highlights',
        'Manage service/event/set highlights and popup visibility',
        Icons.auto_awesome_outlined,
        () => _go(
          context,
          const ContentManagerPage(
            title: 'Highlights',
            collection: 'highlights',
            kind: ContentKind.highlight,
          ),
        ),
        assetPath: 'assets/events.png',
      ),
      _ManageItem(
        'Gospel',
        'Upload, edit and delete gospel tracts (image/pdf/word)',
        Icons.menu_book_outlined,
        () => _go(
          context,
          const ContentManagerPage(
            title: 'Gospel',
            collection: 'gospel_tracts',
            kind: ContentKind.gospel,
          ),
        ),
        assetPath: 'assets/about.png',
      ),
      _ManageItem(
        'Prayer Request',
        'Callbacks, prayers and prayer-cell members',
        Icons.volunteer_activism_outlined,
        () => _go(context, const PrayerRequestsPage()),
        assetPath: 'assets/prayerrequest.png',
      ),
      _ManageItem(
        'Add Daily Devotion',
        'Create, edit, disable and reorder daily devotion images',
        Icons.menu_book_outlined,
        () => _go(context, const DailyDevotionManageScreen()),
        assetPath: 'assets/dailybread.png',
      ),
      _ManageItem(
        'Add Live Stream',
        'Manage live stream details',
        Icons.live_tv_outlined,
        () => _go(
          context,
          const ContentManagerPage(
            title: 'Live Stream',
            collection: 'live_streams',
            kind: ContentKind.stream,
          ),
        ),
        assetPath: 'assets/livestream.png',
      ),
      _ManageItem(
        'About Us',
        'Update ministry information',
        Icons.info_outline,
        () => _go(
          context,
          const ContentManagerPage(
            title: 'About Us',
            collection: 'about_us',
            kind: ContentKind.about,
          ),
        ),
        assetPath: 'assets/about.png',
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _ManageCard(item: items[index]),
      ),
    );
  }

  static void _go(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _ManageItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? assetPath;
  const _ManageItem(
    this.title,
    this.subtitle,
    this.icon,
    this.onTap, {
    this.assetPath,
  });
}

class _ManageCard extends StatelessWidget {
  final _ManageItem item;
  const _ManageCard({required this.item});
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: item.assetPath == null
                  ? Icon(item.icon, color: ccmRed, size: 28)
                  : Image.asset(
                      item.assetPath!,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.multiply,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(item.icon, color: ccmRed, size: 28),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: ccmInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(color: ccmMutedInk, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ccmRed),
          ],
        ),
      ),
    ),
  );
}

enum ContentKind { slider, event, card, testimonial, stream, about, highlight, gospel }

class ContentManagerPage extends StatelessWidget {
  final String title;
  final String collection;
  final ContentKind kind;
  const ContentManagerPage({
    super.key,
    required this.title,
    required this.collection,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final docs = [...?snapshot.data?.docs]
          ..sort(
            (a, b) => ((a.data()['sortOrder'] ?? 0) as num).compareTo(
              (b.data()['sortOrder'] ?? 0) as num,
            ),
          );
        return Stack(
          children: [
            if (snapshot.hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Unable to load $title: ${snapshot.error}'),
                ),
              )
            else if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator(color: ccmRed))
            else if (docs.isEmpty)
              const Center(child: Text('No items yet. Tap + to add one.'))
            else
              ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _ContentTile(
                  doc: docs[index],
                  collection: collection,
                  kind: kind,
                ),
              ),
            Positioned(
              right: 18,
              bottom: 18,
              child: FloatingActionButton(
                onPressed: () => ContentEditor.show(
                  context,
                  collection: collection,
                  kind: kind,
                ),
                backgroundColor: ccmRed,
                foregroundColor: ccmWhite,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ContentTile extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final String collection;
  final ContentKind kind;
  const _ContentTile({
    required this.doc,
    required this.collection,
    required this.kind,
  });
  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        title: Text(
            collection.startsWith('prayer_')
            ? (data['name']?.toString().trim().isNotEmpty == true
              ? data['name'].toString()
              : 'Prayer Request')
            : data['title']?.toString() ?? 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          kind == ContentKind.testimonial
              ? '${data['testimony'] ?? data['details'] ?? data['subtitle'] ?? ''}'
              : collection.startsWith('prayer_')
              ? '${data['name'] ?? ''} • ${data['phone'] ?? data['mobile'] ?? ''}\n${data['details'] ?? data['prayerRequest'] ?? data['callbackDetails'] ?? data['place'] ?? ''}\n${data['isRead'] == true ? 'Read' : 'Unread'}'
              : kind == ContentKind.gospel
              ? '${data['details'] ?? ''}\n${data['fileUrl'] ?? ''}\n${data['enabled'] == false ? 'Hidden' : 'Visible'}'
              : kind == ContentKind.highlight
              ? '${data['details'] ?? ''}\n${data['highlightBasis'] ?? ''}${(data['eventName']?.toString().trim().isNotEmpty == true) ? ' • ${data['eventName']}' : ''}${data['addToHomePopup'] == true ? ' • Popup' : ''}'
              : '${data['details'] ?? data['subtitle'] ?? ''}\n${data['enabled'] == false ? 'Hidden' : 'Visible'}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          children: [
            if (collection.startsWith('prayer_'))
              IconButton(
                icon: Icon(
                  data['isRead'] == true
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  color: ccmBlue,
                ),
                tooltip: data['isRead'] == true ? 'Mark unread' : 'Mark read',
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection(collection)
                      .doc(doc.id)
                      .update({
                        'isRead': data['isRead'] == true ? false : true,
                        'updated_at': FieldValue.serverTimestamp(),
                      });
                },
              ),
            if (!collection.startsWith('prayer_'))
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: ccmRed),
                onPressed: () => ContentEditor.show(
                  context,
                  collection: collection,
                  kind: kind,
                  doc: doc,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: ccmRed),
              onPressed: () async {
                if (await _confirm(context)) {
                  await FirebaseFirestore.instance
                      .collection(collection)
                      .doc(doc.id)
                      .delete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete item?'),
          content: const Text('This content will be removed.'),
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
}

class ContentEditor {
  static Future<void> show(
    BuildContext context, {
    required String collection,
    required ContentKind kind,
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final data = doc?.data() ?? {};
    final title = TextEditingController(text: data['title']?.toString() ?? '');
    final name = TextEditingController(text: data['name']?.toString() ?? '');
    final category = TextEditingController(
      text: data['category']?.toString() ?? '',
    );
    final highlightBasis = TextEditingController(
      text: data['highlightBasis']?.toString() ?? '',
    );
    final eventName = TextEditingController(
      text: data['eventName']?.toString() ?? '',
    );
    var videoUrl = data['videoUrl']?.toString() ?? '';
    var fileUrl = data['fileUrl']?.toString() ?? '';
    final details = TextEditingController(
      text:
          data['testimony']?.toString() ??
          data['details']?.toString() ??
          data['subtitle']?.toString() ??
          '',
    );
    var imageUrl = data['imageUrl']?.toString() ?? data['photoUrl']?.toString() ?? '';
    final order = TextEditingController(text: '${data['sortOrder'] ?? 0}');
    final actionType = TextEditingController(
      text: data['actionType']?.toString() ?? 'comingSoon',
    );
    bool enabled = data['enabled'] != false;
    bool addToHomePopup = data['addToHomePopup'] == true;
    var isUploadingImage = false;
    var isUploadingVideo = false;
    var isUploadingFile = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${doc == null ? 'Add' : 'Edit'} ${_label(kind)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kind == ContentKind.highlight)
                  TextField(
                    controller: highlightBasis,
                    decoration: const InputDecoration(
                      labelText: 'Highlight Basis',
                      helperText: 'service / event / set',
                    ),
                  ),
                if (kind == ContentKind.highlight) const SizedBox(height: 10),
                if (kind == ContentKind.highlight)
                  TextField(
                    controller: eventName,
                    decoration: const InputDecoration(
                      labelText: 'Event Name (Optional)',
                    ),
                  ),
                if (kind == ContentKind.highlight) const SizedBox(height: 10),
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: kind == ContentKind.testimonial
                        ? 'Testimonial Title *'
                        : 'Title *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: details,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: kind == ContentKind.about
                        ? 'About text'
                        : kind == ContentKind.testimonial
                        ? 'Your Testimony *'
                        : 'Details / subtitle',
                  ),
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
                                    folder: collection,
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
                if (kind == ContentKind.testimonial) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploadingVideo
                              ? null
                              : () async {
                                  setState(() => isUploadingVideo = true);
                                  try {
                                    final uploadedUrl = await MediaUploadService.pickAndUploadVideo(
                                      folder: 'testimonials/videos',
                                    );
                                    if (uploadedUrl != null) {
                                      setState(() => videoUrl = uploadedUrl);
                                    }
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Video upload failed: $error'),
                                      ),
                                    );
                                  } finally {
                                    setState(() => isUploadingVideo = false);
                                  }
                                },
                          icon: const Icon(Icons.video_file_outlined),
                          label: Text(
                            isUploadingVideo
                                ? 'Uploading video...'
                                : videoUrl.isEmpty
                                ? 'Upload video from mobile'
                                : 'Replace uploaded video',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (videoUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Video uploaded',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
                if (kind == ContentKind.gospel) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploadingFile
                              ? null
                              : () async {
                                  setState(() => isUploadingFile = true);
                                  try {
                                    final uploadedUrl = await MediaUploadService.pickAndUploadDocument(
                                      folder: 'gospel_tracts/files',
                                    );
                                    if (uploadedUrl != null) {
                                      setState(() => fileUrl = uploadedUrl);
                                    }
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('File upload failed: $error'),
                                      ),
                                    );
                                  } finally {
                                    setState(() => isUploadingFile = false);
                                  }
                                },
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(
                            isUploadingFile
                                ? 'Uploading file...'
                                : fileUrl.isEmpty
                                ? 'Upload file (Image/PDF/Word)'
                                : 'Replace uploaded file',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (fileUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'File uploaded',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: order,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Display order'),
                ),
                if (kind == ContentKind.card)
                  TextField(
                    controller: actionType,
                    decoration: const InputDecoration(
                      labelText: 'Action type',
                      helperText: 'services, events, dailyBread or comingSoon',
                    ),
                  ),
                if (kind == ContentKind.highlight)
                  SwitchListTile(
                    title: const Text('Add highlights to Home Page popup'),
                    value: addToHomePopup,
                    onChanged: (value) => setState(() => addToHomePopup = value),
                  ),
                SwitchListTile(
                  title: const Text('Visible'),
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true ||
      title.text.trim().isEmpty ||
      (kind == ContentKind.testimonial && details.text.trim().isEmpty) ||
      (kind == ContentKind.gospel && fileUrl.trim().isEmpty)) {
      return;
    }
    final payload = <String, dynamic>{
      'title': title.text.trim(),
      'name': name.text.trim(),
      'category': category.text.trim(),
      'videoUrl': videoUrl.trim(),
      'fileUrl': fileUrl.trim(),
      'subtitle': details.text.trim(),
      'details': details.text.trim(),
      'testimony': details.text.trim(),
      'imageUrl': imageUrl.trim(),
      'photoUrl': imageUrl.trim(),
      'highlightBasis': highlightBasis.text.trim(),
      'eventName': eventName.text.trim(),
      'addToHomePopup': addToHomePopup,
      'sortOrder': int.tryParse(order.text) ?? 0,
      'enabled': enabled,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (kind == ContentKind.card) {
      payload['actionType'] = actionType.text.trim().isEmpty
          ? 'comingSoon'
          : actionType.text.trim();
    }
    try {
      if (doc == null) {
        payload['created_at'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection(collection).add(payload);
      } else {
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(doc.id)
            .update(payload);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_label(kind)} saved successfully')),
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save ${_label(kind)}: ${error.message ?? error.code}',
            ),
          ),
        );
      }
    }
  }

  static String _label(ContentKind kind) => switch (kind) {
    ContentKind.slider => 'Slider',
    ContentKind.event => 'Event',
    ContentKind.card => 'Homepage Card',
    ContentKind.testimonial => 'Testimonial',
    ContentKind.stream => 'Live Stream',
    ContentKind.about => 'About Us',
    ContentKind.highlight => 'Highlight',
    ContentKind.gospel => 'Gospel',
  };
}

class MediaManagerPage extends StatelessWidget {
  const MediaManagerPage({super.key});
  static const categories = [
    'Sermons',
    'Inspirational',
    'Videos',
    'Missionary',
    'Music',
    'Sunday School',
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Media')),
    body: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ManageCard(
        item: _ManageItem(
          categories[index],
          'Manage ${categories[index].toLowerCase()} media',
          Icons.play_circle_outline,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContentManagerPage(
                title: categories[index],
                collection:
                    'media_${categories[index].toLowerCase().replaceAll(' ', '_')}',
                kind: ContentKind.event,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PrayerRequestsPage extends StatelessWidget {
  const PrayerRequestsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prayer Requests')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ManageCard(
          item: _ManageItem(
            'Requested Call Backs',
            'Name, mobile number and location',
            Icons.phone_callback_outlined,
            () => _open(context, 'prayer_callbacks', 'Requested Call Backs'),
          ),
        ),
        const SizedBox(height: 12),
        _ManageCard(
          item: _ManageItem(
            'Requested Prayers',
            'Open each prayer request detail',
            Icons.volunteer_activism_outlined,
            () => _open(context, 'prayer_requests', 'Requested Prayers'),
          ),
        ),
        const SizedBox(height: 12),
        _ManageCard(
          item: _ManageItem(
            'Join the Prayer Cell',
            'Name, mobile number and location',
            Icons.groups_outlined,
            () => _open(context, 'prayer_cell', 'Prayer Cell Members'),
          ),
        ),
      ],
    ),
  );
  static void _open(BuildContext context, String collection, String title) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContentManagerPage(
            title: title,
            collection: collection,
            kind: ContentKind.testimonial,
          ),
        ),
      );
}
