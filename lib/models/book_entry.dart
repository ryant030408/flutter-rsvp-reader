// lib/models/book_entry.dart

class BookEntry {
  final String id;
  final String title;
  final String path;

  // Reading progress
  int lastChapterIndex;
  int lastWordIndex;
  int currentWpm;

  BookEntry({
    required this.id,
    required this.title,
    required this.path,
    this.lastChapterIndex = 0,
    this.lastWordIndex = 0,
    this.currentWpm = 300,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'lastChapterIndex': lastChapterIndex,
      'lastWordIndex': lastWordIndex,
      'currentWpm': currentWpm,
    };
  }

  factory BookEntry.fromJson(Map<String, dynamic> json) {
    return BookEntry(
      id: json['id'],
      title: json['title'],
      path: json['path'],
      lastChapterIndex: json['lastChapterIndex'] ?? 0,
      lastWordIndex: json['lastWordIndex'] ?? 0,
      currentWpm: json['currentWpm'] ?? 300,
    );
  }
}