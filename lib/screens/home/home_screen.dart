import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_colors.dart';
import '../more/updates_screen.dart';
import '../common/coming_soon_screen.dart';
import 'daily_bread_screen.dart';
import 'events_page.dart';
import 'quick_access_section.dart';
import 'service_management_screen.dart';
import 'testimonials_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({super.key, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const String _mockActiveMemberNameKey = 'active_member_name';
  static const String _mockActiveMemberPhoneKey = 'active_member_phone';
  final PageController _heroController = PageController();
  final PageController _eventController = PageController();
  String _localMemberName = '';
  int _heroIndex = 0;
  int _eventIndex = 0;
  int _eventCount = 0;
  Timer? _eventAutoScrollTimer;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ccmSand,
      drawer: _buildQuickLinksDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                _buildHomeTopHeader(),
                const SizedBox(height: 12),
                _buildHeroFromFirestore(),
                const SizedBox(height: 18),
                _buildActionsFromFirestore(),
                const SizedBox(height: 22),
                _sectionHeader(
                  title: 'UPCOMING MAJOR EVENTS',
                  onMore: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventsPage(isAdmin: widget.isAdmin),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildEventsFromFirestore(),
                const SizedBox(height: 22),
                _sectionHeader(
                  title: 'DAILY DEVOTION',
                  onMore: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyBreadScreen(isAdmin: widget.isAdmin),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildDailyDevotionFromFirestore(),
                const SizedBox(height: 22),
                _buildTestimonialsFromFirestore(),
              ],
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Material(
                color: ccmWhite.withValues(alpha: .95),
                elevation: 6,
                shadowColor: ccmInk.withValues(alpha: .25),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.menu, size: 16, color: ccmInk),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTopHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final isPasswordUser =
      user?.providerData.any((p) => p.providerId == 'password') ?? false;
    final shouldUseFirebaseProfile =
      widget.isAdmin || (!isPasswordUser && _localMemberName.isEmpty);

    final userStream = (user == null || !shouldUseFirebaseProfile)
      ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
      : FirebaseFirestore.instance
        .collection(widget.isAdmin ? 'admins' : 'users')
        .doc(user.uid)
        .snapshots();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: ccmWhite.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4D4AA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0x261D2E45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD5AF3B), width: 2.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/ccm_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_circle,
                  size: 44,
                  color: ccmMutedInk,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userStream,
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? <String, dynamic>{};
                final firstName = (data['firstName'] ?? '').toString().trim();
                final lastName = (data['lastName'] ?? '').toString().trim();
                final profileName = [firstName, lastName]
                  .where((part) => part.isNotEmpty)
                  .join(' ')
                  .trim();
                final fallbackEmail = user?.email?.split('@').first.trim() ?? '';
                final fullName = [
                  if (!widget.isAdmin) _localMemberName,
                  if (shouldUseFirebaseProfile) data['fullName'],
                  if (shouldUseFirebaseProfile) data['name'],
                  if (shouldUseFirebaseProfile) profileName,
                  if (widget.isAdmin) user?.displayName,
                  if (widget.isAdmin) _titleCaseName(fallbackEmail),
                  if (shouldUseFirebaseProfile)
                    user?.phoneNumber?.replaceFirst('+91', ''),
                ]
                    .map((value) => value?.toString().trim() ?? '')
                    .firstWhere((value) => value.isNotEmpty, orElse: () => 'MEMBER');
                final displayName = _titleCaseName(fullName);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CCM',
                      style: TextStyle(
                        color: Color(0xFF1D3557),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA07A1C),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  String _titleCaseName(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return 'Member';
    }

    final normalized = cleaned.replaceAll(RegExp(r'[._-]+'), ' ');
    final parts = normalized.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final titleCased = parts
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ')
        .trim();

    return titleCased.isEmpty ? cleaned : titleCased;
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .limit(99)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final visibleCount = docs.where((doc) => doc.data()['enabled'] != false).length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpdatesScreen()),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ccmWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD7D9DF)),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF2F629A),
                  size: 30,
                ),
              ),
            ),
            if (visibleCount > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9254B),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    visibleCount > 9 ? '9+' : '$visibleCount',
                    style: const TextStyle(
                      color: ccmWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickLinksDrawer() {
    return Drawer(
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ccmSandDark.withValues(alpha: .45), ccmSand],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ccmBlue.withValues(alpha: .92), ccmBlue],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Links',
                            style: TextStyle(
                              color: ccmWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Explore Connecting Christ Ministries',
                            style: TextStyle(
                              color: ccmWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: ccmWhite),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                  children: [
                    _drawerQuickLink(
                      'Daily Bread',
                      'Devotions & Bible',
                      'assets/dailybread.png',
                      Icons.menu_book_outlined,
                      null,
                    ),
                    _drawerQuickLink(
                      'About CCM',
                      'Our ministry & mission',
                      'assets/about.png',
                      Icons.info_outline,
                      QuickAccessView.about,
                    ),
                    _drawerQuickLink(
                      'Sermons',
                      'Messages & teachings',
                      'assets/media.png',
                      Icons.tv_outlined,
                      QuickAccessView.sermons,
                    ),
                    _drawerQuickLink(
                      'Events',
                      'Upcoming services',
                      'assets/events.png',
                      Icons.event_note_outlined,
                      QuickAccessView.events,
                    ),
                    _drawerQuickLink(
                      'Prayer Request',
                      'Share a prayer need',
                      'assets/prayerrequest.png',
                      Icons.volunteer_activism_outlined,
                      QuickAccessView.prayer,
                    ),
                    _drawerQuickLink(
                      'Testimonials',
                      'Stories of faith',
                      'assets/testimonials.png',
                      Icons.chat_bubble_outline,
                      QuickAccessView.testimonials,
                    ),
                    _drawerQuickLink(
                      'Highlights',
                      'Ministry moments',
                      'assets/service.png',
                      Icons.auto_awesome_outlined,
                      QuickAccessView.highlights,
                    ),
                    _drawerQuickLink(
                      'Gospel',
                      'Good news of Christ',
                      'assets/about.png',
                      Icons.book_outlined,
                      QuickAccessView.gospel,
                    ),
                    _drawerQuickLink(
                      'Updates',
                      'Latest CCM notices',
                      'assets/service.png',
                      Icons.notifications_none_outlined,
                      QuickAccessView.updates,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerQuickLink(
    String title,
    String subtitle,
    String assetPath,
    IconData fallbackIcon,
    QuickAccessView? view,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ccmWhite.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ccmSandDark.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: ccmSandDark.withValues(alpha: .30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ccmSandDark.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              color: ccmInk,
              colorBlendMode: BlendMode.multiply,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(fallbackIcon, color: ccmRed, size: 24),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: ccmInk,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: ccmMutedInk,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.north_east_rounded, color: ccmRed),
        onTap: () {
          Navigator.pop(context);
          if (view == null) {
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
            MaterialPageRoute(
              builder: (_) => QuickLinksPage(
                isAdmin: widget.isAdmin,
                initialView: view,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadLocalMemberName();
    _eventAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_eventController.hasClients || _eventCount <= 1) return;
      final next = (_eventIndex + 1) % _eventCount;
      _eventController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSpecialServicePopupIfAny();
      _showHomeHighlightPopupIfAny();
    });
  }

  Future<void> _loadLocalMemberName() async {
    if (widget.isAdmin) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = (prefs.getString(_mockActiveMemberNameKey) ?? '').trim();
      if (savedName.isNotEmpty) {
        if (!mounted) return;
        setState(() => _localMemberName = savedName);
        return;
      }

      final activePhone = (prefs.getString(_mockActiveMemberPhoneKey) ?? '').trim();
      if (activePhone.isEmpty) {
        return;
      }

      final profile = prefs.getStringList('mock_profile_$activePhone') ?? const <String>[];
      final firstName = profile.isNotEmpty ? profile[0].trim() : '';
      final lastName = profile.length > 1 ? profile[1].trim() : '';
      final fullName = [firstName, lastName]
          .where((part) => part.isNotEmpty)
          .join(' ')
          .trim();
      if (fullName.isEmpty || !mounted) {
        return;
      }
      setState(() => _localMemberName = fullName);
    } catch (_) {
      // Ignore local cache read failures and keep fallback behavior.
    }
  }

  @override
  void dispose() {
    _eventAutoScrollTimer?.cancel();
    _heroController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  Widget _sectionHeader({required String title, VoidCallback? onMore}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xff642d25),
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),
          ),
          if (onMore != null)
            TextButton.icon(
              onPressed: onMore,
              icon: const Icon(Icons.more_horiz, size: 16, color: ccmRed),
              label: const Text(
                'More',
                style: TextStyle(color: ccmRed, fontWeight: FontWeight.w700),
              ),
            ),
        ],
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
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _shareChip(
                        onTap: () => _shareHeroSlide(slide),
                      ),
                    ),
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
        stream: (widget.isAdmin
          ? FirebaseFirestore.instance.collection('homepage_events')
          : FirebaseFirestore.instance
        .collection('homepage_events')
        .where('enabled', isEqualTo: true))
      .snapshots(),
      builder: (context, snapshot) {
        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aOrder = (aData['sortOrder'] ?? 9999) as num;
            final bOrder = (bData['sortOrder'] ?? 9999) as num;
            if (aOrder != bOrder) return aOrder.compareTo(bOrder);
            return 0;
          });
        final managed = docs
            .where((doc) {
              final data = doc.data();
              if (widget.isAdmin) return true;
              return data['enabled'] != false && data['displayHome'] != false;
            })
            .map((doc) => _Event.fromMap(doc.data()))
            .toList();
        if (managed.isEmpty) {
          _eventCount = 0;
          return const _EmptySectionMessage('No Upcoming Events');
        }
        return _buildEventsWithItems(managed);
      },
    );
  }

  Widget _buildDailyDevotionFromFirestore() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: (widget.isAdmin
          ? FirebaseFirestore.instance.collection('daily_devotions')
          : FirebaseFirestore.instance
        .collection('daily_devotions')
        .where('enabled', isEqualTo: true))
      .snapshots(),
      builder: (context, snapshot) {
        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aOrder = (aData['sortOrder'] ?? 9999) as num;
            final bOrder = (bData['sortOrder'] ?? 9999) as num;
            if (aOrder != bOrder) return aOrder.compareTo(bOrder);
            return 0;
          });
        final visible = docs.where((doc) {
          final data = doc.data();
          if (widget.isAdmin) return true;
          return data['enabled'] != false;
        }).toList();

        if (visible.isEmpty) {
          return const _EmptySectionMessage('Coming Soon');
        }

        final data = visible.first.data();
        final imageUrl = data['imageUrl']?.toString() ?? '';
        final devotionDate = data['devotionDate']?.toString() ?? '';

        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: .72), width: 1.2),
          ),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.73,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const ColoredBox(
                          color: Color(0xff2b2632),
                          child: Center(
                            child: Icon(Icons.auto_stories_outlined, color: ccmWhite, size: 54),
                          ),
                        ),
                      )
                    : const ColoredBox(
                        color: Color(0xff2b2632),
                        child: Center(
                          child: Icon(Icons.auto_stories_outlined, color: ccmWhite, size: 54),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _shareChip(
                  onTap: () => _shareDailyDevotion(imageUrl, devotionDate),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Text(
                  devotionDate.isEmpty ? 'Daily Devotion' : devotionDate,
                  style: const TextStyle(
                    color: ccmWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
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
    _eventCount = events.length;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.73,
          child: PageView.builder(
            controller: _eventController,
            itemCount: events.length,
            onPageChanged: (index) => setState(() => _eventIndex = index),
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: const Color(0xff2b2632),
                  image: event.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(event.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .78),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .26),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _shareChip(
                        onTap: () => _shareEvent(event),
                      ),
                    ),
                    if (event.imageUrl.isEmpty)
                      Positioned(
                        right: -15,
                        bottom: -25,
                        child: Icon(
                          event.icon,
                          size: 170,
                          color: Colors.white.withValues(alpha: .10),
                        ),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: .06),
                              Colors.black.withValues(alpha: .58),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: () => _openEvent(event),
                        ),
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
            events.length,
            (index) => _dot(index == _eventIndex),
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

  Widget _shareChip({required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: .28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(
            Icons.share_outlined,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _shareHeroSlide(_HeroSlide slide) async {
    final text = [
      slide.title,
      if (slide.subtitle.isNotEmpty) slide.subtitle,
      if (slide.imageUrl.isNotEmpty) slide.imageUrl,
    ].join('\n');

    await Share.share(
      text,
      subject: 'CCM Update',
    );
  }

  Future<void> _shareEvent(_Event event) async {
    final text = [
      event.title,
      if (event.subtitle.isNotEmpty) event.subtitle,
      if (event.imageUrl.isNotEmpty) event.imageUrl,
    ].join('\n');

    await Share.share(
      text,
      subject: 'CCM Upcoming Event',
    );
  }

  Future<void> _shareDailyDevotion(String imageUrl, String devotionDate) async {
    final text = [
      'Daily Devotion',
      if (devotionDate.isNotEmpty) devotionDate,
      if (imageUrl.isNotEmpty) imageUrl,
    ].join('\n');

    await Share.share(
      text,
      subject: 'CCM Daily Devotion',
    );
  }

  Future<void> _showSpecialServicePopupIfAny() async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('homepage_events')
          .where('enabled', isEqualTo: true)
          .where('eventType', isEqualTo: 'Special Service')
          .limit(1)
          .get();

      if (!mounted || result.docs.isEmpty) return;

      final data = result.docs.first.data();
      if (data['displayHome'] == false) return;

      final title = data['title']?.toString() ?? 'Special Service';
      final subtitle = data['subtitle']?.toString() ?? data['details']?.toString() ?? '';
      final imageUrl = data['imageUrl']?.toString() ?? '';

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(subtitle),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Ignore popup errors to keep home usable.
    }
  }

  Future<void> _showHomeHighlightPopupIfAny() async {
    try {
      // Show occasionally to avoid repeated interruption on every open.
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now % 3 != 0) {
        return;
      }

      final result = await FirebaseFirestore.instance
          .collection('highlights')
          .where('enabled', isEqualTo: true)
          .where('addToHomePopup', isEqualTo: true)
          .limit(1)
          .get();

      if (!mounted || result.docs.isEmpty) {
        return;
      }

      final data = result.docs.first.data();
      final title = data['title']?.toString() ?? 'Highlight';
      final details = data['details']?.toString() ?? '';
      final eventName = data['eventName']?.toString() ?? '';

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eventName.isNotEmpty)
                Text(
                  eventName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              if (details.isNotEmpty) ...[
                if (eventName.isNotEmpty) const SizedBox(height: 8),
                Text(details),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Keep home screen functional if highlight popup fails.
    }
  }
}

class _EmptySectionMessage extends StatelessWidget {
  final String text;
  const _EmptySectionMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: ccmWhite.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ccmSandDark.withValues(alpha: .6)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ccmMutedInk,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
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
