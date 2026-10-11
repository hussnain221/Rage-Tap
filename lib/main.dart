import 'package:flutter/material.dart';

void main() {
  runApp(const RageTapApp());
}

class RageTapApp extends StatelessWidget {
  const RageTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0B1026),
        body: Center(
          child: Text(
            'Rage Tap',
            style: TextStyle(
              color: Color(0xFFF4F7FF),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

