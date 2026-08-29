// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'firebase_options.dart';

// import 'dart:async';
// import 'dart:convert';

// String? firebaseInitError;

// // Handle background notification messages
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
// }

// class AppFeatureStore extends ChangeNotifier {
//   static const _favoritesKey = 'favorite_song_ids';
//   static const _cachedSongsKey = 'cached_songs';
//   static const _setlistsKey = 'worship_setlists';

//   SharedPreferences? _preferences;
//   final List<String> favoriteSongIds = <String>[];
//   final Map<String, Map<String, dynamic>> cachedSongs =
//       <String, Map<String, dynamic>>{};
//   List<Map<String, dynamic>> setlists = <Map<String, dynamic>>[];

//   Future<void> load() async {
//     try {
//       _preferences = await SharedPreferences.getInstance();
//       final savedFavs = _preferences?.getStringList(_favoritesKey) ?? <String>[];
//       favoriteSongIds.clear();
//       favoriteSongIds.addAll(savedFavs);

//       final cached = _preferences?.getString(_cachedSongsKey);
//       if (cached != null) {
//         final decoded = jsonDecode(cached) as List<dynamic>;
//         for (final item in decoded) {
//           final song = Map<String, dynamic>.from(item as Map);
//           final id = song['id']?.toString();
//           if (id != null) cachedSongs[id] = song;
//         }
//       }
//       final storedSetlists = _preferences?.getString(_setlistsKey);
//       if (storedSetlists != null) {
//         setlists = (jsonDecode(storedSetlists) as List<dynamic>)
//             .map((item) => Map<String, dynamic>.from(item as Map))
//             .toList();
//       }
//       notifyListeners();
//     } catch (error) {
//       debugPrint('Local feature storage unavailable: $error');
//     }
//   }

//   bool isFavorite(String songId) => favoriteSongIds.contains(songId);

//   Future<void> toggleFavorite(String songId) async {
//     if (favoriteSongIds.contains(songId)) {
//       favoriteSongIds.remove(songId);
//     } else {
//       favoriteSongIds.add(songId);
//     }
//     await _preferences?.setStringList(_favoritesKey, favoriteSongIds);
//     notifyListeners();
//   }

//   Future<void> reorderFavorites(int oldIndex, int newIndex) async {
//     if (newIndex > oldIndex) newIndex -= 1;
//     final item = favoriteSongIds.removeAt(oldIndex);
//     favoriteSongIds.insert(newIndex, item);
//     await _preferences?.setStringList(_favoritesKey, favoriteSongIds);
//     notifyListeners();
//   }

//   Future<void> cacheSongs(Iterable<QueryDocumentSnapshot> docs) async {
//     for (final doc in docs) {
//       cachedSongs[doc.id] = <String, dynamic>{
//         'id': doc.id,
//         ...(doc.data() as Map<String, dynamic>),
//       };
//     }
//     await _preferences?.setString(
//       _cachedSongsKey,
//       jsonEncode(cachedSongs.values.toList()),
//     );
//   }

//   Future<void> saveSetlists() async {
//     await _preferences?.setString(_setlistsKey, jsonEncode(setlists));
//     notifyListeners();
//   }
// }

// final appFeatureStore = AppFeatureStore();

// // Helper to post a notification record to Firestore
// Future<void> sendNotificationRecord({
//   required String title,
//   required String body,
//   required String category,
// }) async {
//   try {
//     await FirebaseFirestore.instance.collection('notifications').add({
//       'title': title,
//       'body': body,
//       'category': category,
//       'created_at': FieldValue.serverTimestamp(),
//     });
//   } catch (e) {
//     debugPrint('Error writing notification: $e');
//   }
// }

// // Color constants for CCM theme (Red/White & Blue/White)
// const Color ccmRed = Color(0xFFC41E3A);
// const Color ccmBlue = Color(0xFF003DA5);
// const Color ccmWhite = Color(0xFFFFFFFF);
// const Color ccmLightGray = Color(0xFFF5F5F5);

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );

//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//     final messaging = FirebaseMessaging.instance;

//     await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     await messaging.subscribeToTopic('all_members');

//   } catch (e) {
//     firebaseInitError = e.toString();
//     debugPrint('Firebase init error: $firebaseInitError');
//   }
//   await appFeatureStore.load();
//   runApp(const CCMMelodiesApp());
// }

// class CCMMelodiesApp extends StatelessWidget {
//   const CCMMelodiesApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'CCM App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: ccmRed),
//         useMaterial3: true,
//         textTheme: GoogleFonts.notoSansTeluguTextTheme(),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: ccmRed,
//           foregroundColor: ccmWhite,
//           elevation: 2,
//         ),
//       ),
//       home: const WelcomeScreen(),
//     );
//   }
// }

// class WelcomeScreen extends StatelessWidget {
//   const WelcomeScreen({super.key});

//   Future<void> _openMember(BuildContext context) async {
//     try {
//       await FirebaseAuth.instance.signInAnonymously();
//       if (!context.mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const MainApp(isAdmin: false, rememberMe: false),
//         ),
//       );
//     } on FirebaseAuthException catch (error) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Member sign-in failed: ${error.message ?? error.code}')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               ccmRed.withValues(alpha: 0.9),
//               ccmBlue.withValues(alpha: 0.9),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               Expanded(
//                 child: Center(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(32),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const SizedBox(height: 28),
//                         Text(
//                           'CONNECTING CHRIST\nMINISTRIES',
//                           textAlign: TextAlign.center,
//                           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: ccmWhite,
//                                 fontSize: 30,
//                               ),
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'A place for worship, prayer, and fellowship.',
//                           textAlign: TextAlign.center,
//                           style: Theme.of(context).textTheme.bodyLarge
//                               ?.copyWith(color: ccmWhite.withValues(alpha: 0.9)),
//                         ),
//                         const SizedBox(height: 48),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: ccmWhite,
//                               foregroundColor: ccmRed,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             onPressed: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const AdminLoginScreen(),
//                               ),
//                             ),
//                             icon: const Icon(Icons.admin_panel_settings_outlined),
//                             label: const Text(
//                               'CCM Admin',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: OutlinedButton.icon(
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: ccmWhite,
//                               side: const BorderSide(color: ccmWhite, width: 2),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             onPressed: () => _openMember(context),
//                             icon: const Icon(Icons.person_outline),
//                             label: const Text(
//                               'CCM Member',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 16.0),
//                 child: Column(
//                   children: [
//                     Text(
//                       'All rights reserved to CCM',
//                       style: TextStyle(
//                         color: ccmWhite.withValues(alpha: 0.8),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'Copyrights @2026',
//                       style: TextStyle(
//                         color: ccmWhite.withValues(alpha: 0.8),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class AdminLoginScreen extends StatefulWidget {
//   const AdminLoginScreen({super.key});

//   @override
//   State<AdminLoginScreen> createState() => _AdminLoginScreenState();
// }

// class _AdminLoginScreenState extends State<AdminLoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _rememberMe = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedCredentials();
//   }

//   Future<void> _loadSavedCredentials() async {
//     final prefs = await SharedPreferences.getInstance();
//     final remember = prefs.getBool('admin_remember_me') ?? false;
//     if (remember) {
//       final email = prefs.getString('admin_email') ?? '';
//       final password = prefs.getString('admin_password') ?? '';
//       setState(() {
//         _rememberMe = true;
//         _usernameController.text = email;
//         _passwordController.text = password;
//       });
//     }
//   }

//   Future<void> _handleRememberMe() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (_rememberMe) {
//       await prefs.setBool('admin_remember_me', true);
//       await prefs.setString('admin_email', _usernameController.text.trim());
//       await prefs.setString('admin_password', _passwordController.text);
//     } else {
//       await prefs.setBool('admin_remember_me', false);
//       await prefs.remove('admin_email');
//       await prefs.remove('admin_password');
//     }
//   }

//   void _login() {
//     if (!_formKey.currentState!.validate()) return;
//     _signInAdmin();
//   }

//   Future<void> _signInAdmin() async {
//     try {
//       final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _usernameController.text.trim(),
//         password: _passwordController.text,
//       );
//       final token = await credential.user?.getIdTokenResult(true);
//       if (token?.claims?['admin'] != true) {
//         await FirebaseAuth.instance.signOut();
//         throw FirebaseAuthException(
//           code: 'not-admin',
//           message: 'This account is not an administrator.',
//         );
//       }

