// lib/main.dart

import 'package:flutter/material.dart';
import 'package:rsvp_reader/screens/library_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSVP Reader Library',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LibraryScreen(),
    );
  }
}