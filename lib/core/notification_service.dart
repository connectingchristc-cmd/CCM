import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


Future<void> sendNotificationRecord({
  required String title,
  required String body,
  required String category,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'category': category,
      'created_at':
          FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint(
      'Error writing notification: $e',
    );
  }
}