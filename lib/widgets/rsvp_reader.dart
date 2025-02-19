// lib/widgets/rsvp_reader.dart

import 'dart:async';
import 'package:flutter/material.dart';

enum ReadingState {
  notStarted,
  reading,
  paused,
}

class RsvpReader extends StatefulWidget {
  final List<String> words;

  // We'll let the parent manage overall WPM tracking,
  // so we also accept an initial WPM from outside:
  final int initialWpm;

  // Callback to let the parent know the current word index
  final ValueChanged<int>? onWordIndexChanged;

  // Callback to let the parent know if speed changes
  final ValueChanged<int>? onWpmChanged;

  const RsvpReader({
    Key? key,
    required this.words,
    this.initialWpm = 300,
    this.onWordIndexChanged,
    this.onWpmChanged,
  }) : super(key: key);

  @override
  RsvpReaderState createState() => RsvpReaderState();
}

class RsvpReaderState extends State<RsvpReader> {
  int currentIndex = 0;
  Timer? _timer;
  late int wpm;
  late int msDelay;

  // This tracks our reading state so we can label the button properly.
  ReadingState readingState = ReadingState.notStarted;

  @override
  void initState() {
    super.initState();
    wpm = widget.initialWpm;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    readingState = ReadingState.reading;
    _updateTimer();
  }

  void _pause() {
    readingState = ReadingState.paused;
    _timer?.cancel();
    _timer = null;
  }

  void _resume() {
    readingState = ReadingState.reading;
    _updateTimer();
  }

  /// Called whenever we start/resume reading or change the speed
  void _updateTimer() {
    _timer?.cancel();
    msDelay = (60000 / wpm).round();

    _timer = Timer.periodic(Duration(milliseconds: msDelay), (_) {
      setState(() {
        currentIndex++;
        if (currentIndex >= widget.words.length) {
          currentIndex = widget.words.length - 1;
          _timer?.cancel();
          readingState = ReadingState.paused;
        }

        // Notify parent of the new index
        widget.onWordIndexChanged?.call(currentIndex);
      });
    });
  }

  void _increaseSpeed() {
    setState(() {
      wpm += 50;
      // tell parent we changed wpm
      widget.onWpmChanged?.call(wpm);

      if (readingState == ReadingState.reading) {
        _updateTimer();
      }
    });
  }

  void _decreaseSpeed() {
    setState(() {
      wpm = (wpm - 50).clamp(50, 2000);
      widget.onWpmChanged?.call(wpm);

      if (readingState == ReadingState.reading) {
        _updateTimer();
      }
    });
  }

  /// The single button below needs to reflect the readingState.
  /// - notStarted -> "Start"
  /// - reading -> "Pause"
  /// - paused -> "Resume"
  void _onMainButtonPressed() {
    setState(() {
      if (readingState == ReadingState.notStarted) {
        _start();
      } else if (readingState == ReadingState.reading) {
        _pause();
      } else if (readingState == ReadingState.paused) {
        _resume();
      }
    });
  }

  String get mainButtonLabel {
    switch (readingState) {
      case ReadingState.notStarted:
        return "Start";
      case ReadingState.reading:
        return "Pause";
      case ReadingState.paused:
        return "Resume";
    }
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

        // Speed controls
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

        // The main reading button
        ElevatedButton(
          onPressed: _onMainButtonPressed,
          child: Text(mainButtonLabel),
        ),
      ],
    );
  }
}