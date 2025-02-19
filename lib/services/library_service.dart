// lib/services/library_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rsvp_reader/models/book_entry.dart';

class LibraryService {
  static const String _libraryKey = 'user_library';

  /// Loads the list of books from SharedPreferences
  static Future<List<BookEntry>> loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_libraryKey);
    if (jsonString == null) return [];

    try {
      final List decoded = json.decode(jsonString);
      return decoded.map((e) => BookEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves the list of books to SharedPreferences
  static Future<void> saveLibrary(List<BookEntry> library) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(library.map((b) => b.toJson()).toList());
    await prefs.setString(_libraryKey, encoded);
  }
}