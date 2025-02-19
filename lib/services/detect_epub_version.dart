// lib/services/detect_epub_version.dart

import 'dart:convert';      // for utf8
import 'dart:typed_data';   // for Uint8List
import 'package:archive/archive.dart'; // for ZipDecoder

/// Reads container.xml and content.opf from an EPUB. Returns the "version" attribute string.
/// For example, "1.0", "2.0", "3.0", or null if not found.
Future<String?> detectEpubVersion(Uint8List epubBytes) async {
  try {
    // Decode the ZIP
    final archive = ZipDecoder().decodeBytes(epubBytes);

    // Find META-INF/container.xml
    final containerFile = archive.files.firstWhere(
      (f) => f.name.toLowerCase() == 'meta-inf/container.xml',
      orElse: () => throw Exception('No container.xml found'),
    );

    final containerXml = utf8.decode(containerFile.content as List<int>);
    final fullPathMatch = RegExp(r'full-path="([^"]+)"').firstMatch(containerXml);
    if (fullPathMatch == null) {
      throw Exception('No full-path in container.xml');
    }

    final opfPath = fullPathMatch.group(1);
    if (opfPath == null) {
      throw Exception('No full-path attribute in container.xml');
    }

    // Find the .opf file
    final opfFile = archive.files.firstWhere(
      (f) => f.name == opfPath,
      orElse: () => throw Exception('OPF file not found at $opfPath'),
    );

    final opfXml = utf8.decode(opfFile.content as List<int>);
    final versionMatch = RegExp(r'<package[^>]*version\s*=\s*"([^"]+)"').firstMatch(opfXml);
    if (versionMatch == null) {
      return null; // version attribute not found
    }

    return versionMatch.group(1); // e.g. "1.0", "2.0", "3.0"
  } catch (e) {
    return null;
  }
}