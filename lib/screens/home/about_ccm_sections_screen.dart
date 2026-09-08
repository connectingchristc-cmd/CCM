import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class AboutCcmSectionsScreen extends StatelessWidget {
  const AboutCcmSectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccmSand,
      appBar: AppBar(
        title: const Text('About CCM', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: ccmWhite,
        foregroundColor: ccmInk,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'CONNECTING CHRIST MINISTRIES',
                style: TextStyle(
                  color: Color(0xff642d25),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Explore our ministry, leadership and how you can join us.',
                style: TextStyle(color: ccmMutedInk, fontSize: 13, height: 1.35),
              ),
              SizedBox(height: 18),
              SizedBox(
                height: 132,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SectionCard(
                        title: 'About Us',
                        subtitle: 'Our story & mission',
                        icon: Icons.church_outlined,
                        tint: Color(0xffdce7f0),
                        section: AboutCcmSection.aboutUs,
                      ),
                      SizedBox(width: 12),
                      _SectionCard(
                        title: 'Our Leadership',
                        subtitle: 'Pastoral team',
                        icon: Icons.groups_2_outlined,
                        tint: Color(0xffeadcc9),
                        section: AboutCcmSection.leadership,
                      ),
                      SizedBox(width: 12),
                      _SectionCard(
                        title: 'Join Us',
                        subtitle: 'Come as you are',
                        icon: Icons.volunteer_activism_outlined,
                        tint: Color(0xffe8d8df),
                        section: AboutCcmSection.joinUs,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AboutCcmSection { aboutUs, leadership, joinUs }

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final AboutCcmSection section;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AboutCcmDetailScreen(section: section),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .95),
                  tint.withValues(alpha: .72),
                ],
              ),
              border: Border.all(color: Colors.white, width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: .40),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: .96),
                        tint.withValues(alpha: .68),
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Icon(icon, color: const Color(0xff9a3d18), size: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff1d2d3f),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ccmMutedInk,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class AboutCcmDetailScreen extends StatelessWidget {
  final AboutCcmSection section;

  const AboutCcmDetailScreen({super.key, required this.section});

  String get pageTitle {
    switch (section) {
      case AboutCcmSection.aboutUs:
        return 'About Us';
      case AboutCcmSection.leadership:
        return 'Our Leadership';
      case AboutCcmSection.joinUs:
        return 'Join Us';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccmSand,
      appBar: AppBar(
        title: Text(pageTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: ccmWhite,
        foregroundColor: ccmInk,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        child: switch (section) {
          AboutCcmSection.aboutUs => const _AboutUsContent(),
          AboutCcmSection.leadership => const _LeadershipContent(),
          AboutCcmSection.joinUs => const _JoinUsContent(),
        },
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final String label;
  final double height;

  const _PlaceholderImage({required this.label, this.height = 210});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .95),
            ccmSandDark.withValues(alpha: .58),
          ],
        ),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: ccmSandDark.withValues(alpha: .24),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 52, color: ccmMutedInk.withValues(alpha: .72)),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ccmMutedInk, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Image placeholder',
            style: TextStyle(color: ccmMutedInk, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Widget child;

  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ccmWhite.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: ccmSandDark.withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0xff1d3557),
          fontSize: 21,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      );
}

class _BodyText extends StatelessWidget {
  final String text;
  const _BodyText(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: ccmMutedInk,
          fontSize: 14,
          height: 1.48,
        ),
      );
}

class _AboutUsContent extends StatelessWidget {
  const _AboutUsContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlaceholderImage(
          label: 'Church Image / Logo Placeholder',
          height: 220,
        ),
        SizedBox(height: 18),
        _Heading('About Us'),
        SizedBox(height: 5),
        Text(
          'Connecting Christ Ministries',
          style: TextStyle(
            color: Color(0xff642d25),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        _BodyText(
          'Connecting People to Christ • Restoring Broken Hearts through Worship • '
          'Transforming Lives through the Word • Raising Christ-Centered Disciples • '
          'Multiplying God’s Kingdom',
        ),
        _ContentCard(
          child: _BodyText(
            'Welcome to Connecting Christ Ministries, a Christ-centered family where every person is '
            'valued, loved, and encouraged to Connect with CHRIST and experience the transforming power '
            'of Jesus Christ.\n\n'
            'Founded in 2023, our ministry was established with a simple yet powerful mission is to Connect '
            'people to Christ and Changing lives through Word & Worship to Multiply God’s Kingdom.\n\n'
            '"We connect people to Jesus Christ through worship, where His love restores the broken, His Word '
            'transforms lives, and trusting in His unfailing promises.\n'
            'Committed to sharing the Good News, we inspire individuals, families, and communities to grow as '
            'faithful disciples, reflect Christ’s love, and multiply His Kingdom for generations to come."\n\n'
            'We are more than a church. We are a family of Christ, a home for the seeking, a refuge for the '
            'weary, and a place where broken hearts find healing and hope in God’s unfailing love. No matter '
            'your background, your struggles, or where you are on life’s journey, God is waiting for you to '
            'connect with Him. His grace is ready to meet you, restore your heart, renew your spirit, and '
            'anchor your soul in His eternal love.\n\n'
            'In a world filled with uncertainty, pain, and brokenness, His love reaches beyond every failure, '
            'every disappointment, and every wound. We exist to connect people to Jesus Christ, No matter how '
            'deep the pain or how heavy the burden, there is hope in Jesus Christ.\n\n'
            'Through worship, prayer, biblical preaching, and fellowship, we help people encounter God’s love, '
            'find healing for their hearts, and discover lasting peace in Him.\n\n'
            'Inspired by the words of Jesus in John 15:5, "I am the vine; you are the branches," we are '
            'committed to helping people to connect with CHRIST to build a genuine and lasting relationship '
            'with Him. As hearts connect with Christ, we believe healing replaces hurt, hope overcomes despair, '
            'and lives are transformed by God’s amazing grace.\n\n'
            'Serving through our branches in Konnembattu and Samanthamallam, we are committed to being a beacon '
            'of hope and a testimony of God’s transforming power.',
          ),
        ),
      ],
    );
  }
}

