import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: ccmRed,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 72,
              color: ccmRed,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ccmRed,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}