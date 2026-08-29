import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/app_colors.dart';
import '../common/coming_soon_screen.dart';
import 'daily_bread_screen.dart';
import 'service_management_screen.dart';
import 'testimonials_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({super.key, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _heroController = PageController();
  final PageController _eventController = PageController(viewportFraction: .88);
  int _heroIndex = 0;
  int _eventIndex = 0;

  final List<_HeroSlide> _slides = const [
    _HeroSlide(
      'CONNECTING CHRIST MINISTRIES',
      'Worship together. Grow together.',
      Icons.groups_rounded,
      ccmBlue,
    ),
    _HeroSlide(
      'A PLACE TO BELONG',
      'Join our family of faith.',
      Icons.favorite_rounded,
      ccmRed,
    ),
    _HeroSlide(
      'LET EVERY HEART SING',
      'Discover songs for every season.',
      Icons.music_note_rounded,
      Color(0xffedd7d4),
    ),
  ];

  final List<_HomeAction> _actions = const [
    _HomeAction('SERVICES @\nCCM', '', Icons.add, ccmRed, 'assets/service.png'),
    _HomeAction(
      'EVENTS',
      'Master calendar',
      Icons.calendar_month_outlined,
      Color(0xffbd7d31),
      'assets/events.png',
    ),
    _HomeAction(
      'LIVE STREAM',
      'Watch live worship',
      Icons.videocam_outlined,
      Color(0xffb94b3d),
      'assets/livestream.png',
      live: true,
    ),
    _HomeAction(
      'DAILY BREAD',
      'Access today\'s verse',
      Icons.spa_outlined,
      Color(0xff709b53),
      'assets/dailybread.png',
    ),
    _HomeAction(
      'PRAYER\nREQUESTS',
      'Share your prayer',
      Icons.favorite_border,
      Color(0xffd66b68),
      'assets/prayerrequest.png',
    ),
    _HomeAction(
      'TESTIMONIALS',
      'Heartwarming stories',
      Icons.favorite_border,
      Color(0xffa96891),
      'assets/testimonials.png',
    ),
    _HomeAction(
      'ABOUT CCM',
      'Our story and mission',
      Icons.info_outline,
      Color(0xffaf7a36),
      'assets/about.png',
    ),
    _HomeAction(
      'MEDIA',
      'Sermons, videos, music',
      Icons.music_note_outlined,
      Color(0xff4b8eae),
      'assets/media.png',
    ),
  ];

  final List<_Event> _events = const [
    _Event(
      'ONEDAY RETREAT\nON SEPTEMBER 14',
      'Join us for a day of prayer and fellowship',
      Icons.menu_book_rounded,
    ),
    _Event(
      'VIDEO SONG RECORDING',
      'Be part of our next worship recording',
      Icons.mic_none_rounded,
    ),
    _Event(
      'SUNDAY WORSHIP',
      'Come and worship with the CCM family',
      Icons.church_outlined,
    ),
  ];

  @override
  void dispose() {
    _heroController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccmSand,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 24),
          children: [
            _buildHeroFromFirestore(),
            const SizedBox(height: 18),
            _buildActionsFromFirestore(),
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'UPCOMING MAJOR EVENTS',
                style: TextStyle(
                  color: Color(0xff642d25),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildEventsFromFirestore(),
            const SizedBox(height: 22),
            _buildTestimonialsFromFirestore(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroFromFirestore() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('homepage_hero_slides')
          .where('enabled', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots(),
      builder: (context, snapshot) {
        final managed =
            snapshot.data?.docs
                .map((doc) => _HeroSlide.fromMap(doc.data()))
                .toList() ??
            [];
        return _buildHeroWithSlides(managed.isEmpty ? _slides : managed);
      },
    );
  }

  Widget _buildHeroWithSlides(List<_HeroSlide> slides) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.73,
          child: PageView.builder(
            controller: _heroController,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => _heroIndex = index),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: slide.color,
                  image: slide.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(slide.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .78),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: slide.color.withValues(alpha: .35),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (slide.imageUrl.isEmpty)
                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/WhatsApp Image 2026-08-25 at 00.38.49.jpeg',
                            width: 132,
                            height: 132,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Positioned(
                      right: -15,
                      bottom: -30,
                      child: Icon(
                        slide.icon,
                        size: 190,
                        color: Colors.white.withValues(alpha: .12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (index) => _dot(index == _heroIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsFromFirestore() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('homepage_action_cards')
          .where('enabled', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots(),
      builder: (context, snapshot) {
        final managed =
            snapshot.data?.docs
                .map((doc) => _HomeAction.fromMap(doc.data()))
                .toList() ??
            [];
        final actions = managed.isEmpty ? _actions : managed;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 84,
          ),
          itemBuilder: (context, index) => _buildAction(actions[index]),
        );
      },
    );
  }

  Widget _buildEventsFromFirestore() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('homepage_events')
          .where('enabled', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots(),
      builder: (context, snapshot) {
        final managed =
            snapshot.data?.docs
                .map((doc) => _Event.fromMap(doc.data()))
                .toList() ??
            [];
        return _buildEventsWithItems(managed.isEmpty ? _events : managed);
      },
    );
  }

  Widget _buildTestimonialsFromFirestore() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('testimonials').snapshots(),
      builder: (context, snapshot) {
        final testimonials =
            [...?snapshot.data?.docs]
                .where((doc) => doc.data()['enabled'] != false)
                .toList()
              ..sort(
                (a, b) => ((a.data()['sortOrder'] ?? 0) as num).compareTo(
                  (b.data()['sortOrder'] ?? 0) as num,
                ),
              );
        if (testimonials.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'TESTIMONIALS',
                style: TextStyle(
                  color: Color(0xff642d25),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...testimonials.map((doc) => _buildTestimonialCard(doc.data())),
          ],
        );
      },
    );
  }

  Widget _buildTestimonialCard(Map<String, dynamic> data) {
    final photo =
        data['photoUrl']?.toString() ?? data['imageUrl']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 5,
      shadowColor: const Color(0x55493828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.white.withValues(alpha: .75)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: ccmRed.withValues(alpha: .12),
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? const Icon(Icons.person_outline, color: ccmRed)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title']?.toString() ?? 'Testimony',
                    style: const TextStyle(
                      color: ccmInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${data['name'] ?? ''} • ${data['category'] ?? ''}',
                    style: const TextStyle(color: ccmMutedInk, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['testimony']?.toString() ??
                        data['details']?.toString() ??
                        data['subtitle']?.toString() ??
                        '',
                    style: const TextStyle(
                      color: ccmMutedInk,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    margin: const EdgeInsets.symmetric(horizontal: 3),
    width: active ? 9 : 7,
    height: active ? 9 : 7,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? Colors.white : Colors.white.withValues(alpha: .55),
      border: Border.all(color: const Color(0xffc9ad8f)),
    ),
  );

  Widget _buildAction(_HomeAction action) {
    const cardRadius = 56.0;
    return Material(
      color: action.color.withValues(alpha: .10),
      elevation: 6,
      shadowColor: action.color.withValues(alpha: .38),
      borderRadius: BorderRadius.circular(cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: () => _openAction(action),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: .72),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: action.color.withValues(alpha: .24),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: .56),
                blurRadius: 5,
                spreadRadius: -2,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              action.assetPath.startsWith('http')
                  ? Image.network(
                      action.assetPath,
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(action.icon, size: 42, color: action.color),
                    )
                  : Image.asset(
                      action.assetPath,
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.multiply,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(action.icon, size: 42, color: action.color),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff241b16),
                  ),
                ),
              ),
              if (action.live)
                const CircleAvatar(
                  radius: 5,
                  backgroundColor: Color(0xffff5b4d),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsWithItems(List<_Event> events) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _eventController,
            itemCount: events.length,
            onPageChanged: (index) => setState(() => _eventIndex = index),
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(right: 10),
                clipBehavior: Clip.antiAlias,
                elevation: 6,
                shadowColor: const Color(0x66493828),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: .70),
                    width: 1.2,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff493728), Color(0xff171311)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  foregroundDecoration: event.imageUrl.isNotEmpty
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          image: DecorationImage(
                            image: NetworkImage(event.imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: .42),
                              BlendMode.darken,
                            ),
                          ),
                        )
                      : null,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 18,
                        top: 15,
                        child: Icon(
                          event.icon,
                          size: 112,
                          color: Colors.white.withValues(alpha: .14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.subtitle,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _openEvent(event),
                                  child: const Text(
                                    'Details',
                                    style: TextStyle(color: Color(0xffffd7a2)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            events.length,
            (index) => Container(
              width: index == _eventIndex ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == _eventIndex ? ccmRed : Colors.black26,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openAction(_HomeAction action) {
    final title = action.title.replaceAll('\n', ' ');
    if (action.actionType == 'testimonials' || title == 'TESTIMONIALS') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TestimonialsScreen()),
      );
      return;
    }
    final actionType = action.actionType;
    if (actionType == 'services' || title == 'SERVICES @ CCM') {
      if (widget.isAdmin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServiceManagementScreen()),
        );
      } else {
        _showMessage('Services are available every Sunday.');
      }
      return;
    }
    if (actionType == 'dailyBread' || title == 'DAILY BREAD') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyBreadScreen(isAdmin: widget.isAdmin),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComingSoonScreen(title: title)),
    );
  }

  void _openEvent(_Event event) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ComingSoonScreen(title: event.title.replaceAll('\n', ' ')),
    ),
  );

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _HeroSlide {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String imageUrl;
  const _HeroSlide(
    this.title,
    this.subtitle,
    this.icon,
    this.color, {
    this.imageUrl = '',
  });

  factory _HeroSlide.fromMap(Map<String, dynamic> data) => _HeroSlide(
    data['title']?.toString() ?? 'Connecting Christ Ministries',
    data['subtitle']?.toString() ?? '',
    Icons.auto_awesome,
    _parseColor(data['colorHex']?.toString()),
    imageUrl: data['imageUrl']?.toString() ?? '',
  );
}

