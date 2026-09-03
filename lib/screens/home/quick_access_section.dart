import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_colors.dart';

class QuickAccessSection extends StatefulWidget {
  final bool isAdmin;
  final QuickAccessView initialView;
  final bool showHeader;

  const QuickAccessSection({
    super.key,
    required this.isAdmin,
    this.initialView = QuickAccessView.menu,
    this.showHeader = true,
  });

  @override
  State<QuickAccessSection> createState() => _QuickAccessSectionState();
}

class _QuickAccessSectionState extends State<QuickAccessSection> {
  late QuickAccessView _activeView;

  PrayerRequestType _selectedPrayerType = PrayerRequestType.submitPrayer;
  final _prayerFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _prayerController = TextEditingController();
  final _callbackDetailsController = TextEditingController();
  final _joinPlaceController = TextEditingController();

  bool _isSubmittingPrayer = false;
  List<String> _familyMembers = <String>['None'];
  String _selectedFamilyMember = 'None';
  String _selectedHighlightEvent = 'All';

  @override
  void initState() {
    super.initState();
    _activeView = widget.initialView;
    _loadMemberPrefill();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _prayerController.dispose();
    _callbackDetailsController.dispose();
    _joinPlaceController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberPrefill() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      final fullName = (data['fullName'] ?? data['name'] ?? '').toString().trim();
      final phone = (data['phoneNumber'] ?? user.phoneNumber ?? '').toString().trim();

      if (_nameController.text.trim().isEmpty && fullName.isNotEmpty) {
        _nameController.text = fullName;
      }
      if (_phoneController.text.trim().isEmpty && phone.isNotEmpty) {
        _phoneController.text = phone;
      }

      final collected = <String>{'None'};
      if (fullName.isNotEmpty) {
        collected.add(fullName);
      }

      final familyRaw = data['familyMembers'];
      if (familyRaw is List) {
        for (final member in familyRaw) {
          if (member is String && member.trim().isNotEmpty) {
            collected.add(member.trim());
          } else if (member is Map) {
            final name = (member['name'] ?? member['fullName'] ?? '').toString().trim();
            if (name.isNotEmpty) {
              collected.add(name);
            }
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _familyMembers = collected.toList();
        if (!_familyMembers.contains(_selectedFamilyMember)) {
          _selectedFamilyMember = 'None';
        }
      });
    } catch (_) {
      // Keep form usable even if profile lookup fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'QUICK ACCESS',
              style: TextStyle(
                color: Color(0xff642d25),
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),
          ),
        if (widget.showHeader) const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _activeView == QuickAccessView.menu
              ? _buildQuickMenu()
              : _buildQuickContent(),
        ),
      ],
    );
  }

  Widget _buildQuickMenu() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.55,
      children: [
        _quickButton('About CCM', Icons.info_outline, QuickAccessView.about),
        _quickButton('Sermons', Icons.ondemand_video_outlined, QuickAccessView.sermons),
        _quickButton('Events', Icons.event_outlined, QuickAccessView.events),
        _quickButton('Prayer Request', Icons.volunteer_activism_outlined, QuickAccessView.prayer),
        _quickButton('Testimonials', Icons.favorite_border, QuickAccessView.testimonials),
        _quickButton('Highlights', Icons.auto_awesome_outlined, QuickAccessView.highlights),
        _quickButton('Gospel', Icons.menu_book_outlined, QuickAccessView.gospel),
        _quickButton('Updates', Icons.notifications_outlined, QuickAccessView.updates),
      ],
    );
  }

  Widget _quickButton(String label, IconData icon, QuickAccessView view) {
    return Material(
      color: ccmWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _activeView = view),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: ccmRed.withValues(alpha: .12),
                child: Icon(icon, color: ccmRed, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ccmInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickContent() {
    return Card(
      key: ValueKey<String>('quick_${_activeView.name}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _activeView = QuickAccessView.menu),
                  icon: const Icon(Icons.arrow_back, color: ccmRed),
                  tooltip: 'Back to Quick Access',
                ),
                Expanded(
                  child: Text(
                    _activeView.title,
                    style: const TextStyle(
                      color: ccmInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildActiveBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBody() {
    switch (_activeView) {
      case QuickAccessView.menu:
        return const SizedBox.shrink();
      case QuickAccessView.about:
        return _buildAbout();
      case QuickAccessView.sermons:
        return _buildSermons();
      case QuickAccessView.events:
        return _buildEvents();
      case QuickAccessView.prayer:
        return _buildPrayer();
      case QuickAccessView.testimonials:
        return _buildTestimonials();
      case QuickAccessView.highlights:
        return _buildHighlights();
      case QuickAccessView.gospel:
        return _buildGospel();
      case QuickAccessView.updates:
        return _buildUpdates();
    }
  }

  Widget _buildAbout() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('about_us')
          .where('enabled', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) => ((a.data()['sortOrder'] ?? 9999) as num)
              .compareTo((b.data()['sortOrder'] ?? 9999) as num));

        if (docs.isNotEmpty) {
          final content = docs.first.data()['details']?.toString() ?? '';
          return Text(
            content.isEmpty ? 'About CCM content will be updated soon.' : content,
            style: const TextStyle(color: ccmMutedInk, height: 1.45),
          );
        }

        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vision',
              style: TextStyle(fontWeight: FontWeight.w800, color: ccmInk),
            ),
            SizedBox(height: 4),
            Text(
              'To help people know Christ, grow in faith, and serve in love.',
              style: TextStyle(color: ccmMutedInk, height: 1.45),
            ),
            SizedBox(height: 10),
            Text(
              'Doctrine',
              style: TextStyle(fontWeight: FontWeight.w800, color: ccmInk),
            ),
            SizedBox(height: 4),
            Text(
              'We believe in the authority of Scripture, salvation through Jesus Christ, prayer, discipleship, and the ministry of the local church.',
              style: TextStyle(color: ccmMutedInk, height: 1.45),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSermons() {
    const sermonLinks = <Map<String, String>>[
      {
        'title': 'Sunday Sermons',
        'url': 'https://www.youtube.com/@yourchannel/playlists',
      },
      {
        'title': 'Mid-Week Messages',
        'url': 'https://www.youtube.com/@yourchannel/videos',
      },
      {
        'title': 'Special Meetings',
        'url': 'https://www.youtube.com/@yourchannel/live',
      },
    ];

    return Column(
      children: sermonLinks
          .map(
            (link) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 14,
                backgroundColor: ccmRed,
                child: Icon(Icons.play_arrow, color: ccmWhite, size: 16),
              ),
              title: Text(
                link['title']!,
                style: const TextStyle(fontWeight: FontWeight.w700, color: ccmInk),
              ),
              subtitle: Text(
                link['url']!,
                style: const TextStyle(fontSize: 12, color: ccmMutedInk),
              ),
              trailing: TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link['url']!));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('YouTube link copied')),
                  );
                },
                child: const Text('Copy Link'),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEvents() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('homepage_events')
          .where('enabled', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: ccmRed));
        }

        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) => ((a.data()['sortOrder'] ?? 9999) as num)
              .compareTo((b.data()['sortOrder'] ?? 9999) as num));

        final visible = docs
            .where((doc) => doc.data()['displayEvents'] != false)
            .toList();

        if (visible.isEmpty) {
          return const Text(
            'No events available.',
            style: TextStyle(color: ccmMutedInk),
          );
        }

        return Column(
          children: visible.map((doc) {
            final data = doc.data();
            final title = data['title']?.toString() ?? 'Event';
            final type = data['eventType']?.toString() ?? '';
            final date = data['eventDate']?.toString() ?? '';
            final time = data['eventTime']?.toString() ?? '';
            final place = data['place']?.toString().trim().isNotEmpty == true
                ? data['place'].toString()
                : (data['location']?.toString() ?? 'TBD');

            final schedule = _eventSchedule(type, date, time);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ccmSandDark.withValues(alpha: .36),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ccmSandDark.withValues(alpha: .7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ccmInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Event Type: ${type.isEmpty ? 'General' : type}'),
                  if (schedule.isNotEmpty) Text(schedule),
                  Text('Place: ${place.isEmpty ? 'TBD' : place}'),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _eventSchedule(String type, String date, String time) {
    final normalizedType = type.toLowerCase();
    final normalizedTime = time.trim();

    if (normalizedType == 'sunday service') {
      return normalizedTime.isEmpty
          ? 'Every Sunday'
          : 'Every Sunday @ $normalizedTime';
    }
    if (normalizedType == 'mid-week service' || normalizedType == 'mid week service') {
      return normalizedTime.isEmpty
          ? 'Every Thursday'
          : 'Every Thursday @ $normalizedTime';
    }
    if (normalizedType == 'fasting prayer') {
      return normalizedTime.isEmpty
          ? 'Every Saturday'
          : 'Every Saturday @ $normalizedTime';
    }

    final pieces = <String>[];
    if (date.trim().isNotEmpty) {
      pieces.add(date.trim());
    }
    if (normalizedTime.isNotEmpty) {
      pieces.add(normalizedTime);
    }
    if (pieces.isEmpty) {
      return '';
    }
    return 'Date & Time: ${pieces.join(' @ ')}';
  }

  Widget _buildPrayer() {
    return Form(
      key: _prayerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select an option',
            style: TextStyle(color: ccmInk, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          _radioOption(
            value: PrayerRequestType.submitPrayer,
            title: 'Submit a Prayer Request',
            subtitle:
                'Please submit your prayer request details, we will uphold you in our prayers.',
          ),
          _radioOption(
            value: PrayerRequestType.requestCallback,
            title: 'Request a Callback',
            subtitle:
                'Please submit your contact details, one of our pastors will reach you shortly.',
          ),
          _radioOption(
            value: PrayerRequestType.joinPrayerCell,
            title: 'Join Prayer Cell',
            subtitle:
                'Please submit your details, so that we can add you to the prayer cell.',
          ),
          const SizedBox(height: 10),
          _input(
            controller: _nameController,
            label: 'Name *',
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Name is required'
                : null,
          ),
          const SizedBox(height: 8),
          _input(
            controller: _phoneController,
            label: 'Phone *',
            keyboardType: TextInputType.phone,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Phone is required'
                : null,
          ),
          const SizedBox(height: 8),
          if (_selectedPrayerType == PrayerRequestType.submitPrayer) ...[
            _input(
              controller: _prayerController,
              label: 'Prayer Request *',
              maxLines: 4,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Prayer Request is required'
                  : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFamilyMember,
              decoration: const InputDecoration(
                labelText: 'Prayer for Family Member (Optional)',
              ),
              items: _familyMembers
                  .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFamilyMember = value ?? 'None';
                });
              },
            ),
          ],
          if (_selectedPrayerType == PrayerRequestType.requestCallback) ...[
            _input(
              controller: _callbackDetailsController,
              label: 'Callback Request Details (Optional)',
              maxLines: 3,
            ),
          ],
          if (_selectedPrayerType == PrayerRequestType.joinPrayerCell) ...[
            _input(
              controller: _joinPlaceController,
              label: 'Place (Optional)',
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingPrayer ? null : _submitPrayer,
              child: _isSubmittingPrayer
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radioOption({
    required PrayerRequestType value,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPrayerType = value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<PrayerRequestType>(
            value: value,
            groupValue: _selectedPrayerType,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPrayerType = val);
              }
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: ccmMutedInk, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _submitPrayer() async {
    if (!_prayerFormKey.currentState!.validate() || _isSubmittingPrayer) {
      return;
    }

    setState(() {
      _isSubmittingPrayer = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    String collection;
    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'memberUid': user?.uid ?? '',
      'memberPhone': _phoneController.text.trim(),
      'requestType': _selectedPrayerType.name,
      'isRead': false,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'source': 'quick_access',
    };

    if (_selectedPrayerType == PrayerRequestType.submitPrayer) {
      collection = 'prayer_requests';
      payload['details'] = _prayerController.text.trim();
      payload['prayerRequest'] = _prayerController.text.trim();
      payload['familyMember'] = _selectedFamilyMember;
    } else if (_selectedPrayerType == PrayerRequestType.requestCallback) {
      collection = 'prayer_callbacks';
      payload['details'] = _callbackDetailsController.text.trim();
      payload['callbackDetails'] = _callbackDetailsController.text.trim();
    } else {
      collection = 'prayer_cell';
      payload['details'] = _joinPlaceController.text.trim();
      payload['place'] = _joinPlaceController.text.trim();
    }

    try {
      await FirebaseFirestore.instance.collection(collection).add(payload);

      if (!mounted) {
        return;
      }

      _prayerController.clear();
      _callbackDetailsController.clear();
      _joinPlaceController.clear();
      setState(() => _selectedFamilyMember = 'None');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prayer request is submitted.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingPrayer = false;
        });
      }
    }
  }

  Widget _buildTestimonials() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('testimonials')
          .where('enabled', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: ccmRed));
        }

        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) => ((a.data()['sortOrder'] ?? 9999) as num)
              .compareTo((b.data()['sortOrder'] ?? 9999) as num));

        if (docs.isEmpty) {
          return const Text('No testimonials yet.', style: TextStyle(color: ccmMutedInk));
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final title = data['title']?.toString() ?? 'Testimonial';
            final text = data['testimony']?.toString().trim().isNotEmpty == true
                ? data['testimony'].toString()
                : (data['details']?.toString() ?? '');

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ccmSandDark.withValues(alpha: .36),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ccmInk)),
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(text, style: const TextStyle(color: ccmMutedInk)),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHighlights() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('highlights')
          .where('enabled', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: ccmRed));
        }

        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) => ((a.data()['sortOrder'] ?? 9999) as num)
              .compareTo((b.data()['sortOrder'] ?? 9999) as num));

        final events = <String>{'All'};
        for (final doc in docs) {
          final name = (doc.data()['eventName'] ?? '').toString().trim();
          if (name.isNotEmpty) {
            events.add(name);
          }
        }

        if (!events.contains(_selectedHighlightEvent)) {
          _selectedHighlightEvent = 'All';
        }

        final filtered = _selectedHighlightEvent == 'All'
            ? docs
            : docs
                .where((doc) =>
                    (doc.data()['eventName'] ?? '').toString().trim() == _selectedHighlightEvent)
                .toList();

        if (filtered.isEmpty) {
          return const Text('No highlights available.', style: TextStyle(color: ccmMutedInk));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedHighlightEvent,
              decoration: const InputDecoration(labelText: 'Filter by Event Name'),
              items: events
                  .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedHighlightEvent = value ?? 'All';
                });
              },
            ),
            const SizedBox(height: 8),
            ...filtered.map((doc) {
            final data = doc.data();
            final title = data['title']?.toString() ?? 'Highlight';
            final basis = data['highlightBasis']?.toString() ?? '';
            final eventName = data['eventName']?.toString() ?? '';
            final details = data['details']?.toString() ?? '';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_awesome, color: ccmRed),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: ccmInk)),
              subtitle: Text(
                [
                  if (basis.isNotEmpty) 'Based on: $basis',
                  if (eventName.isNotEmpty) 'Event: $eventName',
                  if (details.isNotEmpty) details,
                ].join('\n'),
                style: const TextStyle(color: ccmMutedInk, fontSize: 12),
              ),
            );
            }),
          ],
        );
      },
    );
  }

  Widget _buildGospel() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('gospel_tracts')
          .where('enabled', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: ccmRed));
        }

        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) => ((a.data()['sortOrder'] ?? 9999) as num)
              .compareTo((b.data()['sortOrder'] ?? 9999) as num));

        if (docs.isEmpty) {
          return const Text('No gospel tracts uploaded yet.', style: TextStyle(color: ccmMutedInk));
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final title = data['title']?.toString() ?? 'Gospel Tract';
            final fileUrl = data['fileUrl']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.description_outlined, color: ccmRed),
                title: Text(title),
                subtitle: Text(
                  fileUrl.isEmpty ? 'No file URL' : fileUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.link, color: ccmBlue),
                      onPressed: fileUrl.isEmpty
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(this.context);
                              await Clipboard.setData(ClipboardData(text: fileUrl));
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Download link copied')),
                              );
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: ccmRed),
                      onPressed: fileUrl.isEmpty
                          ? null
                          : () => Share.share(fileUrl, subject: title),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUpdates() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: ccmRed));
        }

        final docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) {
          return const Text('No updates yet.', style: TextStyle(color: ccmMutedInk));
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final title = data['title']?.toString() ?? 'Update';
            final body = data['body']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ccmSandDark.withValues(alpha: .36),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: ccmInk)),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(body, style: const TextStyle(color: ccmMutedInk)),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

enum QuickAccessView {
  menu('Quick Access'),
  about('About CCM'),
  sermons('Sermons'),
  events('Events'),
  prayer('Prayer Request'),
  testimonials('Testimonials'),
  highlights('Highlights'),
  gospel('Gospel'),
  updates('Updates');

  final String title;
  const QuickAccessView(this.title);
}

class QuickLinksPage extends StatelessWidget {
  final bool isAdmin;
  final QuickAccessView initialView;

  const QuickLinksPage({
    super.key,
    required this.isAdmin,
    this.initialView = QuickAccessView.menu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Links'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          child: QuickAccessSection(
            isAdmin: isAdmin,
            showHeader: false,
            initialView: initialView,
          ),
        ),
      ),
    );
  }
}

enum PrayerRequestType {
  submitPrayer,
  requestCallback,
  joinPrayerCell,
}
