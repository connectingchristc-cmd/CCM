import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

String? firebaseInitError;

const _adminUsername = 'CCMAdmin';
const _adminPassword = 'CCMAdmin@2026';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    firebaseInitError = e.toString();
    debugPrint('Firebase init error: $firebaseInitError');
  }
  runApp(const CCMMelodiesApp());
}

class CCMMelodiesApp extends StatelessWidget {
  const CCMMelodiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCM Melodies',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTeluguTextTheme(),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note_rounded, size: 88, color: colors.primary),
                  const SizedBox(height: 28),
                  Text(
                    'WELCOME\nTO\nCONNECTING CHRIST MELODIES',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A place to discover and share songs of faith.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                      ),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('CCM Admin'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SongListScreen(isAdmin: false)),
                      ),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('CCM Member'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    if (_usernameController.text.trim() == _adminUsername &&
        _passwordController.text == _adminPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SongListScreen(isAdmin: true)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid admin username or password.')),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CCM Admin Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings, size: 72),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter admin username'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter admin password'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
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

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCM Melodies', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search songs (Telugu or English)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: Firebase.apps.isEmpty
                ? Center(
                    child: Text(
                      firebaseInitError == null
                          ? 'Firebase is not connected.'
                          : 'Firebase connection error:\n$firebaseInitError',
                      textAlign: TextAlign.center,
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('songs')
                        .orderBy('title_english')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final filtered = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final eng = (data['title_english'] ?? '').toString().toLowerCase();
                        final tel = (data['title_telugu'] ?? '').toString().toLowerCase();
                        return eng.contains(_searchQuery) || tel.contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('No songs found. Add your first song!'));
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final song = filtered[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                (song['title_english'] ?? 'A')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              song['title_telugu'] ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(song['title_english'] ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LyricViewScreen(song: song)),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Add Song'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddSongScreen()),
              ),
            )
          : null,
    );
  }
}

// ---------------- LYRIC VIEWER SCREEN ----------------
class LyricViewScreen extends StatefulWidget {
  final Map<String, dynamic> song;
  const LyricViewScreen({super.key, required this.song});

  @override
  State<LyricViewScreen> createState() => _LyricViewScreenState();
}

class _LyricViewScreenState extends State<LyricViewScreen> {
  double _fontSize = 18.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song['title_english'] ?? 'Lyrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(14.0, 32.0)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(14.0, 32.0)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.song['title_telugu'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            SelectableText(
              widget.song['lyrics'] ?? '',
              style: TextStyle(fontSize: _fontSize, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ADD SONG FORM ----------------
class AddSongScreen extends StatefulWidget {
  const AddSongScreen({super.key});

  @override
  State<AddSongScreen> createState() => _AddSongScreenState();
}

class _AddSongScreenState extends State<AddSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _engTitleController = TextEditingController();
  final _telTitleController = TextEditingController();
  final _lyricsController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitSong() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('songs').add({
        'title_english': _engTitleController.text.trim(),
        'title_telugu': _telTitleController.text.trim(),
        'lyrics': _lyricsController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding song: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Song')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _engTitleController,
                decoration: const InputDecoration(
                  labelText: 'Title in English (e.g. Aaradhana Neeke)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telTitleController,
                decoration: const InputDecoration(
                  labelText: 'Title in Telugu (e.g. ఆరాధన నీకే)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lyricsController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Song Lyrics (Telugu script)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSong,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Save & Publish Song', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}