class _JoinUsContent extends StatelessWidget {
  const _JoinUsContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlaceholderImage(
          label: 'Church Image / Logo Placeholder',
          height: 220,
        ),
        SizedBox(height: 18),
        _Heading('Join Us'),
        _ContentCard(
          child: _BodyText(
            'Are you weary and burdened, whether you are seeking hope, searching for answers, recovering '
            'from life’s struggles, or longing for a closer walk with God, there is a place for you here.\n\n'
            'Here at CCM, hearts are restored, souls are anchored, and lives are changed through the saving '
            'power of Jesus Christ. Come and experience God’s love, discover His purpose for your life, and '
            'be part of a community where hearts are restored, lives are transformed, and souls are anchored '
            'in Christ. "Come to Me, all who are weary and burdened, and I will give you rest." Matthew 11:28.',
          ),
        ),
      ],
    );
  }
}

class _LeadershipContent extends StatelessWidget {
  const _LeadershipContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading('Our Leadership'),
        SizedBox(height: 12),
        _PastorCard(
          imageLabel: 'Pastor Daniel Damodar Image Placeholder',
          name: 'Pastor Daniel Damodar',
          role: 'Founder & Senior Pastor (Bachelor of Divinity, 2023)',
          content:
              'Inspired by God’s divine calling and the words of Isaiah 6:8, “Here am I. Send me!”, Pastor '
              'Daniel Damodar surrendered his life to the Lord’s purpose and founded Connecting Christ '
              'Ministries in 2023.\n\n'
              'With a deep burden for the lost, the brokenhearted, and those searching for hope, his God-given '
              'vision is to connect people to Jesus Christ, restore broken hearts through worship, transform '
              'lives through God’s Word, raise Christ-centered disciples, and multiply God’s Kingdom for '
              'generations to come.\n\n'
              'Guided by Christ’s command to “make disciples of all nations” (Matthew 28:19) and God’s promise '
              'to “bind up the brokenhearted” (Isaiah 61:1), Pastor Daniel is passionate about serving God and '
              'faithfully answering His calling. Through prayer, worship, biblical teaching, and compassionate '
              'care, he is passionate about leading people into a life-changing relationship with Christ and '
              'helping them discover God’s love, healing, purpose, and hope.',
          message:
              '“No matter how difficult your journey has been, how deeply your heart has been wounded, or how '
              'far you feel you have wandered, Jesus Christ is still calling you. His love has never left you, '
              'His grace has not forgotten you, and His purpose for your life remains.\n\n'
              'At Connecting Christ Ministries, our deepest desire is not simply to welcome you into a church, '
              'but to lead you into a life-changing relationship with Jesus Christ. My prayer is that you will '
              'encounter His presence, hear His voice, experience His healing, and discover the beautiful '
              'purpose for which He created you.\n\n'
              'When Christ enters a heart, brokenness becomes a testimony, pain gives birth to purpose, fear '
              'gives way to faith, and darkness is overcome by His light. No heart is too broken for Him to '
              'restore, no burden is too heavy for Him to carry, and no life is beyond the transforming power '
              'of His grace.\n\n'
              'God is still searching for willing hearts that will carry His love to the hurting, proclaim His '
              'Word to the lost, and shine His light in a broken world. Let us answer His call together with '
              'faith and surrender: ‘Here am I. Send me!’\n\n'
              'Come as you are. Jesus is calling you closer, and His love can turn your pain into purpose, '
              'your fear into faith, and your life into a testimony of His grace.\n\n'
              'Come as you are. Jesus is waiting to restore your heart, transform your life, raise you as His '
              'faithful disciple, and use you to multiply His Kingdom for generations to come.”',
        ),
        SizedBox(height: 14),
        _PastorCard(
          imageLabel: 'Pastor Sudhakar Image Placeholder',
          name: 'Pastor Sudhakar',
          role: 'Co-Pastor',
          content:
              'Serving alongside Pastor Daniel is a dedicated pastoral team committed to shepherding God’s '
              'people with love, prayer, and spiritual guidance:',
        ),
        SizedBox(height: 14),
        _PastorCard(
          imageLabel: 'Pastor James Image Placeholder',
          name: 'Pastor James',
          role: 'Co-Pastor',
          content:
              'Serving alongside Pastor Daniel is a dedicated pastoral team committed to shepherding God’s '
              'people with love, prayer, and spiritual guidance:',
        ),
      ],
    );
  }
}

class _PastorCard extends StatelessWidget {
  final String imageLabel;
  final String name;
  final String role;
  final String content;
  final String? message;

  const _PastorCard({
    required this.imageLabel,
    required this.name,
    required this.role,
    required this.content,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlaceholderImage(label: imageLabel, height: 190),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xff1d3557),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            role,
            style: const TextStyle(
              color: Color(0xffb17a32),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _BodyText(content),
          if (message != null) ...[
            const SizedBox(height: 18),
            const Text(
              'A Message from Pastor Daniel Damodar',
              style: TextStyle(
                color: Color(0xff1d3557),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xfff1f4f7),
                border: Border(
                  left: BorderSide(color: Color(0xffc9a45c), width: 3),
                ),
              ),
              child: _BodyText(message!),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pastor Daniel Damodar\nFounder & Senior Pastor\nConnecting Christ Ministries',
              style: TextStyle(
                color: ccmMutedInk,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
