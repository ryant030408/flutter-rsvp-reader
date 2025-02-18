// lib/screens/my_home_page.dart

import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';
import 'package:rsvp_reader/services/epub_service.dart';
import 'package:rsvp_reader/widgets/rsvp_reader.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final EpubService _epubService = EpubService();

  bool _isLoading = false;
  EpubBook? _epubBook;
  int? _selectedChapterIndex;

  // We'll store a list of word-lists, one for each chapter:
  late List<List<String>> chapterWords = [];

  // We'll store the total word count for each chapter:
  late List<int> chapterWordCounts = [];

  // We'll store the sum of all words in the book:
  int totalBookWords = 0;

  // This is the user’s current word index in the current chapter:
  int _currentChapterWordIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    setState(() => _isLoading = true);

    try {
      // Load the book
      final book = await _epubService.loadEpub('assets/sample.epub');
      _epubBook = book;

      // Build a word list for each chapter
      final chapters = book.Chapters ?? <EpubChapter>[];
      chapterWords = [];
      chapterWordCounts = [];
      totalBookWords = 0;

      for (var chapter in chapters) {
        final chapterText = _epubService.extractChapterText(chapter);
        final words = chapterText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

        chapterWords.add(words);
        chapterWordCounts.add(words.length);
      }

      // Sum them up for the entire book
      totalBookWords = chapterWordCounts.fold(0, (sum, count) => sum + count);

      // Select the first chapter by default (index 0)
      _selectedChapterIndex = 0;
      _currentChapterWordIndex = 0; // start at 0
    } catch (e, stack) {
      debugPrint('Failed to load EPUB: $e\n$stack');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // This is called when the RSVP widget reports a word index change.
  // We'll store the new index, so we can compute progress bars.
  void _onWordIndexChanged(int newIndex) {
    setState(() {
      _currentChapterWordIndex = newIndex;
    });
  }

  /// Builds the Drawer with the list of chapters so we can pick one.
  Widget _buildChapterDrawer() {
    if (_epubBook == null) {
      return const Drawer(child: Center(child: Text('No chapters loaded')));
    }

    final chapters = _epubBook!.Chapters ?? <EpubChapter>[];
    return Drawer(
      child: ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final chapterTitle = chapter.Title ?? 'Chapter ${index + 1}';
          return ListTile(
            title: Text(chapterTitle),
            onTap: () {
              setState(() {
                _selectedChapterIndex = index;
                // reset current word index to 0 whenever we pick a new chapter
                _currentChapterWordIndex = 0;
              });
              Navigator.of(context).pop(); // Close drawer
            },
          );
        },
      ),
    );
  }

  /// Compute the fraction (0.0 to 1.0) for the current chapter progress.
  double get chapterProgress {
    if (_selectedChapterIndex == null) return 0.0;
    final chapterCount = chapterWordCounts[_selectedChapterIndex!];
    if (chapterCount == 0) return 0.0;
    return _currentChapterWordIndex / chapterCount;
  }

  /// Compute the fraction for total book progress.
  double get bookProgress {
    if (_selectedChapterIndex == null) return 0.0;
    final chaptersSoFar = _selectedChapterIndex!; // number of completed chapters
    final wordsBeforeThisChapter = chapterWordCounts
        .take(chaptersSoFar) // sum of all chapters before the current one
        .fold(0, (sum, count) => sum + count);

    final totalWordsRead = wordsBeforeThisChapter + _currentChapterWordIndex;
    if (totalBookWords == 0) return 0.0;
    return totalWordsRead / totalBookWords;
  }

  @override
  Widget build(BuildContext context) {
    // Loading spinner
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('RSVP Reader')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If failed or still no data
    if (_epubBook == null || _selectedChapterIndex == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RSVP Reader')),
        body: const Center(child: Text('No EPUB or chapters available')),
      );
    }

    // Get the words for the currently selected chapter
    final words = chapterWords[_selectedChapterIndex!];

    return Scaffold(
      appBar: AppBar(title: const Text('RSVP Reader')),
      drawer: _buildChapterDrawer(),
      body: Column(
        children: [
          // Chapter progress bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: LinearProgressIndicator(
              value: chapterProgress,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
            ),
          ),
          Text(
            "Chapter progress: ${(chapterProgress * 100).toStringAsFixed(1)}%",
            style: const TextStyle(fontSize: 14),
          ),

          // Book progress bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: LinearProgressIndicator(
              value: bookProgress,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
          ),
          Text(
            "Book progress: ${(bookProgress * 100).toStringAsFixed(1)}%",
            style: const TextStyle(fontSize: 14),
          ),

          // The actual RSVP widget
          Expanded(
            child: Center(
              child: RsvpReader(
                words: words,
                initialWpm: 300,
                onWordIndexChanged: _onWordIndexChanged, // callback
              ),
            ),
          ),
        ],
      ),
    );
  }
}