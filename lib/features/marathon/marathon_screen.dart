import 'package:flutter/material.dart';

class MarathonScreen extends StatelessWidget {
  const MarathonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Maraton (yakında): aylık streak yarışmaları + leaderboard + ödül',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}