//       await _handleRememberMe();

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MainApp(isAdmin: true, rememberMe: _rememberMe),
//         ),
//       );
//     } on FirebaseAuthException catch (error) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Admin sign-in failed: ${error.message ?? error.code}')),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('CCM Admin Login'),
//         backgroundColor: ccmRed,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               ccmRed.withValues(alpha: 0.05),
//               ccmBlue.withValues(alpha: 0.05),
//             ],
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: ccmRed.withValues(alpha: 0.1),
//                     ),
//                     padding: const EdgeInsets.all(16),
//                     child: const Icon(
//                       Icons.admin_panel_settings,
//                       size: 72,
//                       color: ccmRed,
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   Text(
//                     'Admin Access',
//                     style: Theme.of(context).textTheme.headlineSmall
//                         ?.copyWith(fontWeight: FontWeight.bold, color: ccmRed),
//                   ),
//                   const SizedBox(height: 24),
//                   TextFormField(
//                     controller: _usernameController,
//                     decoration: InputDecoration(
//                       labelText: 'Admin email',
//                       prefixIcon: const Icon(
//                         Icons.person_outline,
//                         color: ccmRed,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: ccmRed, width: 2),
//                       ),
//                     ),
//                     validator: (value) => value == null || value.trim().isEmpty
//                         ? 'Enter admin email'
//                         : null,
//                   ),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: _obscurePassword,
//                     decoration: InputDecoration(
//                       labelText: 'Admin Password',
//                       prefixIcon: const Icon(Icons.lock_outline, color: ccmRed),
//                       suffixIcon: IconButton(
//                         onPressed: () => setState(
//                           () => _obscurePassword = !_obscurePassword,
//                         ),
//                         icon: Icon(
//                           _obscurePassword
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                           color: ccmRed,
//                         ),
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: ccmRed, width: 2),
//                       ),
//                     ),
//                     validator: (value) => value == null || value.isEmpty
//                         ? 'Enter admin password'
//                         : null,
//                   ),
//                   const SizedBox(height: 16),
//                   CheckboxListTile(
//                     value: _rememberMe,
//                     onChanged: (value) =>
//                         setState(() => _rememberMe = value ?? false),
//                     title: const Text('Remember Me'),
//                     activeColor: ccmRed,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ccmRed,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       onPressed: _login,
//                       child: const Text(
//                         'Login',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: ccmWhite,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text(
//                       'Back to Home',
//                       style: TextStyle(color: ccmRed),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class MainApp extends StatefulWidget {
//   final bool isAdmin;
//   final bool rememberMe;

//   const MainApp({super.key, required this.isAdmin, required this.rememberMe});

//   @override
//   State<MainApp> createState() => _MainAppState();
// }

// class _MainAppState extends State<MainApp> {
//   int _selectedIndex = 0;

//   late List<Widget> _screens;

//   @override
//   void initState() {
//     super.initState();
//     _screens = [
//       HomeScreen(isAdmin: widget.isAdmin),
//       SongsScreen(isAdmin: widget.isAdmin),
//       MoreScreen(isAdmin: widget.isAdmin),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) => setState(() => _selectedIndex = index),
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_outlined),
//             activeIcon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.music_note_outlined),
//             activeIcon: Icon(Icons.music_note),
//             label: 'Songs',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.more_horiz_outlined),
//             activeIcon: Icon(Icons.more_horiz),
//             label: 'More',
//           ),
//         ],
//         selectedItemColor: ccmRed,
//         unselectedItemColor: Colors.grey,
//         backgroundColor: ccmWhite,
//         elevation: 8,
//       ),
//     );
//   }
// }

// // ==================== HOME SCREEN ====================
// class HomeScreen extends StatefulWidget {
//   final bool isAdmin;

//   const HomeScreen({super.key, required this.isAdmin});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _dailyBreadIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: const Text(
//           'CONNECTING CHRIST MINISTRIES',
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//         ),
//         centerTitle: true,
//         backgroundColor: ccmRed,
//         elevation: 0,
//         toolbarHeight: 56,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [ccmRed.withValues(alpha: 0.05), ccmWhite],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'SERVICES @ CCM',
//                           style: Theme.of(context).textTheme.titleLarge
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: ccmRed,
//                                 fontSize: 18,
//                               ),
//                         ),
//                         if (widget.isAdmin)
//                           ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: ccmRed,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             onPressed: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     const ServiceManagementScreen(),
//                               ),
//                             ),
//                             icon: const Icon(Icons.settings, size: 16),
//                             label: const Text(
//                               'Manage',
//                               style: TextStyle(fontSize: 11, color: ccmWhite),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collection('services')
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         final services = snapshot.data?.docs ?? [];

//                         final visibleServices = services.where((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           final isEnabled = data['enabled'] ?? true;
//                           return widget.isAdmin || isEnabled;
//                         }).toList();

//                         if (visibleServices.isEmpty) {
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 20),
//                             child: Center(
//                               child: Text(
//                                 'No services available',
//                                 style: Theme.of(context).textTheme.bodyMedium,
//                               ),
//                             ),
//                           );
//                         }

