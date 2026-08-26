import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import 'home/home_screen.dart';
import 'songs/songs_screen.dart';
import 'more/more_screen.dart';

class MainApp extends StatefulWidget {
  final bool isAdmin;
  final bool rememberMe;

  const MainApp({
    super.key,
    required this.isAdmin,
    required this.rememberMe,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(isAdmin: widget.isAdmin),
      SongsScreen(isAdmin: widget.isAdmin),
      MoreScreen(isAdmin: widget.isAdmin),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(
          () => _selectedIndex = index,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note_outlined),
            activeIcon: Icon(Icons.music_note),
            label: 'Songs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
        selectedItemColor: ccmRed,
        unselectedItemColor: Colors.grey,
        backgroundColor: ccmWhite,
        elevation: 8,
      ),
    );
  }
}