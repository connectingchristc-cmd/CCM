import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_colors.dart';
import '../admin/daily_devotion_manage_screen.dart';

class DailyBreadScreen extends StatefulWidget {
  final bool isAdmin;
  const DailyBreadScreen({super.key, required this.isAdmin});

  @override
  State<DailyBreadScreen> createState() => _DailyBreadScreenState();
}

enum _Testament { old, newTestament }
enum _BibleLanguage { english, telugu }

class _DailyBreadScreenState extends State<DailyBreadScreen> {
  late Future<List<_BibleChapter>> _chaptersFuture;
  _Testament _selectedTestament = _Testament.old;
  _BibleLanguage _selectedLanguage = _BibleLanguage.english;
  String? _selectedBook;
  int? _selectedChapter;
  final TextEditingController _referenceController = TextEditingController();
  String _referenceMessage = '';
  String _bibleSourceText = 'Loading Bible...';

  @override
  void initState() {
    super.initState();
    _chaptersFuture = _loadBibleData();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<List<_BibleChapter>> _loadBibleData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('offline_bible_chapters')
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        final chapters = snapshot.docs
            .map((doc) => _BibleChapter.fromMap(doc.data()))
            .toList();
        chapters.sort((a, b) {
          final testamentCmp = a.testament.compareTo(b.testament);
          if (testamentCmp != 0) return testamentCmp;
          final bookCmp = a.book.compareTo(b.book);
          if (bookCmp != 0) return bookCmp;
          return a.chapter.compareTo(b.chapter);
        });
        _bibleSourceText = 'Source: Imported by admin';
        return chapters;
      }
    } catch (_) {
      // Fall through to bundled asset.
    }

    _bibleSourceText = 'Source: Bundled sample offline Bible';
    return _loadOfflineBible();
  }

  Future<List<_BibleChapter>> _loadOfflineBible() async {
    final raw = await rootBundle.loadString('assets/offline_bible_te_en.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final chapters = (decoded['chapters'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_BibleChapter.fromMap)
        .toList();
    return chapters;
  }

  DateTime? _parseDevotionDate(Map<String, dynamic> data) {
    final raw = data['devotionDate']?.toString().trim() ?? '';
    if (raw.isNotEmpty) {
      final ddmmyyyy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(raw);
      if (ddmmyyyy != null) {
        final day = int.parse(ddmmyyyy.group(1)!);
        final month = int.parse(ddmmyyyy.group(2)!);
        final year = int.parse(ddmmyyyy.group(3)!);
        return DateTime(year, month, day);
      }

      final iso = DateTime.tryParse(raw);
      if (iso != null) {
        return DateTime(iso.year, iso.month, iso.day);
      }
    }

    final createdAt = data['created_at'];
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      return DateTime(d.year, d.month, d.day);
    }
    return null;
  }

  bool _isInLast7Days(DateTime date) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = end.subtract(const Duration(days: 6));
    return !date.isBefore(start) && !date.isAfter(end);
  }

  List<_BibleBookMeta> _booksForTestament() {
    return _bibleBooks
        .where((b) => b.testament == _selectedTestament.name)
        .toList(growable: false);
  }

  _BibleBookMeta? _selectedBookMeta(List<_BibleBookMeta> books) {
    if (books.isEmpty) return null;
    if (_selectedBook == null) return books.first;
    for (final b in books) {
      if (b.book == _selectedBook) return b;
    }
    return books.first;
  }

  Map<String, _BibleChapter> _chapterIndex(List<_BibleChapter> chapters) {
    final map = <String, _BibleChapter>{};
    for (final chapter in chapters) {
      map[_chapterKey(chapter.testament, chapter.book, chapter.chapter)] = chapter;
    }
    return map;
  }

  String _chapterKey(String testament, String book, int chapter) {
    return '${testament.toLowerCase()}|${_normalizeBook(book)}|$chapter';
  }

  String _normalizeBook(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  void _jumpToReference() {
    final input = _referenceController.text.trim();
    if (input.isEmpty) {
      setState(() => _referenceMessage = 'Enter a reference like John 1:1');
      return;
    }

    final match = RegExp(r'^(.+?)\s+(\d+)(?::\d+)?$').firstMatch(input);
    if (match == null) {
      setState(() => _referenceMessage = 'Invalid format. Example: John 1:1');
      return;
    }

    final rawBook = match.group(1)!.trim();
    final chapter = int.tryParse(match.group(2)!);
    if (chapter == null || chapter <= 0) {
      setState(() => _referenceMessage = 'Invalid chapter number.');
      return;
    }

    final normalizedBook = _normalizeBook(rawBook);
    _BibleBookMeta? target;
    for (final book in _bibleBooks) {
      if (_normalizeBook(book.book) == normalizedBook) {
        target = book;
        break;
      }
    }
    if (target == null) {
      setState(() => _referenceMessage = 'Book not found.');
      return;
    }
    final resolvedTarget = target;
    if (chapter > resolvedTarget.chapters) {
      setState(() => _referenceMessage = 'Chapter out of range for ${resolvedTarget.book}.');
      return;
    }

    setState(() {
      _selectedTestament = resolvedTarget.testament == 'old'
          ? _Testament.old
          : _Testament.newTestament;
      _selectedBook = resolvedTarget.book;
      _selectedChapter = chapter;
      _referenceMessage = 'Jumped to ${resolvedTarget.book} $chapter';
    });
  }

  Future<void> _importBibleJsonFromDevice() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final rawChapters = (decoded['chapters'] as List<dynamic>?) ?? const [];
      final chapters = rawChapters
          .cast<Map<String, dynamic>>()
          .map(_BibleChapter.fromMap)
          .toList();

      if (chapters.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No chapters found in JSON file.')),
        );
        return;
      }

      await _replaceBibleInFirestore(chapters);

      if (!mounted) return;
      setState(() {
        _chaptersFuture = _loadBibleData();
      });

      messenger.showSnackBar(
        SnackBar(content: Text('Bible import completed (${chapters.length} chapters).')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  Future<void> _replaceBibleInFirestore(List<_BibleChapter> chapters) async {
    final collection = FirebaseFirestore.instance.collection('offline_bible_chapters');

    final existing = await collection.get();
    final existingDocs = existing.docs;

    for (var i = 0; i < existingDocs.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      final end = (i + 400 < existingDocs.length) ? i + 400 : existingDocs.length;
      for (var j = i; j < end; j++) {
        batch.delete(existingDocs[j].reference);
      }
      await batch.commit();
    }

    for (var i = 0; i < chapters.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      final end = (i + 400 < chapters.length) ? i + 400 : chapters.length;
      for (var j = i; j < end; j++) {
        final chapter = chapters[j];
        final id = _chapterKey(chapter.testament, chapter.book, chapter.chapter);
        final ref = collection.doc(id);
        batch.set(ref, {
          'testament': chapter.testament,
          'book': chapter.book,
          'chapter': chapter.chapter,
          'english': chapter.english.map((k, v) => MapEntry(k.toString(), v)),
          'telugu': chapter.telugu.map((k, v) => MapEntry(k.toString(), v)),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Daily Bread',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            if (widget.isAdmin)
              IconButton(
                tooltip: 'Import Bible JSON',
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: _importBibleJsonFromDevice,
              ),
            if (widget.isAdmin)
              IconButton(
                tooltip: 'Manage Daily Devotion',
                icon: const Icon(Icons.add),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyDevotionManageScreen()),
                ),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Weekly Devotions'),
              Tab(text: 'Telugu & English Bible'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                const _SectionTitle('Weekly Devotions (Last 7 Days)'),
                const SizedBox(height: 8),
                const Text(
                  'Available online and offline from Firestore cache.',
                  style: TextStyle(color: ccmMutedInk, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _buildWeeklyDevotions(),
              ],
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                const _SectionTitle('Telugu & English Bible'),
                const SizedBox(height: 8),
                const Text(
                  'Available online via imported chapters and offline via cache or bundled file.',
                  style: TextStyle(color: ccmMutedInk, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _buildOfflineBible(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyDevotions() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('daily_devotions')
          .where('enabled', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SimpleMessageCard('Unable to load Daily Bread: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: ccmRed)),
          );
        }

        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aOrder = (aData['sortOrder'] ?? 9999) as num;
            final bOrder = (bData['sortOrder'] ?? 9999) as num;
            if (aOrder != bOrder) return aOrder.compareTo(bOrder);
            final aDate = _parseDevotionDate(aData);
            final bDate = _parseDevotionDate(bData);
            if (aDate != null && bDate != null) {
              return bDate.compareTo(aDate);
            }
            return 0;
          });

        final weekly = docs.where((doc) {
          final date = _parseDevotionDate(doc.data());
          if (date == null) return false;
          return _isInLast7Days(date);
        }).toList();

        if (weekly.isEmpty) {
          return const _SimpleMessageCard('No Daily Bread added in the last 7 days.');
        }

        return Column(
          children: [
            for (var i = 0; i < weekly.length; i++) ...[
              _BreadCard(data: weekly[i].data()),
              if (i != weekly.length - 1) const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOfflineBible() {
    return FutureBuilder<List<_BibleChapter>>(
      future: _chaptersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SimpleMessageCard('Offline Bible failed to load.');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator(color: ccmRed)),
          );
        }

        final all = snapshot.data ?? const <_BibleChapter>[];
        final index = _chapterIndex(all);
        final books = _booksForTestament();
        final selectedBook = _selectedBookMeta(books);
        if (selectedBook == null) {
          return const _SimpleMessageCard('Offline Bible content not available.');
        }
        final chapterCount = selectedBook.chapters;
        final chapterOptions = List<int>.generate(chapterCount, (i) => i + 1);
        final selectedChapter = (_selectedChapter != null &&
                _selectedChapter! >= 1 &&
                _selectedChapter! <= chapterCount)
            ? _selectedChapter!
            : 1;
        final selectedFromData = index[
          _chapterKey(_selectedTestament.name, selectedBook.book, selectedChapter)
        ];
        final verses = _selectedLanguage == _BibleLanguage.english
            ? selectedFromData?.english
            : selectedFromData?.telugu;

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Old Testament'),
                      selected: _selectedTestament == _Testament.old,
                      onSelected: (_) {
                        setState(() {
                          _selectedTestament = _Testament.old;
                          _selectedBook = null;
                          _selectedChapter = null;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('New Testament'),
                      selected: _selectedTestament == _Testament.newTestament,
                      onSelected: (_) {
                        setState(() {
                          _selectedTestament = _Testament.newTestament;
                          _selectedBook = null;
                          _selectedChapter = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('English'),
                      selected: _selectedLanguage == _BibleLanguage.english,
                      onSelected: (_) {
                        setState(() => _selectedLanguage = _BibleLanguage.english);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Telugu'),
                      selected: _selectedLanguage == _BibleLanguage.telugu,
                      onSelected: (_) {
                        setState(() => _selectedLanguage = _BibleLanguage.telugu);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: 'Jump to reference',
                    hintText: 'Example: John 1:1',
                    suffixIcon: IconButton(
                      onPressed: _jumpToReference,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                  onSubmitted: (_) => _jumpToReference(),
                ),
                if (_referenceMessage.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _referenceMessage,
                    style: const TextStyle(color: ccmMutedInk, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedBook.book,
                  decoration: const InputDecoration(labelText: 'Book'),
                  items: books
                      .map((book) => DropdownMenuItem(value: book.book, child: Text(book.book)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedBook = value;
                      _selectedChapter = 1;
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: selectedChapter,
                  decoration: const InputDecoration(labelText: 'Chapter'),
                  items: chapterOptions
                      .map((ch) => DropdownMenuItem(value: ch, child: Text(ch.toString())))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedChapter = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  '${selectedBook.book} $selectedChapter',
                  style: const TextStyle(
                    color: ccmInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _bibleSourceText,
                  style: const TextStyle(color: ccmMutedInk, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (verses == null || verses.isEmpty)
                  const Text(
                    'Offline text for this chapter is not added yet.\nAdd licensed Telugu and English Bible JSON for full coverage.',
                    style: TextStyle(color: ccmMutedInk, height: 1.4),
                  )
                else
                  for (final entry in verses.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${entry.key}. ${entry.value}',
                        style: const TextStyle(color: ccmMutedInk, height: 1.4),
                      ),
                    ),
                const SizedBox(height: 8),
                const Divider(height: 18),
                const Text(
                  'Bible Reading Plans',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text('1. 7-Day Faith Starter: John 1-7'),
                const Text('2. 30-Day Psalms Journey: Psalms 1-30'),
                const Text('3. Gospel Walk: Matthew, Mark, Luke, John'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BreadCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BreadCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl']?.toString() ?? '';
    final devotionDate = data['devotionDate']?.toString() ?? '';
    return Card(
      elevation: 5,
      shadowColor: const Color(0x55493828),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.white.withValues(alpha: .75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ColoredBox(
                      color: Color(0xff2b2632),
                      child: Center(
                        child: Icon(Icons.auto_stories_outlined, color: ccmWhite, size: 46),
                      ),
                    ),
                  )
                : const ColoredBox(
                    color: Color(0xff2b2632),
                    child: Center(
                      child: Icon(Icons.auto_stories_outlined, color: ccmWhite, size: 46),
                    ),
                  ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              color: Colors.black.withValues(alpha: .32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  final shareText = [
                    'Daily Devotion',
                    if (devotionDate.isNotEmpty) devotionDate,
                    if (imageUrl.isNotEmpty) imageUrl,
                  ].join('\n');
                  await SharePlus.instance.share(
                    ShareParams(
                      text: shareText,
                      subject: 'CCM Daily Devotion',
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.share_outlined, color: ccmWhite, size: 18),
                ),
              ),
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xff642d25),
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SimpleMessageCard extends StatelessWidget {
  final String text;
  const _SimpleMessageCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _BibleChapter {
  final String testament;
  final String book;
  final int chapter;
  final Map<int, String> english;
  final Map<int, String> telugu;

  const _BibleChapter({
    required this.testament,
    required this.book,
    required this.chapter,
    required this.english,
    required this.telugu,
  });

  factory _BibleChapter.fromMap(Map<String, dynamic> map) {
    final en = (map['english'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(int.parse(k), v.toString()),
    );
    final te = (map['telugu'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(int.parse(k), v.toString()),
    );
    return _BibleChapter(
      testament: map['testament'].toString(),
      book: map['book'].toString(),
      chapter: (map['chapter'] as num).toInt(),
      english: en,
      telugu: te,
    );
  }
}

class _BibleBookMeta {
  final String testament;
  final String book;
  final int chapters;

  const _BibleBookMeta({
    required this.testament,
    required this.book,
    required this.chapters,
  });
}

const List<_BibleBookMeta> _bibleBooks = [
  _BibleBookMeta(testament: 'old', book: 'Genesis', chapters: 50),
  _BibleBookMeta(testament: 'old', book: 'Exodus', chapters: 40),
  _BibleBookMeta(testament: 'old', book: 'Leviticus', chapters: 27),
  _BibleBookMeta(testament: 'old', book: 'Numbers', chapters: 36),
  _BibleBookMeta(testament: 'old', book: 'Deuteronomy', chapters: 34),
  _BibleBookMeta(testament: 'old', book: 'Joshua', chapters: 24),
  _BibleBookMeta(testament: 'old', book: 'Judges', chapters: 21),
  _BibleBookMeta(testament: 'old', book: 'Ruth', chapters: 4),
  _BibleBookMeta(testament: 'old', book: '1 Samuel', chapters: 31),
  _BibleBookMeta(testament: 'old', book: '2 Samuel', chapters: 24),
  _BibleBookMeta(testament: 'old', book: '1 Kings', chapters: 22),
  _BibleBookMeta(testament: 'old', book: '2 Kings', chapters: 25),
  _BibleBookMeta(testament: 'old', book: '1 Chronicles', chapters: 29),
  _BibleBookMeta(testament: 'old', book: '2 Chronicles', chapters: 36),
  _BibleBookMeta(testament: 'old', book: 'Ezra', chapters: 10),
  _BibleBookMeta(testament: 'old', book: 'Nehemiah', chapters: 13),
  _BibleBookMeta(testament: 'old', book: 'Esther', chapters: 10),
  _BibleBookMeta(testament: 'old', book: 'Job', chapters: 42),
  _BibleBookMeta(testament: 'old', book: 'Psalms', chapters: 150),
  _BibleBookMeta(testament: 'old', book: 'Proverbs', chapters: 31),
  _BibleBookMeta(testament: 'old', book: 'Ecclesiastes', chapters: 12),
  _BibleBookMeta(testament: 'old', book: 'Song of Solomon', chapters: 8),
  _BibleBookMeta(testament: 'old', book: 'Isaiah', chapters: 66),
  _BibleBookMeta(testament: 'old', book: 'Jeremiah', chapters: 52),
  _BibleBookMeta(testament: 'old', book: 'Lamentations', chapters: 5),
  _BibleBookMeta(testament: 'old', book: 'Ezekiel', chapters: 48),
  _BibleBookMeta(testament: 'old', book: 'Daniel', chapters: 12),
  _BibleBookMeta(testament: 'old', book: 'Hosea', chapters: 14),
  _BibleBookMeta(testament: 'old', book: 'Joel', chapters: 3),
  _BibleBookMeta(testament: 'old', book: 'Amos', chapters: 9),
  _BibleBookMeta(testament: 'old', book: 'Obadiah', chapters: 1),
  _BibleBookMeta(testament: 'old', book: 'Jonah', chapters: 4),
  _BibleBookMeta(testament: 'old', book: 'Micah', chapters: 7),
  _BibleBookMeta(testament: 'old', book: 'Nahum', chapters: 3),
  _BibleBookMeta(testament: 'old', book: 'Habakkuk', chapters: 3),
  _BibleBookMeta(testament: 'old', book: 'Zephaniah', chapters: 3),
  _BibleBookMeta(testament: 'old', book: 'Haggai', chapters: 2),
  _BibleBookMeta(testament: 'old', book: 'Zechariah', chapters: 14),
  _BibleBookMeta(testament: 'old', book: 'Malachi', chapters: 4),
  _BibleBookMeta(testament: 'new', book: 'Matthew', chapters: 28),
  _BibleBookMeta(testament: 'new', book: 'Mark', chapters: 16),
  _BibleBookMeta(testament: 'new', book: 'Luke', chapters: 24),
  _BibleBookMeta(testament: 'new', book: 'John', chapters: 21),
  _BibleBookMeta(testament: 'new', book: 'Acts', chapters: 28),
  _BibleBookMeta(testament: 'new', book: 'Romans', chapters: 16),
  _BibleBookMeta(testament: 'new', book: '1 Corinthians', chapters: 16),
  _BibleBookMeta(testament: 'new', book: '2 Corinthians', chapters: 13),
  _BibleBookMeta(testament: 'new', book: 'Galatians', chapters: 6),
  _BibleBookMeta(testament: 'new', book: 'Ephesians', chapters: 6),
  _BibleBookMeta(testament: 'new', book: 'Philippians', chapters: 4),
  _BibleBookMeta(testament: 'new', book: 'Colossians', chapters: 4),
  _BibleBookMeta(testament: 'new', book: '1 Thessalonians', chapters: 5),
  _BibleBookMeta(testament: 'new', book: '2 Thessalonians', chapters: 3),
  _BibleBookMeta(testament: 'new', book: '1 Timothy', chapters: 6),
  _BibleBookMeta(testament: 'new', book: '2 Timothy', chapters: 4),
  _BibleBookMeta(testament: 'new', book: 'Titus', chapters: 3),
  _BibleBookMeta(testament: 'new', book: 'Philemon', chapters: 1),
  _BibleBookMeta(testament: 'new', book: 'Hebrews', chapters: 13),
  _BibleBookMeta(testament: 'new', book: 'James', chapters: 5),
  _BibleBookMeta(testament: 'new', book: '1 Peter', chapters: 5),
  _BibleBookMeta(testament: 'new', book: '2 Peter', chapters: 3),
  _BibleBookMeta(testament: 'new', book: '1 John', chapters: 5),
  _BibleBookMeta(testament: 'new', book: '2 John', chapters: 1),
  _BibleBookMeta(testament: 'new', book: '3 John', chapters: 1),
  _BibleBookMeta(testament: 'new', book: 'Jude', chapters: 1),
  _BibleBookMeta(testament: 'new', book: 'Revelation', chapters: 22),
];
