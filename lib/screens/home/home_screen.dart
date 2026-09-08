import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_colors.dart';
import '../auth/admin_login_screen.dart';
import '../common/coming_soon_screen.dart';
import '../more/updates_screen.dart';
import 'about_ccm_sections_screen.dart';
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

  int _heroIndex = 0;
  int _eventIndex = 0;
  int _eventCount = 0;
  Timer? _eventAutoScrollTimer;
  Timer? _heroAutoScrollTimer;

  final List<_HomeAction> _actions = const [
    _HomeAction('Services', '', Icons.add, ccmRed, 'assets/service.png', actionType: 'services'),
    _HomeAction('EVENTS', 'Master calendar', Icons.calendar_month_outlined, Color(0xffbd7d31), 'assets/events.png'),
    _HomeAction('LIVE STREAM', 'Watch live worship', Icons.videocam_outlined, Color(0xffb94b3d), 'assets/livestream.png', live: true),
    _HomeAction('DAILY BREAD', 'Access today\'s verse', Icons.spa_outlined, Color(0xff709b53), 'assets/dailybread.png'),
    _HomeAction('PRAYER\nREQUESTS', 'Share your prayer', Icons.favorite_border, Color(0xffd66b68), 'assets/prayerrequest.png'),
    _HomeAction('TESTIMONIALS', 'Heartwarming stories', Icons.favorite_border, Color(0xffa96891), 'assets/testimonials.png'),
    _HomeAction('ABOUT CCM', 'Our story and mission', Icons.info_outline, Color(0xffaf7a36), 'assets/about.png'),
    _HomeAction('MEDIA', 'Sermons, videos, music', Icons.music_note_outlined, Color(0xff4b8eae), 'assets/media.png'),
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalMemberName();

    _eventAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_eventController.hasClients || _eventCount <= 1) return;
      final next = (_eventIndex + 1) % _eventCount;
      _eventController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSpecialServicePopupIfAny();
      _showHomeHighlightPopupIfAny();
    });
  }

  @override
  void dispose() {
    _eventAutoScrollTimer?.cancel();
    _heroAutoScrollTimer?.cancel();
    _heroController.dispose();
    _eventController.dispose();
    super.dispose();
  }

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
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: const Text(
                'Welcome to CCM Family!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1D3557),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
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

  Widget _sectionHeader({required String title, VoidCallback? onMore}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    if (_heroAutoScrollTimer == null && _heroController.hasClients) {
      _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_heroController.hasClients || _heroIndex < 0) return;
      });
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('homepage_hero_slides').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildHeroLoadingSkeleton();
        }
        if (snapshot.hasError) {
          debugPrint('Homepage hero slides error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final docs = [...?snapshot.data?.docs];
        final sortedDocs = docs
          ..sort((a, b) {
            final aOrder = (a.data()['sortOrder'] ?? 9999) as num;
            final bOrder = (b.data()['sortOrder'] ?? 9999) as num;
            return aOrder.compareTo(bOrder);
          });

        final managed = sortedDocs
            .where((doc) => doc.data()['enabled'] != false)
            .map((doc) => _HeroSlide.fromMap(doc.data()))
            .toList();

        if (managed.isEmpty) {
          return _buildHeroWithSlides([
            const _HeroSlide(
              'CONNECTING CHRIST MINISTRIES',
              'Worship together. Grow together.',
              Icons.groups_rounded,
              ccmBlue,
            ),
          ]);
        }

        for (final slide in managed) {
          if (slide.imageUrl.isNotEmpty) {
            debugPrint('HOME_HERO_IMAGE_URL: ${slide.imageUrl}');
          }
        }

        if (managed.length > 1 && _heroAutoScrollTimer == null) {
          _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
            if (!mounted || !_heroController.hasClients || managed.length <= 1) return;
            final next = (_heroIndex + 1) % managed.length;
            _heroController.animateToPage(
              next,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        }

        return _buildHeroWithSlides(managed);
      },
    );
  }

  Widget _buildHeroWithSlides(List<_HeroSlide> slides) {
    if (_heroAutoScrollTimer == null && slides.length > 1) {
      _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_heroController.hasClients || slides.length <= 1) return;
        final next = (_heroIndex + 1) % slides.length;
        _heroController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }

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
                    if (slide.imageUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: _BufferedNetworkImage(
                            url: slide.imageUrl,
                            fit: BoxFit.cover,
                            placeholderColor: slide.color.withValues(alpha: 0.35),
                            icon: slide.icon,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _shareChip(onTap: () => _shareHeroSlide(slide)),
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
        final managed = snapshot.data?.docs
                .map((doc) => _HomeAction.fromMap(doc.data()))
                .toList() ??
            <_HomeAction>[];
        final actions = managed.isEmpty ? _actions : managed;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 122,
          ),
          itemBuilder: (context, index) => _buildAction(actions[index]),
        );
      },
    );
  }

  Widget _buildAction(_HomeAction action) {
    const cardRadius = 22.0;
    const circleSize = 92.0;
    final label = action.title.replaceAll('\n', ' ').trim().toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: () => _openAction(action),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Compact glass card. The icon badge intentionally overlaps
            // the top edge, matching the supplied reference design.
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 42, 10, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardRadius),
                      color: Colors.white.withValues(alpha: .72),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          action.color.withValues(alpha: .25),
                          Colors.white.withValues(alpha: .58),
                          action.color.withValues(alpha: .18),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .95),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: action.color.withValues(alpha: .14),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: .65),
                          blurRadius: 7,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.02,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .15,
                                color: Color(0xff1D2D3F),
                              ),
                            ),
                          ),
                          if (action.live) ...[
                            const SizedBox(width: 5),
                            const CircleAvatar(
                              radius: 4,
                              backgroundColor: Color(0xffff5b4d),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Larger circular badge, kept outside the card boundary.
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.25, -0.35),
                  radius: .9,
                  colors: [
                    Colors.white.withValues(alpha: .72),
                    action.color.withValues(alpha: .22),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .96),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: .72),
                    blurRadius: 9,
                    offset: const Offset(-2, -3),
                  ),
                  BoxShadow(
                    color: action.color.withValues(alpha: .20),
                    blurRadius: 11,
                    offset: const Offset(3, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Center(
                  child: _buildActionImage(action),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionImage(_HomeAction action) {
    final image = action.assetPath.startsWith('http')
        ? Image.network(
            action.assetPath,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              action.icon,
              size: 50,
              color: const Color(0xff9a3d18),
            ),
          )
        : Image.asset(
            action.assetPath,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              action.icon,
              size: 50,
              color: const Color(0xff9a3d18),
            ),
          );

    return image;
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
            final aOrder = (a.data()['sortOrder'] ?? 9999) as num;
            final bOrder = (b.data()['sortOrder'] ?? 9999) as num;
            return aOrder.compareTo(bOrder);
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
                    if (event.imageUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: _BufferedNetworkImage(
                            url: event.imageUrl,
                            fit: BoxFit.cover,
                            placeholderColor: const Color(0xff2b2632),
                            icon: event.icon,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _shareChip(onTap: () => _shareEvent(event)),
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
            final aOrder = (a.data()['sortOrder'] ?? 9999) as num;
            final bOrder = (b.data()['sortOrder'] ?? 9999) as num;
            return aOrder.compareTo(bOrder);
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
                child: _shareChip(onTap: () => _shareDailyDevotion(imageUrl, devotionDate)),
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
        final testimonials = [...?snapshot.data?.docs]
            .where((doc) => doc.data()['enabled'] != false)
            .toList()
          ..sort((a, b) {
            final aOrder = (a.data()['sortOrder'] ?? 0) as num;
            final bOrder = (b.data()['sortOrder'] ?? 0) as num;
            return aOrder.compareTo(bOrder);
          });

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
    final photo = data['photoUrl']?.toString() ?? data['imageUrl']?.toString() ?? '';
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
              child: photo.isEmpty ? const Icon(Icons.person_outline, color: ccmRed) : null,
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
                    data['testimony']?.toString() ?? data['details']?.toString() ?? data['subtitle']?.toString() ?? '',
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

  void _openAction(_HomeAction action) {
    final title = action.title.replaceAll('\n', ' ');
    if (action.actionType == 'testimonials' || title == 'TESTIMONIALS') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TestimonialsScreen()),
      );
      return;
    }

    if (action.actionType == 'services' || title == 'Services') {
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

    if (action.actionType == 'aboutCcm' || title == 'ABOUT CCM' || title == 'About CCM') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AboutCcmSectionsScreen()),
      );
      return;
    }

    if (action.actionType == 'dailyBread' || title == 'DAILY BREAD') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DailyBreadScreen(isAdmin: widget.isAdmin)),
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
          builder: (_) => ComingSoonScreen(title: event.title.replaceAll('\n', ' ')),
        ),
      );

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

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

  Widget _shareChip({required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: .28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(Icons.share_outlined, size: 18, color: Colors.white),
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

    await SharePlus.instance.share(ShareParams(text: text, subject: 'CCM Update'));
  }

  Future<void> _shareEvent(_Event event) async {
    final text = [
      event.title,
      if (event.subtitle.isNotEmpty) event.subtitle,
      if (event.imageUrl.isNotEmpty) event.imageUrl,
    ].join('\n');

    await SharePlus.instance.share(ShareParams(text: text, subject: 'CCM Upcoming Event'));
  }

  Future<void> _shareDailyDevotion(String imageUrl, String devotionDate) async {
    final text = [
      'Daily Devotion',
      if (devotionDate.isNotEmpty) devotionDate,
      if (imageUrl.isNotEmpty) imageUrl,
    ].join('\n');

    await SharePlus.instance.share(ShareParams(text: text, subject: 'CCM Daily Devotion'));
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

      // Do not block the dialog on image preloading here. Awaiting precacheImage
      // delays the popup and can leave the initial dialog blank until the network
      // image eventually resolves.
      if (imageUrl.isNotEmpty && mounted) {
        try {
          unawaited(precacheImage(NetworkImage(imageUrl), context));
        } catch (_) {
          // Let the existing image widget handle any image loading failure.
        }
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: imageUrl.isEmpty && subtitle.isEmpty
              ? const SizedBox(
                  width: 300,
                  child: _PopupSkeleton(),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _PopupImageLoader(
                          url: imageUrl,
                          height: 140,
                          width: double.infinity,
                        ),
                      )
                    else
                      const SizedBox(height: 140, child: _PopupSkeleton()),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
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
      // Ignore popup issues.
    }
  }

  Future<void> _showHomeHighlightPopupIfAny() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now % 3 != 0) return;

      final result = await FirebaseFirestore.instance
          .collection('highlights')
          .where('enabled', isEqualTo: true)
          .where('addToHomePopup', isEqualTo: true)
          .limit(1)
          .get();

      if (!mounted || result.docs.isEmpty) return;

      final data = result.docs.first.data();
      final title = data['title']?.toString() ?? 'Highlight';
      final details = data['details']?.toString() ?? '';
      final eventName = data['eventName']?.toString() ?? '';

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: details.isEmpty && eventName.isEmpty
              ? const SizedBox(
                  width: 300,
                  child: _PopupSkeleton(),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eventName.isNotEmpty)
                      Text(
                        eventName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    if (details.isNotEmpty) ...[
                      if (eventName.isNotEmpty) const SizedBox(height: 8),
                      Text(
                        details,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
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
      // Keep home screen functional.
    }
  }

  Future<void> _loadLocalMemberName() async {
    if (widget.isAdmin) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = (prefs.getString(_mockActiveMemberNameKey) ?? '').trim();
      if (savedName.isNotEmpty) {
        return;
      }

      final activePhone = (prefs.getString(_mockActiveMemberPhoneKey) ?? '').trim();
      if (activePhone.isEmpty) return;

      final profile = prefs.getStringList('mock_profile_$activePhone') ?? const <String>[];
      final firstName = profile.isNotEmpty ? profile[0].trim() : '';
      final lastName = profile.length > 1 ? profile[1].trim() : '';
      final fullName = [firstName, lastName].where((part) => part.isNotEmpty).join(' ').trim();
      if (fullName.isEmpty || !mounted) return;
    } catch (_) {
      // Ignore local cache read failures and keep fallback behavior.
    }
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
                    _drawerQuickLink(
                      'CCM Admin',
                      'Admin access',
                      'assets/service.png',
                      Icons.admin_panel_settings_outlined,
                      null,
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
          if (title == 'CCM Admin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            );
            return;
          }
          if (view == null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DailyBreadScreen(isAdmin: widget.isAdmin)),
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

  Widget _buildHeroLoadingSkeleton() {
    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: Colors.white.withValues(alpha: 0.4),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BufferedNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Color placeholderColor;
  final IconData icon;

  const _BufferedNetworkImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholderColor = const Color(0xff2b2632),
    this.icon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(
        color: placeholderColor,
        child: Center(
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.65), size: 32),
        ),
      );
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: placeholderColor,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: placeholderColor,
        child: Center(
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 28),
        ),
      ),
    );
  }
}

class _PopupImageLoader extends StatelessWidget {
  final String url;
  final double width;
  final double height;

  const _PopupImageLoader({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.18),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF2EDE7),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white70, size: 28),
        ),
      ),
    );
  }
}

class _PopupSkeleton extends StatelessWidget {
  const _PopupSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SkeletonBox(),
        SizedBox(height: 12),
        _SkeletonLine(width: 180),
        SizedBox(height: 8),
        _SkeletonLine(width: 220),
        SizedBox(height: 6),
        _SkeletonLine(width: 160),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.18),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  const _SkeletonLine({this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.08),
      ),
    );
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
        imageUrl: (data['imageUrl'] ??
                data['photoUrl'] ??
                data['downloadUrl'] ??
                data['url'] ??
                '')
            .toString(),
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
