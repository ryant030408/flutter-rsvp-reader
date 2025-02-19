// lib/screens/book_reader_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:epubx/epubx.dart';

import 'package:rsvp_reader/models/book_entry.dart';
import 'package:rsvp_reader/services/library_service.dart';
import 'package:rsvp_reader/widgets/rsvp_reader.dart';

class BookReaderScreen extends StatefulWidget {
  final BookEntry book;

  const BookReaderScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  bool _isLoading = false;
  EpubBook? _epubBook;

  late List<List<String>> chapterWords;
  late List<int> chapterWordCounts;
  int totalBookWords = 0;

  late int _currentChapterIndex;
  late int _currentWordIndex;
  late int _currentWpm;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.book.lastChapterIndex;
    _currentWordIndex = widget.book.lastWordIndex;
    _currentWpm = widget.book.currentWpm;
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    setState(() => _isLoading = true);

    try {
      final bytes = await _readBytes(widget.book.path);
      if (bytes == null) {
        throw Exception('No file bytes for ${widget.book.path}');
      }

      _epubBook = await EpubReader.readBook(bytes);
      final chapters = _epubBook!.Chapters ?? <EpubChapter>[];

      chapterWords = [];
      chapterWordCounts = [];
      totalBookWords = 0;

      for (var c in chapters) {
        String text = _extractChapterText(c);
        // strip HTML tags:
        text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
        final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

        chapterWords.add(words);
        chapterWordCounts.add(words.length);
        totalBookWords += words.length;
      }

      // clamp if needed
      if (_currentChapterIndex >= chapterWords.length) {
        _currentChapterIndex = 0;
      }
      if (_currentWordIndex >= chapterWords[_currentChapterIndex].length) {
        _currentWordIndex = 0;
      }
    } catch (e, st) {
      debugPrint('Error loading EPUB: $e\n$st');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Uint8List?> _readBytes(String path) async {
    if (path.startsWith('assets/')) {
      final bd = await rootBundle.load(path);
      return bd.buffer.asUint8List();
    } else if (path.startsWith('_inMemory_')) {
      // if you're on web or in-memory, handle that if needed
      return null;
    } else {
      // local file
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    return null;
  }

  String _extractChapterText(EpubChapter chapter) {
    String text = chapter.HtmlContent ?? '';
    for (var sub in chapter.SubChapters ?? <EpubChapter>[]) {
      text += _extractChapterText(sub);
    }
    return text;
  }

  void _onWordIndexChanged(int idx) {
    _currentWordIndex = idx;
    _saveProgress();
  }

  void _onWpmChanged(int newWpm) {
    _currentWpm = newWpm;
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    widget.book.lastChapterIndex = _currentChapterIndex;
    widget.book.lastWordIndex = _currentWordIndex;
    widget.book.currentWpm = _currentWpm;

    final library = await LibraryService.loadLibrary();
    final i = library.indexWhere((b) => b.id == widget.book.id);
    if (i != -1) {
      library[i] = widget.book;
      await LibraryService.saveLibrary(library);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_epubBook == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(child: Text('Failed to load EPUB')),
      );
    }

    final words = chapterWords[_currentChapterIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: RsvpReader(
        words: words,
        initialWpm: _currentWpm,
        onWordIndexChanged: _onWordIndexChanged,
        onWpmChanged: _onWpmChanged,
      ),
    );
  }
}