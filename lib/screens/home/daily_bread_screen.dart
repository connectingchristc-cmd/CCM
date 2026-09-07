import 'dart:convert';
import 'dart:io';

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
enum _BibleDisplayMode { both, english, telugu }

class _DailyBreadScreenState extends State<DailyBreadScreen> {
  late Future<List<_BibleChapter>> _chaptersFuture;
  _Testament _selectedTestament = _Testament.old;
  _BibleDisplayMode _displayMode = _BibleDisplayMode.both;
  double _bibleFontSize = 19;
  String? _selectedBook;
  int? _selectedChapter;
  final TextEditingController _referenceController = TextEditingController();
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
    final selectedKey = _selectedTestament == _Testament.old ? 'old' : 'new';
    return _bibleBooks
      .where((b) => b.testament == selectedKey)
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
    final messenger = ScaffoldMessenger.of(context);
    final input = _referenceController.text.trim();
    if (input.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a reference like John 1:1')),
      );
      return;
    }

    final match = RegExp(r'^(.+?)\s+(\d+)(?::\d+)?$').firstMatch(input);
    if (match == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid format. Example: John 1:1')),
      );
      return;
    }

    final rawBook = match.group(1)!.trim();
    final chapter = int.tryParse(match.group(2)!);
    if (chapter == null || chapter <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid chapter number.')),
      );
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Book not found.')),
      );
      return;
    }
    final resolvedTarget = target;
    if (chapter > resolvedTarget.chapters) {
      messenger.showSnackBar(
        SnackBar(content: Text('Chapter out of range for ${resolvedTarget.book}.')),
      );
      return;
    }

    setState(() {
      _selectedTestament = resolvedTarget.testament == 'old'
          ? _Testament.old
          : _Testament.newTestament;
      _selectedBook = resolvedTarget.book;
      _selectedChapter = chapter;
    });

    messenger.showSnackBar(
      SnackBar(content: Text('Jumped to ${resolvedTarget.book} $chapter')),
    );
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
        final chapters = _decodeBibleChapters(decoded);

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

  List<_BibleChapter> _decodeBibleChapters(Map<String, dynamic> decoded) {
    final rawChapters = (decoded['chapters'] as List<dynamic>?) ?? const [];
    return rawChapters
        .cast<Map<String, dynamic>>()
        .map(_BibleChapter.fromMap)
        .toList();
  }

  Future<void> _importBibleJsonFromInternet() async {
    final messenger = ScaffoldMessenger.of(context);
    final urlController = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import Bible JSON from Internet'),
          content: TextField(
            controller: urlController,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'https://.../offline_bible_te_en.json',
            ),
            onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, urlController.text.trim()),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );

    final rawUrl = (url ?? '').trim();
    if (rawUrl.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https'))) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid http/https URL.')),
      );
      return;
    }

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final chapters = _decodeBibleChapters(decoded);

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
        SnackBar(content: Text('Internet import failed: $error')),
      );
    } finally {
      client?.close(force: true);
      urlController.dispose();
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
                tooltip: 'Import Bible JSON from Internet',
                icon: const Icon(Icons.cloud_download_outlined),
                onPressed: _importBibleJsonFromInternet,
              ),
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
                  'Telugu + English reading with offline cache and admin JSON import.',
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
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: CircularProgressIndicator(color: ccmRed),
            ),
          );
        }

        final all = snapshot.data ?? const <_BibleChapter>[];
        final index = _chapterIndex(all);
        final books = _booksForTestament();
        final selectedBook = _selectedBookMeta(books);

        if (selectedBook == null) {
          return const _SimpleMessageCard(
            'Offline Bible content not available.',
          );
        }

        final chapterCount = selectedBook.chapters;
        final chapterOptions = List<int>.generate(
          chapterCount,
          (index) => index + 1,
        );

        final selectedChapter = (_selectedChapter != null &&
                _selectedChapter! >= 1 &&
                _selectedChapter! <= chapterCount)
            ? _selectedChapter!
            : 1;

        final chapter = index[
          _chapterKey(
            _selectedTestament == _Testament.old ? 'old' : 'new',
            selectedBook.book,
            selectedChapter,
          )
        ];

        final english = chapter?.english ?? const <int, String>{};
        final telugu = chapter?.telugu ?? const <int, String>{};

        final verseNumbers = <int>{
          ...english.keys,
          ...telugu.keys,
        }.toList()
          ..sort();

        final bookLabel = _bookDisplayName(selectedBook.book);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBibleSelectorCard(
              selectedBook: selectedBook,
              selectedChapter: selectedChapter,
              chapterOptions: chapterOptions,
              bookLabel: bookLabel,
            ),
            const SizedBox(height: 18),
            _buildBibleReadingCard(
              bookLabel: bookLabel,
              chapterNumber: selectedChapter,
              english: english,
              telugu: telugu,
              verseNumbers: verseNumbers,
            ),
            const SizedBox(height: 14),
            _buildChapterNavigation(
              selectedBook: selectedBook,
              selectedChapter: selectedChapter,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _bibleSourceText,
                style: const TextStyle(
                  color: ccmMutedInk,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildBibleReadingPlans(),
          ],
        );
      },
    );
  }

  Widget _buildBibleSelectorCard({
    required _BibleBookMeta selectedBook,
    required int selectedChapter,
    required List<int> chapterOptions,
    required String bookLabel,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A2E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD4A72C).withValues(alpha: .28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              final testamentDropdown = _buildBibleDropdown<_Testament>(
                value: _selectedTestament,
                items: const [
                  DropdownMenuItem(
                    value: _Testament.old,
                    child: Text('Old Testament (పాత నిబంధన)'),
                  ),
                  DropdownMenuItem(
                    value: _Testament.newTestament,
                    child: Text('New Testament (క్రొత్త నిబంధన)'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedTestament = value;
                    _selectedBook = null;
                    _selectedChapter = 1;
                  });
                },
              );

              final bookDropdown = _buildBibleDropdown<String>(
                value: selectedBook.book,
                items: _booksForTestament()
                    .map(
                      (book) => DropdownMenuItem<String>(
                        value: book.book,
                        child: Text(
                          _bookDisplayName(book.book),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final book = _booksForTestament().firstWhere(
                    (item) => item.book == value,
                  );
                  setState(() {
                    _selectedBook = book.book;
                    _selectedChapter = 1;
                  });
                },
              );

              if (compact) {
                return Column(
                  children: [
                    testamentDropdown,
                    const SizedBox(height: 10),
                    bookDropdown,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: testamentDropdown),
                  const SizedBox(width: 12),
                  Expanded(child: bookDropdown),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Chapter $selectedChapter',
                style: const TextStyle(
                  color: Color(0xFFF5C451),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _buildFontButton(
                label: 'A+',
                onPressed: () {
                  setState(() {
                    _bibleFontSize = (_bibleFontSize + 1).clamp(15, 28);
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildFontButton(
                label: 'A−',
                onPressed: () {
                  setState(() {
                    _bibleFontSize = (_bibleFontSize - 1).clamp(15, 28);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Display',
                style: TextStyle(
                  color: Color(0xFFB8C4D8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDisplayChip(
                        label: 'Both',
                        mode: _BibleDisplayMode.both,
                      ),
                      const SizedBox(width: 6),
                      _buildDisplayChip(
                        label: 'English',
                        mode: _BibleDisplayMode.english,
                      ),
                      const SizedBox(width: 6),
                      _buildDisplayChip(
                        label: 'తెలుగు',
                        mode: _BibleDisplayMode.telugu,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedChapter,
                  isExpanded: true,
                  decoration: _bibleInputDecoration('Chapter'),
                  dropdownColor: const Color(0xFFF5EEE5),
                  items: chapterOptions
                      .map(
                        (chapter) => DropdownMenuItem<int>(
                          value: chapter,
                          child: Text('Chapter $chapter'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedChapter = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Search reference',
                onPressed: _showReferenceSearch,
                icon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFF5C451),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBibleReadingCard({
    required String bookLabel,
    required int chapterNumber,
    required Map<int, String> english,
    required Map<int, String> telugu,
    required List<int> verseNumbers,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111A2E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD4A72C).withValues(alpha: .28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: verseNumbers.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'This chapter is not available yet.\n'
                'Please import licensed Telugu and English Bible JSON.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9AA9C2),
                  height: 1.5,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFF5C451),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$bookLabel • Chapter $chapterNumber',
                      style: const TextStyle(
                        color: Color(0xFFF5C451),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < verseNumbers.length; i++) ...[
                  _buildVerse(
                    verseNumber: verseNumbers[i],
                    english: english[verseNumbers[i]],
                    telugu: telugu[verseNumbers[i]],
                  ),
                  if (i != verseNumbers.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        color: const Color(0xFF70809A).withValues(alpha: .18),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildVerse({
    required int verseNumber,
    required String? english,
    required String? telugu,
  }) {
    final showTelugu = _displayMode == _BibleDisplayMode.both ||
        _displayMode == _BibleDisplayMode.telugu;
    final showEnglish = _displayMode == _BibleDisplayMode.both ||
        _displayMode == _BibleDisplayMode.english;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTelugu && telugu != null && telugu.trim().isNotEmpty)
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: _bibleFontSize,
                height: 1.65,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: '$verseNumber. ',
                  style: const TextStyle(
                    color: Color(0xFFF5C451),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(text: telugu.trim()),
              ],
            ),
          ),
        if (showTelugu &&
            showEnglish &&
            telugu != null &&
            telugu.trim().isNotEmpty &&
            english != null &&
            english.trim().isNotEmpty)
          const SizedBox(height: 12),
        if (showEnglish && english != null && english.trim().isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: showTelugu ? 2 : 0,
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: const Color(0xFFAAB7CB),
                  fontSize: (_bibleFontSize - 2).clamp(13, 26),
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  if (!showTelugu)
                    TextSpan(
                      text: '$verseNumber. ',
                      style: const TextStyle(
                        color: Color(0xFFF5C451),
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  TextSpan(text: english.trim()),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChapterNavigation({
    required _BibleBookMeta selectedBook,
    required int selectedChapter,
  }) {
    final canGoPrevious = selectedChapter > 1 ||
        _booksForTestament().indexWhere(
              (book) => book.book == selectedBook.book,
            ) >
            0;

    final canGoNext = selectedChapter < selectedBook.chapters ||
        _booksForTestament().indexWhere(
              (book) => book.book == selectedBook.book,
            ) <
            _booksForTestament().length - 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canGoPrevious ? _goToPreviousChapter : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ccmBlue,
              side: BorderSide(
                color: ccmBlue.withValues(alpha: .45),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canGoNext ? _goToNextChapter : null,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ccmBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBibleReadingPlans() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ccmSandDark.withValues(alpha: .45),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bible Reading Plans',
            style: TextStyle(
              color: ccmInk,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text('1. 7-Day Faith Starter: John 1–7'),
          Text('2. 30-Day Psalms Journey: Psalms 1–30'),
          Text('3. Gospel Walk: Matthew, Mark, Luke, John'),
        ],
      ),
    );
  }

  Widget _buildBibleDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: const Color(0xFFF5EEE5),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF33445E),
      ),
      style: const TextStyle(
        color: Color(0xFF263A58),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: _bibleInputDecoration(null),
      items: items,
      onChanged: onChanged,
    );
  }

  InputDecoration _bibleInputDecoration(String? label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4F5F7),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFBAC4D1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFBAC4D1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFD4A72C),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildFontButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: const Color(0xFFE8ECF2),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2C5B8D),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayChip({
    required String label,
    required _BibleDisplayMode mode,
  }) {
    final selected = _displayMode == mode;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _displayMode = mode;
        });
      },
      selectedColor: const Color(0xFFD4A72C),
      backgroundColor: const Color(0xFFE8ECF2),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF111A2E) : const Color(0xFF40516B),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  void _showReferenceSearch() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Go to Bible Reference'),
          content: TextField(
            controller: _referenceController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Example: John 1:1',
            ),
            onSubmitted: (_) {
              Navigator.pop(dialogContext);
              _jumpToReference();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _jumpToReference();
              },
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  void _goToPreviousChapter() {
    final books = _booksForTestament();
    final currentIndex = books.indexWhere(
      (book) => book.book == _selectedBookMeta(books)?.book,
    );

    final currentChapter = _selectedChapter ?? 1;

    if (currentChapter > 1) {
      setState(() {
        _selectedChapter = currentChapter - 1;
      });
      return;
    }

    if (currentIndex > 0) {
      final previousBook = books[currentIndex - 1];
      setState(() {
        _selectedBook = previousBook.book;
        _selectedChapter = previousBook.chapters;
      });
    }
  }

  void _goToNextChapter() {
    final books = _booksForTestament();
    final currentBook = _selectedBookMeta(books);
    if (currentBook == null) return;

    final currentIndex = books.indexWhere(
      (book) => book.book == currentBook.book,
    );

    final currentChapter = _selectedChapter ?? 1;

    if (currentChapter < currentBook.chapters) {
      setState(() {
        _selectedChapter = currentChapter + 1;
      });
      return;
    }

    if (currentIndex >= 0 && currentIndex < books.length - 1) {
      final nextBook = books[currentIndex + 1];
      setState(() {
        _selectedBook = nextBook.book;
        _selectedChapter = 1;
      });
    }
  }

  String _bookDisplayName(String englishName) {
    return '$englishName (${_teluguBookNames[englishName] ?? ''})';
  }

  static const Map<String, String> _teluguBookNames = {
    'Genesis': 'ఆదికాండము',
    'Exodus': 'నిర్గమకాండము',
    'Leviticus': 'లేవీయకాండము',
    'Numbers': 'సంఖ్యాకాండము',
    'Deuteronomy': 'ద్వితీయోపదేశకాండము',
    'Joshua': 'యెహోషువ',
    'Judges': 'న్యాయాధిపతులు',
    'Ruth': 'రూతు',
    '1 Samuel': '1 సమూయేలు',
    '2 Samuel': '2 సమూయేలు',
    '1 Kings': '1 రాజులు',
    '2 Kings': '2 రాజులు',
    '1 Chronicles': '1 దినవృత్తాంతములు',
    '2 Chronicles': '2 దినవృత్తాంతములు',
    'Ezra': 'ఎజ్రా',
    'Nehemiah': 'నెహెమ్యా',
    'Esther': 'ఎస్తేరు',
    'Job': 'యోబు',
    'Psalms': 'కీర్తనలు',
    'Proverbs': 'సామెతలు',
    'Ecclesiastes': 'ప్రసంగి',
    'Song of Solomon': 'పరమగీతము',
    'Isaiah': 'యెషయా',
    'Jeremiah': 'యిర్మీయా',
    'Lamentations': 'విలాపవాక్యములు',
    'Ezekiel': 'యెహెజ్కేలు',
    'Daniel': 'దానియేలు',
    'Hosea': 'హోషేయ',
    'Joel': 'యోవేలు',
    'Amos': 'ఆమోసు',
    'Obadiah': 'ఓబద్యా',
    'Jonah': 'యోనా',
    'Micah': 'మీకా',
    'Nahum': 'నహూము',
    'Habakkuk': 'హబక్కూకు',
    'Zephaniah': 'జెఫన్యా',
    'Haggai': 'హగ్గయి',
    'Zechariah': 'జెకర్యా',
    'Malachi': 'మలాకీ',
    'Matthew': 'మత్తయి',
    'Mark': 'మార్కు',
    'Luke': 'లూకా',
    'John': 'యోహాను',
    'Acts': 'అపొస్తలుల కార్యములు',
    'Romans': 'రోమీయులకు',
    '1 Corinthians': '1 కొరింథీయులకు',
    '2 Corinthians': '2 కొరింథీయులకు',
    'Galatians': 'గలతీయులకు',
    'Ephesians': 'ఎఫెసీయులకు',
    'Philippians': 'ఫిలిప్పీయులకు',
    'Colossians': 'కొలొస్సయులకు',
    '1 Thessalonians': '1 థెస్సలొనీకయులకు',
    '2 Thessalonians': '2 థెస్సలొనీకయులకు',
    '1 Timothy': '1 తిమోతికి',
    '2 Timothy': '2 తిమోతికి',
    'Titus': 'తీతుకు',
    'Philemon': 'ఫిలేమోనుకు',
    'Hebrews': 'హెబ్రీయులకు',
    'James': 'యాకోబు',
    '1 Peter': '1 పేతురు',
    '2 Peter': '2 పేతురు',
    '1 John': '1 యోహాను',
    '2 John': '2 యోహాను',
    '3 John': '3 యోహాను',
    'Jude': 'యూదా',
    'Revelation': 'ప్రకటన గ్రంథము',
  };

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
    final rawTestament = map['testament']?.toString().trim().toLowerCase() ?? 'old';
    final normalizedTestament = rawTestament.startsWith('new') ? 'new' : 'old';
    return _BibleChapter(
      testament: normalizedTestament,
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
