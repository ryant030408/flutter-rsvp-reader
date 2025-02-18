// lib/widgets/rsvp_reader.dart

import 'dart:async';
import 'package:flutter/material.dart';

class RsvpReader extends StatefulWidget {
  final List<String> words;
  final int initialWpm;

  // New: callback for reporting the current word index
  final ValueChanged<int>? onWordIndexChanged;

  const RsvpReader({
    Key? key,
    required this.words,
    this.initialWpm = 300,
    this.onWordIndexChanged,
  }) : super(key: key);

  @override
  RsvpReaderState createState() => RsvpReaderState();
}

class RsvpReaderState extends State<RsvpReader> {
  int currentIndex = 0;
  Timer? _timer;
  late int wpm;
  late int msDelay;

  @override
  void initState() {
    super.initState();
    wpm = widget.initialWpm;
    _startRsvp();
  }

  void _startRsvp() {
    // Convert WPM to ms delay
    msDelay = (60000 / wpm).round();
    _timer?.cancel();

    _timer = Timer.periodic(Duration(milliseconds: msDelay), (_) {
      setState(() {
        currentIndex++;
        if (currentIndex >= widget.words.length) {
          _timer?.cancel();
          currentIndex = widget.words.length - 1;
        }
        // Notify parent of the new index
        widget.onWordIndexChanged?.call(currentIndex);
      });
    });
  }

  void _stopRsvp() {
    _timer?.cancel();
    _timer = null;
  }

  void _increaseSpeed() {
    setState(() {
      wpm += 50;
      _startRsvp();
    });
  }

  void _decreaseSpeed() {
    setState(() {
      wpm = (wpm - 50).clamp(50, 2000);
      _startRsvp();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = widget.words.isEmpty
        ? ''
        : widget.words[currentIndex.clamp(0, widget.words.length - 1)];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          currentWord,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 50),
        Text('WPM: $wpm', style: const TextStyle(fontSize: 16)),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _decreaseSpeed,
              child: const Text('Slower'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _increaseSpeed,
              child: const Text('Faster'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _timer == null ? _startRsvp : _stopRsvp,
          child: Text(_timer == null ? 'Start' : 'Stop'),
        ),
      ],
    );
  }
}