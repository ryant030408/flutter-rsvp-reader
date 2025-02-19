// lib/services/epub_service.dart

import 'dart:io';              // For File I/O (if you're reading local files)
import 'dart:typed_data';      // For Uint8List
import 'dart:convert';         // For utf8 decoding
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';  // For ZipDecoder
import 'package:epubx/epubx.dart';      // For EpubReader, EpubBook, etc.

class EpubService {
  /// Loads an EPUB from either assets (if [path] starts with 'assets/') or
  /// local file system. Returns [EpubBook].
  Future<EpubBook> loadEpub(String path) async {
    Uint8List bytes;

    // 1. Load from assets if the path starts with "assets/"
    if (path.startsWith('assets/')) {
      final byteData = await rootBundle.load(path);
      bytes = byteData.buffer.asUint8List();
    } else {
      // 2. Otherwise assume it's a local file path (desktop/mobile).
      //    Will not work on web directly unless you adapt.
      final file = File(path);
      bytes = await file.readAsBytes();
    }

    // Parse the bytes into an EpubBook using epubx
    final epubBook = await EpubReader.readBook(bytes);
    return epubBook;
  }

  /// Extracts chapter text (including sub-chapters).
  /// Optionally strip out HTML tags or parse them more thoroughly.
  String extractChapterText(EpubChapter chapter) {
    // Raw HTML content:
    String text = chapter.HtmlContent ?? '';

    // If you want to remove HTML tags quickly (regex approach):
    // text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Recursively handle sub-chapters
    for (var subChapter in chapter.SubChapters ?? <EpubChapter>[]) {
      text += extractChapterText(subChapter);
    }

    return text;
  }

  /// (Optional) Example method to detect EPUB version by reading container.xml
  /// and content.opf. This uses ZipDecoder and utf8, which is why we need their imports.
  Future<String?> detectEpubVersion(Uint8List epubBytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(epubBytes);

      // Find container.xml
      final containerFile = archive.files.firstWhere(
        (f) => f.name.toLowerCase() == 'meta-inf/container.xml',
        orElse: () => throw Exception('No container.xml found'),
      );

      final containerXml = utf8.decode(containerFile.content as List<int>);
      final fullPathMatch = RegExp(r'full-path="([^"]+)"').firstMatch(containerXml);
      if (fullPathMatch == null) {
        throw Exception('No full-path in container.xml');
      }

      final opfPath = fullPathMatch.group(1)!;
      final opfFile = archive.files.firstWhere(
        (f) => f.name == opfPath,
        orElse: () => throw Exception('OPF file not found at $opfPath'),
      );

      final opfXml = utf8.decode(opfFile.content as List<int>);
      final versionMatch =
          RegExp(r'<package[^>]*version\s*=\s*"([^"]+)"').firstMatch(opfXml);
      if (versionMatch == null) {
        return null; // version not found
      }

      return versionMatch.group(1); // e.g. "1.0", "2.0", "3.0"
    } catch (e) {
      return null;
    }
  }
}