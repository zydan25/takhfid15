import 'package:flutter/material.dart';

void main() {
  runApp(const TakhfidClientApp());
}

class TakhfidClientApp extends StatelessWidget {
  const TakhfidClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'التخفيض الصح',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: const Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: Text(
              'التخفيض الصح',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