class _HomeAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String assetPath;
  final String actionType;
  final bool live;
  const _HomeAction(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.assetPath, {
    this.live = false,
    this.actionType = 'comingSoon',
  });

  factory _HomeAction.fromMap(Map<String, dynamic> data) => _HomeAction(
    data['title']?.toString() ?? 'Action',
    data['subtitle']?.toString() ?? '',
    Icons.touch_app_outlined,
    _parseColor(data['colorHex']?.toString()),
    data['imageUrl']?.toString() ?? '',
    live: data['live'] == true,
    actionType: data['actionType']?.toString() ?? 'comingSoon',
  );
}

class _Event {
  final String title;
  final String subtitle;
  final IconData icon;
  final String imageUrl;
  const _Event(this.title, this.subtitle, this.icon, {this.imageUrl = ''});

  factory _Event.fromMap(Map<String, dynamic> data) => _Event(
    data['title']?.toString() ?? 'Upcoming event',
    data['subtitle']?.toString() ?? '',
    Icons.event_outlined,
    imageUrl: data['imageUrl']?.toString() ?? '',
  );
}

Color _parseColor(String? value) {
  if (value == null) return ccmRed;
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null
      ? ccmRed
      : Color(hex.length == 6 ? 0xff000000 | parsed : parsed);
}