//                         return Column(
//                           children: [
//                             for (
//                               int i = 0;
//                               i < visibleServices.length;
//                               i++
//                             ) ...[
//                               _buildServiceCardFromData(
//                                 context,
//                                 visibleServices[i].data()
//                                     as Map<String, dynamic>,
//                                 widget.isAdmin,
//                               ),
//                               if (i < visibleServices.length - 1)
//                                 const SizedBox(height: 12),
//                             ],
//                           ],
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'DAILY BREAD',
//                           style: Theme.of(context).textTheme.titleLarge
//                               ?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: ccmBlue,
//                                 fontSize: 18,
//                               ),
//                         ),
//                         if (widget.isAdmin)
//                           ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: ccmBlue,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             onPressed: () => Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     const AddDailyBreadScreen(),
//                               ),
//                             ),
//                             icon: const Icon(Icons.add, size: 18),
//                             label: const Text(
//                               'Add',
//                               style: TextStyle(fontSize: 12, color: ccmWhite),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collection('daily_bread')
//                           .orderBy('created_at', descending: true)
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         if (snapshot.hasError) {
//                           return Center(
//                             child: Text('Error: ${snapshot.error}'),
//                           );
//                         }
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const Center(
//                             child: CircularProgressIndicator(),
//                           );
//                         }

//                         final docs = snapshot.data?.docs ?? [];
//                         if (docs.isEmpty) {
//                           return _buildEmptyDailyBread();
//                         }

//                         final item =
//                             docs[_dailyBreadIndex].data()
//                                 as Map<String, dynamic>;
//                         return _buildDailyBreadCard(context, item, docs.length);
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildServiceCardFromData(
//     BuildContext context,
//     Map<String, dynamic> service,
//     bool isAdmin,
//   ) {
//     final bool isEnabled = service['enabled'] ?? true;
//     final opacity = isEnabled ? 1.0 : 0.5;

//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             ccmRed.withValues(alpha: 0.9 * opacity),
//             ccmBlue.withValues(alpha: 0.7 * opacity),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.1 * opacity),
//             blurRadius: 8,
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: ccmWhite.withValues(alpha: 0.2 * opacity),
//             ),
//             padding: const EdgeInsets.all(12),
//             child: Icon(
//               Icons.calendar_today,
//               color: ccmWhite.withValues(alpha: opacity),
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         service['title'] ?? 'Service',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: ccmWhite.withValues(alpha: opacity),
//                         ),
//                       ),
//                     ),
//                     if (!isEnabled && isAdmin)
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[400],
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: const Text(
//                           'Disabled',
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   service['location'] ?? '',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: ccmWhite.withValues(alpha: 0.9 * opacity),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 service['time'] ?? '',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: ccmWhite.withValues(alpha: opacity),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDailyBreadCard(
//     BuildContext context,
//     Map<String, dynamic> item,
//     int totalCount,
//   ) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             ccmBlue.withValues(alpha: 0.9),
//             ccmRed.withValues(alpha: 0.7),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (item['imageUrl'] != null && item['imageUrl'].isNotEmpty)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Image.network(
//                 item['imageUrl'],
//                 height: 200,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 200,
//                   color: ccmLightGray,
//                   child: const Center(child: Icon(Icons.image_not_supported)),
//                 ),
//               ),
//             ),
//           const SizedBox(height: 12),
//           Text(
//             'Bible Verse',
//             style: Theme.of(context).textTheme.titleMedium
//                 ?.copyWith(color: ccmWhite, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             item['verse'] ?? 'No verse text',
//             style: TextStyle(
//               fontSize: 16,
//               color: ccmWhite.withValues(alpha: 0.95),
//               fontStyle: FontStyle.italic,
//               height: 1.5,
//             ),
//           ),
//           const SizedBox(height: 12),
//           if (item['reference'] != null)
//             Text(
//               '- ${item['reference']}',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: ccmWhite.withValues(alpha: 0.9),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           if (totalCount > 1) ...[
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.chevron_left, color: ccmWhite),
//                   onPressed: () => setState(() {
//                     _dailyBreadIndex =
//                         (_dailyBreadIndex - 1 + totalCount) % totalCount;
//                   }),
//                 ),
//                 Text(
//                   '${_dailyBreadIndex + 1} of $totalCount',
//                   style: const TextStyle(
//                     color: ccmWhite,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.chevron_right, color: ccmWhite),
//                   onPressed: () => setState(() {
//                     _dailyBreadIndex = (_dailyBreadIndex + 1) % totalCount;
//                   }),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyDailyBread() {
//     return Container(
//       decoration: BoxDecoration(
//         color: ccmLightGray,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         children: [
//           Icon(Icons.book, size: 64, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'No Daily Bread Yet',
//             style: Theme.of(context).textTheme.titleMedium,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Check back soon for today\'s bible verse',
//             textAlign: TextAlign.center,
//             style: Theme.of(context).textTheme.bodySmall,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ==================== SONGS SCREEN ====================
// class SongsScreen extends StatefulWidget {
//   final bool isAdmin;

//   const SongsScreen({super.key, required this.isAdmin});

//   @override
//   State<SongsScreen> createState() => _SongsScreenState();
// }

// class _SongsScreenState extends State<SongsScreen> {
//   String _searchQuery = '';
//   bool _favoritesOnly = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: const Text(
//           'Songs',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: ccmRed,
//         elevation: 0,
//         actions: [
//           IconButton(
//             tooltip: 'Show favorites',
//             icon: Icon(
//               _favoritesOnly ? Icons.favorite : Icons.favorite_outline,
//             ),
//             onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
//           ),
//         ],
//       ),
//       body: AnimatedBuilder(
//         animation: appFeatureStore,
//         builder: (context, _) => Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search songs (Telugu or English)...',
//                   prefixIcon: const Icon(Icons.search, color: ccmRed),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: ccmRed),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: ccmRed, width: 2),
//                   ),
//                   filled: true,
//                   fillColor: ccmLightGray,
//                 ),
//                 onChanged: (value) =>
//                     setState(() => _searchQuery = value.trim().toLowerCase()),
//               ),
//             ),
//             Expanded(
//               child: Firebase.apps.isEmpty
//                   ? _buildCachedSongs()
//                   : StreamBuilder<QuerySnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collection('songs')
//                           .orderBy('title_english')
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         if (snapshot.hasError) {
//                           return _buildCachedSongs();
//                         }
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const Center(
//                             child: CircularProgressIndicator(),
//                           );
//                         }

//                         final docs = snapshot.data?.docs ?? [];
//                         if (docs.isNotEmpty) appFeatureStore.cacheSongs(docs);
//                         final filtered = docs.where((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           final eng = (data['title_english'] ?? '')
//                               .toString()
//                               .toLowerCase();
//                           final tel = (data['title_telugu'] ?? '')
//                               .toString()
//                               .toLowerCase();
//                           final lyrics = (data['lyrics'] ?? '')
//                               .toString()
//                               .toLowerCase();
//                           return (eng.contains(_searchQuery) ||
//                                   tel.contains(_searchQuery) ||
//                                   lyrics.contains(_searchQuery)) &&
//                               (!_favoritesOnly ||
//                                   appFeatureStore.isFavorite(doc.id));
//                         }).toList();

//                         final songList = filtered.map((doc) => <String, dynamic>{
//                           'id': doc.id,
//                           ...(doc.data() as Map<String, dynamic>),
//                         }).toList();

//                         return Column(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 8,
//                                 horizontal: 16,
//                               ),
//                               color: ccmRed.withValues(alpha: 0.1),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     'Total Songs: ${filtered.length}',
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: ccmRed,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                   if (_favoritesOnly)
//                                     const Text(
//                                       '(Filtered Favorites)',
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color: Colors.grey,
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                             Expanded(
//                               child: filtered.isEmpty
//                                   ? const Center(child: Text('No songs found'))
//                                   : ListView.separated(
//                                       itemCount: filtered.length,
//                                       separatorBuilder: (context, index) =>
//                                           const Divider(height: 1),
//                                       itemBuilder: (context, index) {
//                                         final songDoc = filtered[index];
//                                         final song = songDoc.data()
//                                             as Map<String, dynamic>;
//                                         final isFav = appFeatureStore
//                                             .isFavorite(songDoc.id);

//                                         return ListTile(
//                                           leading: CircleAvatar(
//                                             backgroundColor: ccmRed,
//                                             child: Text(
//                                               (song['title_english'] ?? 'A')[0]
//                                                   .toUpperCase(),
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 color: ccmWhite,
//                                               ),
//                                             ),
//                                           ),
//                                           title: Text(
//                                             song['title_telugu'] ?? '',
//                                             style: const TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w600,
//                                             ),
//                                           ),
//                                           subtitle:
//                                               Text(song['title_english'] ?? ''),
//                                           trailing: IconButton(
//                                             icon: Icon(
//                                               isFav
//                                                   ? Icons.favorite
//                                                   : Icons.favorite_outline,
//                                               color: isFav ? ccmRed : Colors.grey,
//                                             ),
//                                             onPressed: () {
//                                               appFeatureStore.toggleFavorite(songDoc.id);
//                                             },
//                                           ),
//                                           onTap: () => Navigator.push(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder: (context) => LyricViewScreen(
//                                                 songId: songDoc.id,
//                                                 song: song,
//                                                 playlist: songList,
//                                                 currentIndex: index,
//                                               ),
//                                             ),
//                                           ),
//                                           onLongPress: widget.isAdmin
//                                               ? () => _showSongOptions(
//                                                   context,
//                                                   songDoc.id,
//                                                   song,
//                                                 )
//                                               : null,
//                                         );
//                                       },
//                                     ),
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: widget.isAdmin
//           ? FloatingActionButton.extended(
//               backgroundColor: ccmRed,
//               icon: const Icon(Icons.add),
//               label: const Text('Add Song'),
//               onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AddSongScreen()),
//               ),
//             )
//           : null,
//     );
//   }

//   Widget _buildCachedSongs() {
//     final cached = appFeatureStore.cachedSongs.values.where((song) {
//       final query = _searchQuery;
//       final eng = (song['title_english'] ?? '').toString().toLowerCase();
//       final tel = (song['title_telugu'] ?? '').toString().toLowerCase();
//       final lyrics = (song['lyrics'] ?? '').toString().toLowerCase();
//       return (eng.contains(query) ||
//               tel.contains(query) ||
//               lyrics.contains(query)) &&
//           (!_favoritesOnly ||
//               appFeatureStore.isFavorite(song['id'].toString()));
//     }).toList();

//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//           color: ccmRed.withValues(alpha: 0.1),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Total Songs: ${cached.length}',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: ccmRed,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: cached.isEmpty
//               ? Center(
//                   child: Text(
//                     firebaseInitError == null
//                         ? 'No offline songs saved yet.'
//                         : 'No cached songs available.',
//                   ),
//                 )
//               : ListView.separated(
//                   itemCount: cached.length,
//                   separatorBuilder: (context, index) => const Divider(height: 1),
//                   itemBuilder: (context, index) {
//                     final song = cached[index];
//                     final id = song['id'].toString();
//                     final isFav = appFeatureStore.isFavorite(id);

//                     return ListTile(
//                       leading: const CircleAvatar(
//                         backgroundColor: ccmRed,
//                         child: Icon(Icons.music_note, color: ccmWhite),
//                       ),
//                       title: Text(song['title_telugu'] ?? ''),
//                       subtitle: Text(song['title_english'] ?? ''),
//                       trailing: IconButton(
//                         icon: Icon(
//                           isFav ? Icons.favorite : Icons.favorite_outline,
//                           color: isFav ? ccmRed : Colors.grey,
//                         ),
//                         onPressed: () {
//                           appFeatureStore.toggleFavorite(id);
//                         },
//                       ),
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => LyricViewScreen(
//                             songId: id,
//                             song: song,
//                             playlist: cached,
//                             currentIndex: index,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//         ),
//       ],
//     );
//   }

//   void _showSongOptions(
//     BuildContext context,
//     String songId,
//     Map<String, dynamic> song,
//   ) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               song['title_english'] ?? 'Song',
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: const Icon(Icons.edit, color: ccmBlue),
//               title: const Text('Edit Song'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         EditSongScreen(songId: songId, song: song),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.delete, color: Colors.red),
//               title: const Text('Delete Song'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _deleteSong(context, songId, song['title_english'] ?? 'Song');
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _deleteSong(BuildContext context, String songId, String songTitle) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Song'),
//         content: Text('Are you sure you want to delete "$songTitle"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               try {
//                 await FirebaseFirestore.instance
//                     .collection('songs')
//                     .doc(songId)
//                     .delete();
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Song deleted successfully!'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Error deleting song: $e'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ==================== MORE SCREEN ====================
// class MoreScreen extends StatefulWidget {
//   final bool isAdmin;

//   const MoreScreen({super.key, required this.isAdmin});

//   @override
//   State<MoreScreen> createState() => _MoreScreenState();
// }

// class _MoreScreenState extends State<MoreScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: const Text(
//           'More',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: ccmRed,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [ccmRed.withValues(alpha: 0.05), ccmWhite],
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//           children: [
//             _buildMoreCard(
//               context,
//               'About Us',
//               'Learn more about our ministry',
//               Icons.info_outline,
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       const ComingSoonScreen(title: 'About Us'),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildMoreCard(
//               context,
//               'Pastoral Team',
//               'Meet our pastoral leaders',
//               Icons.people_outline,
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       const ComingSoonScreen(title: 'Pastoral Team'),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildMoreCard(
//               context,
//               'Contact Us',
//               'Get in touch with us',
//               Icons.email_outlined,
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       const ComingSoonScreen(title: 'Contact Us'),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildMoreCard(
//               context,
//               'Prayer Request',
//               'Submit your prayer requests',
//               Icons.favorite_outline,
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       const ComingSoonScreen(title: 'Prayer Request'),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildMoreCard(
//               context,
//               'Favorite Songs',
//               'Your saved songs, available offline',
//               Icons.favorite_outline,
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const FavoritesScreen(),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             _buildMoreCard(
//               context,
//               'Worship Setlists',
//               widget.isAdmin
//                   ? 'Create and publish service setlists'
//                   : 'View published service setlists',
//               Icons.queue_music,
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => SetlistsScreen(isAdmin: widget.isAdmin),
//                 ),
//               ),
//             ),
//             if (widget.isAdmin) ...[
//               const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 4),
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red[700],
//                     foregroundColor: ccmWhite,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                         title: const Text('Logout'),
//                         content: const Text('Are you sure you want to logout?'),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: const Text('Cancel'),
//                           ),
//                           TextButton(
//                             onPressed: () async {
//                               await FirebaseAuth.instance.signOut();
//                               Navigator.pop(context);
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => const WelcomeScreen(),
//                                 ),
//                               );
//                             },
//                             child: const Text(
//                               'Logout',
//                               style: TextStyle(color: Colors.red),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                   icon: const Icon(Icons.logout),
//                   label: const Text(
//                     'Admin Logout',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMoreCard(
//     BuildContext context,
//     String title,
//     String subtitle,
//     IconData icon,
//     VoidCallback onTap,
//   ) {
//     return Container(
//       decoration: BoxDecoration(
//         color: ccmWhite,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: ccmRed.withValues(alpha: 0.2)),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
//         ],
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//         leading: Container(
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: ccmRed.withValues(alpha: 0.1),
//           ),
//           padding: const EdgeInsets.all(12),
//           child: Icon(icon, color: ccmRed, size: 24),
//         ),
//         title: Text(
//           title,
//           style: Theme.of(context).textTheme.titleMedium
//               ?.copyWith(fontWeight: FontWeight.bold, color: ccmRed),
//         ),
//         subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
//         trailing: const Icon(Icons.arrow_forward, color: ccmRed),
//         onTap: onTap,
//       ),
//     );
//   }
// }

// class FavoritesScreen extends StatelessWidget {
//   const FavoritesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Favorite Songs'),
//         backgroundColor: ccmRed,
//       ),
//       body: AnimatedBuilder(
//         animation: appFeatureStore,
//         builder: (context, _) {
//           final songIds = appFeatureStore.favoriteSongIds;
//           final songs = songIds
//               .map((id) => appFeatureStore.cachedSongs[id])
//               .whereType<Map<String, dynamic>>()
//               .toList();

//           if (songs.isEmpty) {
//             return const Center(
//               child: Text('Favorite songs will appear here.'),
//             );
//           }

//           return ReorderableListView.builder(
//             itemCount: songs.length,
//             onReorder: (oldIndex, newIndex) {
//               appFeatureStore.reorderFavorites(oldIndex, newIndex);
//             },
//             itemBuilder: (context, index) {
//               final song = songs[index];
//               final id = song['id'].toString();
//               return ListTile(
//                 key: ValueKey(id),
//                 leading: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.drag_handle, color: Colors.grey),
//                     const SizedBox(width: 8),
//                     CircleAvatar(
//                       backgroundColor: ccmRed,
//                       radius: 14,
//                       child: Text(
//                         '${index + 1}',
//                         style: const TextStyle(fontSize: 12, color: ccmWhite),
//                       ),
//                     ),
//                   ],
//                 ),
//                 title: Text(song['title_telugu'] ?? ''),
//                 subtitle: Text(song['title_english'] ?? ''),
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => LyricViewScreen(
//                       songId: id,
//                       song: song,
//                       playlist: songs,
//                       currentIndex: index,
//                     ),
//                   ),
//                 ),
//                 trailing: IconButton(
//                   tooltip: 'Remove favorite',
//                   icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
//                   onPressed: () => appFeatureStore.toggleFavorite(id),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class SetlistsScreen extends StatefulWidget {
//   final bool isAdmin;

//   const SetlistsScreen({super.key, required this.isAdmin});

//   @override
//   State<SetlistsScreen> createState() => _SetlistsScreenState();
// }

// class _SetlistsScreenState extends State<SetlistsScreen> {
//   Future<void> _publishSetlist(Map<String, dynamic> setlist) async {
//     final id = setlist['id'].toString();
//     await FirebaseFirestore.instance.collection('setlists').doc(id).set({
//       'name': setlist['name'],
//       'songIds': List<String>.from(setlist['songIds'] as List<dynamic>),
//       'published': true,
//       'updated_at': FieldValue.serverTimestamp(),
//     }, SetOptions(merge: true));
//     setlist['published'] = true;
//     await appFeatureStore.saveSetlists();
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Setlist published for members.'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   Future<void> _hideSetlist(Map<String, dynamic> setlist) async {
//     await FirebaseFirestore.instance
//         .collection('setlists')
//         .doc(setlist['id'].toString())
//         .set({
//           'published': false,
//           'updated_at': FieldValue.serverTimestamp(),
//         }, SetOptions(merge: true));
//     setlist['published'] = false;
//     await appFeatureStore.saveSetlists();
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Setlist hidden from members.')),
//       );
//     }
//   }

//   Future<void> _deleteSetlist(Map<String, dynamic> setlist) async {
//     await FirebaseFirestore.instance
//         .collection('setlists')
//         .doc(setlist['id'].toString())
//         .delete();
//     appFeatureStore.setlists.removeWhere((item) => item['id'] == setlist['id']);
//     await appFeatureStore.saveSetlists();
//   }

//   Future<void> _createSetlist() async {
//     final controller = TextEditingController();
//     bool sendNotification = false;

//     final result = await showDialog<Map<String, dynamic>>(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           title: const Text('New setlist'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: controller,
//                 autofocus: true,
//                 decoration: const InputDecoration(labelText: 'Setlist name'),
//               ),
//               const SizedBox(height: 12),
//               CheckboxListTile(
//                 value: sendNotification,
//                 onChanged: (val) => setDialogState(() => sendNotification = val ?? false),
//                 title: const Text('Send notification to members', style: TextStyle(fontSize: 14)),
//                 activeColor: ccmRed,
//                 contentPadding: EdgeInsets.zero,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             FilledButton(
//               onPressed: () => Navigator.pop(context, {
//                 'name': controller.text.trim(),
//                 'sendNotification': sendNotification,
//               }),
//               child: const Text('Create'),
//             ),
//           ],
//         ),
//       ),
//     );
//     controller.dispose();
//     if (result == null || (result['name'] as String).isEmpty) return;

//     final name = result['name'] as String;
//     final notify = result['sendNotification'] as bool;

//     appFeatureStore.setlists.add(<String, dynamic>{
//       'id': DateTime.now().millisecondsSinceEpoch.toString(),
//       'name': name,
//       'songIds': <String>[],
//     });
//     await appFeatureStore.saveSetlists();

//     if (notify) {
//       await sendNotificationRecord(
//         title: 'New Worship Setlist',
//         body: 'A new worship setlist "$name" has been created!',
//         category: 'setlist',
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.isAdmin) return const PublishedSetlistsScreen();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Worship Setlists'),
//         backgroundColor: ccmRed,
//       ),
//       body: AnimatedBuilder(
//         animation: appFeatureStore,
//         builder: (context, _) {
//           if (appFeatureStore.setlists.isEmpty) {
//             return const Center(
//               child: Text('Create a setlist for your next service.'),
//             );
//           }
//           return ListView.separated(
//             padding: const EdgeInsets.all(12),
//             itemCount: appFeatureStore.setlists.length,
//             separatorBuilder: (context, index) => const SizedBox(height: 8),
//             itemBuilder: (context, index) {
//               final setlist = appFeatureStore.setlists[index];
//               final songCount =
//                   (setlist['songIds'] as List<dynamic>? ?? []).length;
//               return ListTile(
//                 tileColor: ccmLightGray,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 leading: const Icon(Icons.queue_music, color: ccmRed),
//                 title: Text(
//                   setlist['name'] ?? 'Setlist',
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text('$songCount song${songCount == 1 ? '' : 's'}'),
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         SetlistDetailScreen(setlistIndex: index),
//                   ),
//                 ),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       tooltip: 'Publish or hide setlist',
//                       icon: Icon(
//                         setlist['published'] == true
//                             ? Icons.visibility_off
//                             : Icons.publish,
//                         color: setlist['published'] == true
//                             ? Colors.orange
//                             : ccmBlue,
//                       ),
//                       onPressed: () => setlist['published'] == true
//                           ? _hideSetlist(setlist)
//                           : _publishSetlist(setlist),
//                     ),
//                     IconButton(
//                       tooltip: 'Delete setlist',
//                       icon: const Icon(Icons.delete_outline, color: Colors.red),
//                       onPressed: () => _deleteSetlist(setlist),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: ccmRed,
//         icon: const Icon(Icons.add),
//         label: const Text('New setlist'),
//         onPressed: _createSetlist,
//       ),
//     );
//   }
// }

// class PublishedSetlistsScreen extends StatelessWidget {
//   const PublishedSetlistsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Published Setlists'),
//         backgroundColor: ccmRed,
//       ),
//       body: Firebase.apps.isEmpty
//           ? const Center(child: Text('Published setlists are unavailable offline.'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('setlists')
//                   .where('published', isEqualTo: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Unable to load setlists: ${snapshot.error}'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot>[];
//                 if (docs.isEmpty) {
//                   return const Center(child: Text('No setlists have been published yet.'));
//                 }
//                 return ListView.separated(
//                   padding: const EdgeInsets.all(12),
//                   itemCount: docs.length,
//                   separatorBuilder: (context, index) => const SizedBox(height: 8),
//                   itemBuilder: (context, index) {
//                     final setlist = docs[index].data() as Map<String, dynamic>;
//                     final songCount = (setlist['songIds'] as List<dynamic>? ?? []).length;
//                     return ListTile(
//                       tileColor: ccmLightGray,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                       leading: const Icon(Icons.queue_music, color: ccmRed),
//                       title: Text(setlist['name'] ?? 'Worship setlist', style: const TextStyle(fontWeight: FontWeight.bold)),
//                       subtitle: Text('$songCount song${songCount == 1 ? '' : 's'}'),
//                       trailing: const Icon(Icons.chevron_right, color: ccmRed),
//                       onTap: () => Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => PublishedSetlistDetailScreen(setlist: setlist)),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }

// class PublishedSetlistDetailScreen extends StatelessWidget {
//   final Map<String, dynamic> setlist;

//   const PublishedSetlistDetailScreen({super.key, required this.setlist});

//   @override
//   Widget build(BuildContext context) {
//     final songIds = (setlist['songIds'] as List<dynamic>? ?? []).map((id) => id.toString()).toList();
//     return Scaffold(
//       appBar: AppBar(title: Text(setlist['name'] ?? 'Setlist'), backgroundColor: ccmRed),
//       body: Firebase.apps.isEmpty
//           ? const Center(child: Text('Songs are unavailable offline.'))
//           : StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance.collection('songs').snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final songsById = <String, Map<String, dynamic>>{
//                   for (final doc in snapshot.data?.docs ?? <QueryDocumentSnapshot>[])
//                     doc.id: <String, dynamic>{'id': doc.id, ...(doc.data() as Map<String, dynamic>)},
//                 };

//                 final setlistSongs = songIds
//                     .map((id) => songsById[id])
//                     .whereType<Map<String, dynamic>>()
//                     .toList();

//                 return ListView.separated(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   itemCount: songIds.length,
//                   separatorBuilder: (context, index) => const Divider(height: 1),
//                   itemBuilder: (context, index) {
//                     final song = songsById[songIds[index]];
//                     return ListTile(
//                       leading: CircleAvatar(child: Text('${index + 1}')),
//                       title: Text(song?['title_english'] ?? 'Song ${index + 1}'),
//                       subtitle: Text(song?['title_telugu'] ?? 'Song unavailable'),
//                       onTap: song == null
//                           ? null
//                           : () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => LyricViewScreen(
//                                     songId: song['id'].toString(),
//                                     song: song,
//                                     playlist: setlistSongs,
//                                     currentIndex: index,
//                                   ),
//                                 ),
//                               ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }

// class SetlistDetailScreen extends StatefulWidget {
//   final int setlistIndex;
//   const SetlistDetailScreen({super.key, required this.setlistIndex});

//   @override
//   State<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
// }

// class _SetlistDetailScreenState extends State<SetlistDetailScreen> {
//   Map<String, dynamic> get _setlist =>
//       appFeatureStore.setlists[widget.setlistIndex];

//   Future<void> _addSong() async {
//     final songs = appFeatureStore.cachedSongs.values.toList();
//     if (songs.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Open the Songs tab once to cache songs for offline setlists.',
//           ),
//         ),
//       );
//       return;
//     }
//     final selected = await showDialog<String>(
//       context: context,
//       builder: (context) => SimpleDialog(
//         title: const Text('Add song'),
//         children: songs
//             .map(
//               (song) => SimpleDialogOption(
//                 onPressed: () => Navigator.pop(context, song['id'].toString()),
//                 child: Text(song['title_english'] ?? 'Song'),
//               ),
//             )
//             .toList(),
//       ),
//     );
//     if (selected == null) return;
//     final ids = (_setlist['songIds'] as List<dynamic>).cast<String>();
//     if (!ids.contains(selected)) ids.add(selected);
//     await appFeatureStore.saveSetlists();
//     if (mounted) setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final ids = (_setlist['songIds'] as List<dynamic>).cast<String>();
//     final songs = ids
//         .map((id) => appFeatureStore.cachedSongs[id])
//         .whereType<Map<String, dynamic>>()
//         .toList();
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_setlist['name'] ?? 'Setlist'),
//         backgroundColor: ccmRed,
//       ),
//       body: songs.isEmpty
//           ? const Center(child: Text('Add songs to build this setlist.'))
//           : ReorderableListView.builder(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               itemCount: songs.length,
//               onReorder: (oldIndex, newIndex) async {
//                 if (newIndex > oldIndex) newIndex -= 1;
//                 final id = ids.removeAt(oldIndex);
//                 ids.insert(newIndex, id);
//                 await appFeatureStore.saveSetlists();
//                 if (mounted) setState(() {});
//               },
//               itemBuilder: (context, index) {
//                 final song = songs[index];
//                 final id = song['id'].toString();
//                 return ListTile(
//                   key: ValueKey(id),
//                   leading: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.drag_handle, color: Colors.grey),
//                       const SizedBox(width: 8),
//                       CircleAvatar(child: Text('${index + 1}')),
//                     ],
//                   ),
//                   title: Text(song['title_english'] ?? 'Song'),
//                   subtitle: Text(song['title_telugu'] ?? ''),
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => LyricViewScreen(
//                         songId: id,
//                         song: song,
//                         playlist: songs,
//                         currentIndex: index,
//                       ),
//                     ),
//                   ),
//                   trailing: IconButton(
//                     tooltip: 'Remove song',
//                     icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
//                     onPressed: () async {
//                       ids.remove(id);
//                       await appFeatureStore.saveSetlists();
//                       if (mounted) setState(() {});
//                     },
//                   ),
//                 );
//               },
//             ),
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: ccmRed,
//         icon: const Icon(Icons.add),
//         label: const Text('Add song'),
//         onPressed: _addSong,
//       ),
//     );
//   }
// }

// // ==================== COMING SOON SCREEN ====================
// class ComingSoonScreen extends StatelessWidget {
//   final String title;

//   const ComingSoonScreen({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(title), backgroundColor: ccmRed),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               ccmRed.withValues(alpha: 0.05),
//               ccmBlue.withValues(alpha: 0.05),
//             ],
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.schedule,
//                 size: 120,
//                 color: ccmRed.withValues(alpha: 0.5),
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Coming Soon',
//                 style: Theme.of(context).textTheme.headlineSmall
//                     ?.copyWith(fontWeight: FontWeight.bold, color: ccmRed),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'This section is under development.\nCheck back soon!',
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context).textTheme.bodyLarge
//                     ?.copyWith(color: Colors.grey[600]),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ==================== LYRIC VIEWER SCREEN ====================
// class LyricViewScreen extends StatefulWidget {
//   final Map<String, dynamic> song;
//   final String songId;
//   final List<Map<String, dynamic>>? playlist;
//   final int? currentIndex;

//   const LyricViewScreen({
//     super.key,
//     required this.songId,
//     required this.song,
//     this.playlist,
//     this.currentIndex,
//   });

//   @override
//   State<LyricViewScreen> createState() => _LyricViewScreenState();
// }

// class _LyricViewScreenState extends State<LyricViewScreen> {
//   late double _fontSize;
//   int _transpose = 0;

//   late Map<String, dynamic> _currentSong;
//   late String _currentSongId;
//   int? _currentIndex;

//   static const _chordNames = <String>[
//     'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _currentSong = widget.song;
//     _currentSongId = widget.songId;
//     _currentIndex = widget.currentIndex;
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     final screenWidth = MediaQuery.of(context).size.width;
//     if (screenWidth < 350) {
//       _fontSize = 16.0;
//     } else if (screenWidth < 600) {
//       _fontSize = 18.0;
//     } else {
//       _fontSize = 22.0;
//     }
//   }

//   String _transposeChords(String chords) {
//     if (_transpose == 0 || chords.trim().isEmpty) return chords;
//     return chords.replaceAllMapped(
//       RegExp(r'(?<![A-Za-z])([A-G](?:#|b)?)(m|sus|7|add|dim|aug)?'),
//       (match) {
//         final root = match.group(1)!;
//         final suffix = match.group(2) ?? '';
//         final normalized = root.replaceAll('b', '#');
//         final index = _chordNames.indexOf(normalized);
//         if (index == -1) return match.group(0)!;
//         return '${_chordNames[(index + _transpose) % _chordNames.length]}$suffix';
//       },
//     );
//   }

//   void _navigateSong(int delta) {
//     if (widget.playlist == null || _currentIndex == null) return;
//     final newIndex = _currentIndex! + delta;
//     if (newIndex >= 0 && newIndex < widget.playlist!.length) {
//       final nextSong = widget.playlist![newIndex];
//       setState(() {
//         _currentIndex = newIndex;
//         _currentSong = nextSong;
//         _currentSongId = nextSong['id']?.toString() ?? '';
//         _transpose = 0;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasPlaylist = widget.playlist != null && widget.playlist!.length > 1;
//     final canGoPrevious = hasPlaylist && (_currentIndex ?? 0) > 0;
//     final canGoNext = hasPlaylist && (_currentIndex ?? 0) < widget.playlist!.length - 1;

//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: true,
//         title: Text(
//           _currentSong['title_english'] ?? 'Lyrics',
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: ccmRed,
//         actions: [
//           if (hasPlaylist) ...[
//             IconButton(
//               tooltip: 'Previous Song',
//               icon: const Icon(Icons.arrow_back_ios, size: 18),
//               onPressed: canGoPrevious ? () => _navigateSong(-1) : null,
//             ),
//             IconButton(
//               tooltip: 'Next Song',
//               icon: const Icon(Icons.arrow_forward_ios, size: 18),
//               onPressed: canGoNext ? () => _navigateSong(1) : null,
//             ),
//           ],
//           IconButton(
//             tooltip: 'Favorite song',
//             icon: Icon(
//               appFeatureStore.isFavorite(_currentSongId)
//                   ? Icons.favorite
//                   : Icons.favorite_outline,
//             ),
//             onPressed: () async {
//               await appFeatureStore.toggleFavorite(_currentSongId);
//               if (mounted) setState(() {});
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.text_decrease),
//             onPressed: () =>
//                 setState(() => _fontSize = (_fontSize - 2).clamp(14.0, 32.0)),
//           ),
//           IconButton(
//             icon: const Icon(Icons.text_increase),
//             onPressed: () =>
//                 setState(() => _fontSize = (_fontSize + 2).clamp(14.0, 32.0)),
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [ccmRed.withValues(alpha: 0.05), ccmWhite],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 _currentSong['title_telugu'] ?? '',
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1a1a1a),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _currentSong['title_english'] ?? '',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Color(0xFF404040),
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               if ((_currentSong['chords'] ?? '')
//                   .toString()
//                   .trim()
//                   .isNotEmpty) ...[
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Text(
//                       'Key: ${_currentSong['key'] ?? 'Original'}',
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const Spacer(),
//                     IconButton(
//                       tooltip: 'Transpose down',
//                       onPressed: () => setState(
//                         () => _transpose = (_transpose - 1).clamp(-11, 11),
//                       ),
//                       icon: const Icon(Icons.keyboard_arrow_down),
//                     ),
//                     Text(
//                       '${_transpose >= 0 ? '+' : ''}$_transpose',
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     IconButton(
//                       tooltip: 'Transpose up',
//                       onPressed: () => setState(
//                         () => _transpose = (_transpose + 1).clamp(-11, 11),
//                       ),
//                       icon: const Icon(Icons.keyboard_arrow_up),
//                     ),
//                   ],
//                 ),
//                 SelectableText(
//                   _transposeChords(_currentSong['chords'].toString()),
//                   style: TextStyle(
//                     fontSize: _fontSize,
//                     height: 1.8,
//                     color: ccmBlue,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 16),
//               SelectableText(
//                 _currentSong['lyrics'] ?? '',
//                 style: TextStyle(
//                   fontSize: _fontSize,
//                   height: 1.8,
//                   color: const Color(0xFF1a1a1a),
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 60),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: ccmRed,
//         onPressed: () => Navigator.pop(context),
//         child: const Icon(Icons.arrow_back, color: ccmWhite),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }
// }

// // ==================== ADD SONG SCREEN ====================
// class AddSongScreen extends StatefulWidget {
//   const AddSongScreen({super.key});

//   @override
//   State<AddSongScreen> createState() => _AddSongScreenState();
// }

// class _AddSongScreenState extends State<AddSongScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _engTitleController = TextEditingController();
//   final _telTitleController = TextEditingController();
//   final _lyricsController = TextEditingController();
//   final _keyController = TextEditingController();
//   final _chordsController = TextEditingController();
//   bool _isSubmitting = false;
//   bool _sendNotification = false;

//   Future<void> _submitSong() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSubmitting = true);
//     try {
//       final titleEng = _engTitleController.text.trim();
//       final titleTel = _telTitleController.text.trim();

//       await FirebaseFirestore.instance.collection('songs').add({
//         'title_english': titleEng,
//         'title_telugu': titleTel,
//         'lyrics': _lyricsController.text.trim(),
//         'key': _keyController.text.trim(),
//         'chords': _chordsController.text.trim(),
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       if (_sendNotification) {
//         await sendNotificationRecord(
//           title: 'New Song Added',
//           body: '$titleEng ($titleTel) is now available in CCM App.',
//           category: 'song',
//         );
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Song added successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error adding song: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Add New Song',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: ccmRed,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [ccmRed.withValues(alpha: 0.05), ccmWhite],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _engTitleController,
//                   decoration: InputDecoration(
//                     labelText: 'Title in English',
//                     hintText: 'e.g., Aaradhana Neeke',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                     prefixIcon: const Icon(Icons.title, color: ccmRed),
//                   ),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _keyController,
//                   decoration: InputDecoration(
//                     labelText: 'Original key (optional)',
//                     hintText: 'e.g., G',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     prefixIcon: const Icon(Icons.music_note, color: ccmRed),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _chordsController,
//                   maxLines: 5,
//                   decoration: InputDecoration(
//                     labelText: 'Chords (optional)',
//                     hintText:
//                         'Paste chord notation here, for example: G  D  Em  C',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     alignLabelWithHint: true,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _telTitleController,
//                   decoration: InputDecoration(
//                     labelText: 'Title in Telugu',
//                     hintText: 'e.g., ఆరాధన నీకే',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                     prefixIcon: const Icon(Icons.language, color: ccmRed),
//                   ),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _lyricsController,
//                   maxLines: 12,
//                   decoration: InputDecoration(
//                     labelText: 'Song Lyrics',
//                     hintText: 'Enter song lyrics in Telugu script...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                     alignLabelWithHint: true,
//                   ),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 CheckboxListTile(
//                   value: _sendNotification,
//                   onChanged: (val) =>
//                       setState(() => _sendNotification = val ?? false),
//                   title: const Text('Send notification to members'),
//                   activeColor: ccmRed,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: ccmRed,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: _isSubmitting ? null : _submitSong,
//                     icon: _isSubmitting
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 ccmWhite,
//                               ),
//                             ),
//                           )
//                         : const Icon(Icons.save),
//                     label: Text(
//                       _isSubmitting ? 'Saving...' : 'Save & Publish Song',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: ccmWhite,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _engTitleController.dispose();
//     _telTitleController.dispose();
//     _lyricsController.dispose();
//     _keyController.dispose();
//     _chordsController.dispose();
//     super.dispose();
//   }
// }

// // ==================== EDIT SONG SCREEN ====================
// class EditSongScreen extends StatefulWidget {
//   final String songId;
//   final Map<String, dynamic> song;
//   const EditSongScreen({super.key, required this.songId, required this.song});

//   @override
//   State<EditSongScreen> createState() => _EditSongScreenState();
// }

// class _EditSongScreenState extends State<EditSongScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _engTitleController;
//   late TextEditingController _telTitleController;
//   late TextEditingController _lyricsController;
//   late TextEditingController _keyController;
//   late TextEditingController _chordsController;
//   bool _isSubmitting = false;

//   @override
//   void initState() {
//     super.initState();
//     _engTitleController = TextEditingController(
//       text: widget.song['title_english'] ?? '',
//     );
//     _telTitleController = TextEditingController(
//       text: widget.song['title_telugu'] ?? '',
//     );
//     _lyricsController = TextEditingController(
//       text: widget.song['lyrics'] ?? '',
//     );
//     _keyController = TextEditingController(text: widget.song['key'] ?? '');
//     _chordsController = TextEditingController(
//       text: widget.song['chords'] ?? '',
//     );
//   }

//   Future<void> _updateSong() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSubmitting = true);
//     try {
//       await FirebaseFirestore.instance
//           .collection('songs')
//           .doc(widget.songId)
//           .update({
//             'title_english': _engTitleController.text.trim(),
//             'title_telugu': _telTitleController.text.trim(),
//             'lyrics': _lyricsController.text.trim(),
//             'key': _keyController.text.trim(),
//             'chords': _chordsController.text.trim(),
//             'updated_at': FieldValue.serverTimestamp(),
//           });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Song updated successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error updating song: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Edit Song',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: ccmRed,
//         automaticallyImplyLeading: false,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [ccmRed.withValues(alpha: 0.05), ccmWhite],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _engTitleController,
//                   decoration: InputDecoration(
//                     labelText: 'Title in English',
//                     hintText: 'e.g., Aaradhana Neeke',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                     prefixIcon: const Icon(Icons.title, color: ccmRed),
//                   ),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _keyController,
//                   decoration: InputDecoration(
//                     labelText: 'Original key (optional)',
//                     hintText: 'e.g., G',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     prefixIcon: const Icon(Icons.music_note, color: ccmRed),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _chordsController,
//                   maxLines: 5,
//                   decoration: InputDecoration(
//                     labelText: 'Chords (optional)',
//                     hintText:
//                         'Paste chord notation here, for example: G  D  Em  C',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     alignLabelWithHint: true,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _telTitleController,
//                   decoration: InputDecoration(
//                     labelText: 'Title in Telugu',
//                     hintText: 'e.g., ఆరాధన నీకే',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                     prefixIcon: const Icon(Icons.language, color: ccmRed),
//                   ),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _lyricsController,
//                   maxLines: 12,
//                   decoration: InputDecoration(
//                     labelText: 'Song Lyrics',
//                     hintText: 'Enter song lyrics in Telugu script...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                     alignLabelWithHint: true,
//                   ),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: ccmRed,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: _isSubmitting ? null : _updateSong,
//                     icon: _isSubmitting
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 ccmWhite,
//                               ),
//                             ),
//                           )
//                         : const Icon(Icons.save),
//                     label: Text(
//                       _isSubmitting ? 'Saving...' : 'Update Song',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: ccmWhite,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _engTitleController.dispose();
//     _telTitleController.dispose();
//     _lyricsController.dispose();
//     _keyController.dispose();
//     _chordsController.dispose();
//     super.dispose();
//   }
// }

// // ==================== SERVICE MANAGEMENT SCREEN ====================
// class ServiceManagementScreen extends StatefulWidget {
//   const ServiceManagementScreen({super.key});

//   @override
//   State<ServiceManagementScreen> createState() =>
//       _ServiceManagementScreenState();
// }

// class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
//   Future<void> _deleteService(String serviceId, String serviceName) async {
//     final shouldDelete = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Service'),
//         content: Text('Are you sure you want to delete "$serviceName"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (shouldDelete == true && mounted) {
//       try {
//         await FirebaseFirestore.instance
//             .collection('services')
//             .doc(serviceId)
//             .delete();
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Service deleted successfully!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Error deleting service: $e'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   Future<void> _toggleServiceStatus(
//     String serviceId,
//     bool currentStatus,
//   ) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('services')
//           .doc(serviceId)
//           .update({'enabled': !currentStatus});
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Service ${!currentStatus ? 'enabled' : 'disabled'} successfully!',
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error updating service: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Manage Services',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: ccmRed,
//         automaticallyImplyLeading: false,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [ccmRed.withValues(alpha: 0.05), ccmWhite],
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('services')
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(
//                       child: CircularProgressIndicator(color: ccmRed),
//                     );
//                   }

//                   final services = snapshot.data?.docs ?? [];
//                   if (services.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.event_busy,
//                             size: 64,
//                             color: Colors.grey[300],
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             'No services yet',
//                             style: Theme.of(context).textTheme.titleMedium,
//                           ),
//                           const SizedBox(height: 24),
//                           ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: ccmRed,
//                             ),
//                             onPressed: () => _showAddServiceDialog(),
//                             icon: const Icon(Icons.add),
//                             label: const Text(
//                               'Create Service',
//                               style: TextStyle(color: ccmWhite),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: services.length,
//                     itemBuilder: (context, index) {
//                       final service =
//                           services[index].data() as Map<String, dynamic>;
//                       final serviceId = services[index].id;
//                       final isEnabled = service['enabled'] ?? true;

//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 12),
//                         elevation: 2,
//                         child: ListTile(
//                           leading: Icon(
//                             Icons.calendar_today,
//                             color: isEnabled ? ccmRed : Colors.grey[400],
//                           ),
//                           title: Text(service['title'] ?? 'Service'),
//                           subtitle: Text(
//                             '${service['location'] ?? ''} • ${service['time'] ?? ''}',
//                           ),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               IconButton(
//                                 icon: Icon(
//                                   isEnabled
//                                       ? Icons.visibility
//                                       : Icons.visibility_off,
//                                   color: isEnabled ? ccmBlue : Colors.grey[400],
//                                 ),
//                                 onPressed: () =>
//                                     _toggleServiceStatus(serviceId, isEnabled),
//                                 tooltip: isEnabled ? 'Disable' : 'Enable',
//                               ),
//                               IconButton(
//                                 icon: const Icon(
//                                   Icons.delete,
//                                   color: Colors.red,
//                                 ),
//                                 onPressed: () => _deleteService(
//                                   serviceId,
//                                   service['title'] ?? 'Service',
//                                 ),
//                               ),
//                             ],
//                           ),
//                           onTap: () =>
//                               _showEditServiceDialog(serviceId, service),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: ccmRed,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   onPressed: _showAddServiceDialog,
//                   icon: const Icon(Icons.add),
//                   label: const Text(
//                     'Add New Service',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: ccmWhite,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showAddServiceDialog() {
//     final titleController = TextEditingController();
//     final locationController = TextEditingController();
//     final timeController = TextEditingController();
//     bool sendNotification = false;

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           title: const Text('Add New Service'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: titleController,
//                   decoration: InputDecoration(
//                     labelText: 'Service Title',
//                     hintText: 'e.g., Sunday Service',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: locationController,
//                   decoration: InputDecoration(
//                     labelText: 'Location',
//                     hintText: 'e.g., Konnembattu',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: timeController,
//                   decoration: InputDecoration(
//                     labelText: 'Time',
//                     hintText: 'e.g., 10:30 AM',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       borderSide: const BorderSide(color: ccmRed, width: 2),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 CheckboxListTile(
//                   value: sendNotification,
//                   onChanged: (val) =>
//                       setDialogState(() => sendNotification = val ?? false),
//                   title: const Text('Send notification to members',
//                       style: TextStyle(fontSize: 14)),
//                   activeColor: ccmRed,
//                   contentPadding: EdgeInsets.zero,
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: ccmRed),
//               onPressed: () async {
//                 final title = titleController.text.trim();
//                 final loc = locationController.text.trim();
//                 final time = timeController.text.trim();

//                 if (title.isEmpty || loc.isEmpty || time.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Please fill all fields'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                   return;
//                 }

//                 try {
//                   await FirebaseFirestore.instance.collection('services').add({
//                     'title': title,
//                     'location': loc,
//                     'time': time,
//                     'enabled': true,
//                     'created_at': FieldValue.serverTimestamp(),
//                   });

//                   if (sendNotification) {
//                     await sendNotificationRecord(
//                       title: 'New Service Scheduled',
//                       body: '$title at $loc on $time',
//                       category: 'service',
//                     );
//                   }

//                   if (mounted) {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Service created successfully!'),
//                         backgroundColor: Colors.green,
//                       ),
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Error: $e'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 }
//               },
//               child: const Text('Create', style: TextStyle(color: ccmWhite)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showEditServiceDialog(String serviceId, Map<String, dynamic> service) {
//     final titleController = TextEditingController(text: service['title'] ?? '');
//     final locationController = TextEditingController(
//       text: service['location'] ?? '',
//     );
//     final timeController = TextEditingController(text: service['time'] ?? '');

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Edit Service'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 decoration: InputDecoration(
//                   labelText: 'Service Title',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(color: ccmRed, width: 2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: locationController,
//                 decoration: InputDecoration(
//                   labelText: 'Location',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(color: ccmRed, width: 2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: timeController,
//                 decoration: InputDecoration(
//                   labelText: 'Time',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(color: ccmRed, width: 2),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: ccmRed),
//             onPressed: () async {
//               if (titleController.text.trim().isEmpty ||
//                   locationController.text.trim().isEmpty ||
//                   timeController.text.trim().isEmpty) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Please fill all fields'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//                 return;
//               }

//               try {
//                 await FirebaseFirestore.instance
//                     .collection('services')
//                     .doc(serviceId)
//                     .update({
//                       'title': titleController.text.trim(),
//                       'location': locationController.text.trim(),
//                       'time': timeController.text.trim(),
//                     });

//                 if (mounted) {
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Service updated successfully!'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 }
//               } catch (e) {
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Error: $e'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               }
//             },
//             child: const Text('Update', style: TextStyle(color: ccmWhite)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ==================== ADD DAILY BREAD SCREEN ====================
// class AddDailyBreadScreen extends StatefulWidget {
//   const AddDailyBreadScreen({super.key});

//   @override
//   State<AddDailyBreadScreen> createState() => _AddDailyBreadScreenState();
// }

// class _AddDailyBreadScreenState extends State<AddDailyBreadScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _verseController = TextEditingController();
//   final _referenceController = TextEditingController();
//   final _imageUrlController = TextEditingController();
//   bool _isSubmitting = false;
//   bool _sendNotification = false;

//   Future<void> _submitDailyBread() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSubmitting = true);
//     try {
//       final verse = _verseController.text.trim();
//       final ref = _referenceController.text.trim();

//       await FirebaseFirestore.instance.collection('daily_bread').add({
//         'verse': verse,
//         'reference': ref,
//         'imageUrl': _imageUrlController.text.trim(),
//         'created_at': FieldValue.serverTimestamp(),
//       });

//       if (_sendNotification) {
//         await sendNotificationRecord(
//           title: 'Daily Bread Updated',
//           body: '$ref: "$verse"',
//           category: 'daily_bread',
//         );
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Daily Bread added successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error adding Daily Bread: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Add Daily Bread',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: ccmBlue,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [ccmBlue.withValues(alpha: 0.05), ccmWhite],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _verseController,
//                   maxLines: 6,
//                   decoration: InputDecoration(
//                     labelText: 'Bible Verse',
//                     hintText: 'Enter the bible verse text...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmBlue, width: 2),
//                     ),
//                     alignLabelWithHint: true,
//                   ),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _referenceController,
//                   decoration: InputDecoration(
//                     labelText: 'Bible Reference',
//                     hintText: 'e.g., John 3:16',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmBlue, width: 2),
//                     ),
//                     prefixIcon: const Icon(Icons.book, color: ccmBlue),
//                   ),
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Required' : null,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _imageUrlController,
//                   decoration: InputDecoration(
//                     labelText: 'Image URL (Optional)',
//                     hintText: 'https://example.com/image.jpg',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: ccmBlue, width: 2),
//                     ),
//                     prefixIcon: const Icon(Icons.image, color: ccmBlue),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 CheckboxListTile(
//                   value: _sendNotification,
//                   onChanged: (val) =>
//                       setState(() => _sendNotification = val ?? false),
//                   title: const Text('Send notification to members'),
//                   activeColor: ccmBlue,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: ccmBlue,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: _isSubmitting ? null : _submitDailyBread,
//                     icon: _isSubmitting
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 ccmWhite,
//                               ),
//                             ),
//                           )
//                         : const Icon(Icons.save),
//                     label: Text(
//                       _isSubmitting ? 'Saving...' : 'Post Daily Bread',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: ccmWhite,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _verseController.dispose();
//     _referenceController.dispose();
//     _imageUrlController.dispose();
//     super.dispose();
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/app_colors.dart';
import 'config/firebase_options.dart';
import 'core/app_feature_store.dart';
import 'screens/landing/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await appFeatureStore.load();

  runApp(const CCMApp());
}

class CCMApp extends StatelessWidget {
  const CCMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CCM',
      theme: buildCcmTheme(),
      home: const WelcomeScreen(),
    );
  }
}
