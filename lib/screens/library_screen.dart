// lib/screens/library_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:rsvp_reader/models/book_entry.dart';
import 'package:rsvp_reader/screens/book_reader_screen.dart';
import 'package:rsvp_reader/services/library_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<BookEntry> _library = [];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final books = await LibraryService.loadLibrary();
    setState(() => _library = books);
  }

  Future<void> _saveLibrary() async {
    await LibraryService.saveLibrary(_library);
  }

  /// Lets user pick a .epub file, then add to library (no version check)
  Future<void> _pickAndAddBook() async {
    debugPrint('Add button tapped!');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    if (!picked.name.toLowerCase().endsWith('.epub')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${picked.name} is not an EPUB')),
      );
      return;
    }

    // If needed, you can check picked.bytes or path for more logic
    // But we skip version checks
    final newBook = BookEntry(
      id: const Uuid().v4(),
      title: picked.name,
      path: picked.path ?? '_inMemory_${picked.name}', // fallback
    );

    setState(() => _library.add(newBook));
    await _saveLibrary();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${picked.name} to library!')),
    );
  }

  void _openBook(BookEntry book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookReaderScreen(book: book)),
    ).then((_) => _loadLibrary());
  }

  Future<void> _removeBook(BookEntry book) async {
    setState(() {
      _library.removeWhere((b) => b.id == book.id);
    });
    await _saveLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickAndAddBook,
          ),
        ],
      ),
      body: _library.isEmpty
          ? const Center(child: Text('No books in the library.'))
          : ListView.builder(
              itemCount: _library.length,
              itemBuilder: (context, i) {
                final book = _library[i];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text('Chapter: ${book.lastChapterIndex}, Word: ${book.lastWordIndex}'),
                  onTap: () => _openBook(book),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeBook(book),
                  ),
                );
              },
            ),
    );
  }
}