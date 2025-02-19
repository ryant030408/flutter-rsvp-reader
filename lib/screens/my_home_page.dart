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

  // We'll store a list of word-lists, one for each chapter
  late List<List<String>> chapterWords;
  late List<int> chapterWordCounts;
  int totalBookWords = 0;

  // Current reading position in the current chapter
  int _currentChapterWordIndex = 0;

  // We'll track the WPM in the parent so we can do time estimates
  int _currentWpm = 300;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    setState(() => _isLoading = true);

    try {
      final book = await _epubService.loadEpub('assets/sample.epub');
      _epubBook = book;

      final chapters = book.Chapters ?? <EpubChapter>[];
      chapterWords = [];
      chapterWordCounts = [];
      totalBookWords = 0;

      for (var chapter in chapters) {
        final chapterText = _epubService.extractChapterText(chapter);
        final words = chapterText
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();

        chapterWords.add(words);
        chapterWordCounts.add(words.length);
      }

      totalBookWords = chapterWordCounts.fold(0, (sum, c) => sum + c);

      // Default to the first chapter
      _selectedChapterIndex = 0;
      _currentChapterWordIndex = 0;
    } catch (e, stack) {
      debugPrint('Failed to load EPUB: $e\n$stack');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Called by the RSVP widget every time the user moves to the next word
  void _onWordIndexChanged(int newIndex) {
    setState(() {
      _currentChapterWordIndex = newIndex;
    });
  }

  // Called by the RSVP widget if speed changes
  void _onWpmChanged(int newWpm) {
    setState(() {
      _currentWpm = newWpm;
    });
  }

  // Chapter drawer to pick chapters
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
                _currentChapterWordIndex = 0;
              });
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  // fraction (0..1) for the current chapter
  double get chapterProgress {
    if (_selectedChapterIndex == null) return 0.0;
    final chapterCount = chapterWordCounts[_selectedChapterIndex!];
    if (chapterCount == 0) return 0.0;
    return _currentChapterWordIndex / chapterCount;
  }

  // fraction (0..1) for the entire book
  double get bookProgress {
    if (_selectedChapterIndex == null) return 0.0;
    final chaptersSoFar = _selectedChapterIndex!;
    final wordsBeforeThisChapter = chapterWordCounts
        .take(chaptersSoFar)
        .fold(0, (sum, c) => sum + c);

    final totalWordsRead = wordsBeforeThisChapter + _currentChapterWordIndex;
    if (totalBookWords == 0) return 0.0;
    return totalWordsRead / totalBookWords;
  }

  // Estimate how long to finish the chapter at the current WPM
  Duration get chapterTimeLeft {
    if (_selectedChapterIndex == null) return Duration.zero;
    final chapterCount = chapterWordCounts[_selectedChapterIndex!];
    final wordsLeft = chapterCount - _currentChapterWordIndex;
    if (_currentWpm == 0) return Duration.zero;

    // wordsLeft / wpm = minutes, so multiply by 60 for seconds
    final minutes = wordsLeft / _currentWpm;
    final secs = (minutes * 60).round();
    return Duration(seconds: secs);
  }

  // Estimate how long to finish the entire book at current WPM
  Duration get bookTimeLeft {
    if (_selectedChapterIndex == null) return Duration.zero;
    final chaptersSoFar = _selectedChapterIndex!;
    final wordsBeforeThisChapter = chapterWordCounts
        .take(chaptersSoFar)
        .fold(0, (sum, c) => sum + c);

    final totalWordsRead = wordsBeforeThisChapter + _currentChapterWordIndex;
    final wordsLeft = totalBookWords - totalWordsRead;
    if (_currentWpm == 0) return Duration.zero;

    final minutes = wordsLeft / _currentWpm;
    final secs = (minutes * 60).round();
    return Duration(seconds: secs);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    return "$hours:${mins.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('RSVP Reader')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_epubBook == null || _selectedChapterIndex == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RSVP Reader')),
        body: const Center(child: Text('No EPUB or chapters available')),
      );
    }

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
            "Chapter progress: ${(chapterProgress * 100).toStringAsFixed(1)}%"
            "\nTime left in chapter: ${_formatDuration(chapterTimeLeft)}",
            textAlign: TextAlign.center,
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
            "Book progress: ${(bookProgress * 100).toStringAsFixed(1)}%"
            "\nTime left in book: ${_formatDuration(bookTimeLeft)}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),

          // The RSVP area
          Expanded(
            child: Center(
              child: RsvpReader(
                words: words,
                initialWpm: _currentWpm,
                onWordIndexChanged: _onWordIndexChanged,
                onWpmChanged: _onWpmChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}