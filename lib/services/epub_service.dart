import 'package:flutter/services.dart' show rootBundle;
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as htmlParser;

class EpubService {
  Future<EpubBook> loadEpub(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    return await EpubReader.readBook(bytes);
  }

  String extractChapterText(EpubChapter chapter) {
    // 1) Convert HTML content to text properly
    final text = _htmlToText(chapter.HtmlContent);

    // 2) Recursively handle sub-chapters
    final sb = StringBuffer(text);
    for (var sub in chapter.SubChapters ?? <EpubChapter>[]) {
      sb.write(extractChapterText(sub));
    }

    return sb.toString();
  }

  // Helper that strips tags & decodes entities (e.g., &amp; => &)
  String _htmlToText(String? html) {
    if (html == null) return '';
    final doc = htmlParser.parse(html);
    // doc.body?.text will give you the raw text with tags stripped & entities decoded
    final text = doc.body?.text ?? '';
    return text.trim();
  }
}