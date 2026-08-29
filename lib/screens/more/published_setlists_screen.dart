import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/app_feature_store.dart';
import 'setlist_detail_screen.dart';

class PublishedSetlistsScreen extends StatelessWidget {
  const PublishedSetlistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appFeatureStore,
      builder: (context, _) {
        final published = <Map<String, dynamic>>[];

        for (int i = 0; i < appFeatureStore.setlists.length; i++) {
          final setlist = appFeatureStore.setlists[i];

          if (setlist['published'] == true) {
            published.add({...setlist, '_index': i});
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Published Setlists',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: ccmSandDark,
            foregroundColor: ccmInk,
          ),
          body: published.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No published setlists yet.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: published.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final setlist = published[index];

                    final originalIndex = setlist['_index'] as int;

                    final songIds =
                        (setlist['songIds'] as List<dynamic>?)
                            ?.cast<String>() ??
                        <String>[];

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: ccmBlue,
                          child: Icon(Icons.public, color: ccmWhite),
                        ),
                        title: Text(
                          setlist['name'] ?? 'Untitled Setlist',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${songIds.length} song${songIds.length == 1 ? '' : 's'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SetlistDetailScreen(
                                setlistIndex: originalIndex,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
