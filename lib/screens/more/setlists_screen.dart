import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../core/app_feature_store.dart';
import 'setlist_detail_screen.dart';
import 'published_setlists_screen.dart';

class SetlistsScreen extends StatefulWidget {
  const SetlistsScreen({super.key});

  @override
  State<SetlistsScreen> createState() =>
      _SetlistsScreenState();
}

class _SetlistsScreenState
    extends State<SetlistsScreen> {
  Future<void> _createSetlist() async {
    final controller =
        TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Create Setlist',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration:
                const InputDecoration(
              labelText: 'Setlist Name',
              hintText:
                  'e.g. Sunday Worship',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: ccmRed,
              ),
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(
                    context,
                    value,
                  );
                }
              },
              child: const Text(
                'Create',
                style: TextStyle(
                  color: ccmWhite,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.isEmpty) {
      return;
    }

    appFeatureStore.setlists.add({
      'name': name,
      'songIds': <String>[],
      'published': false,
    });

    await appFeatureStore.saveSetlists();

    if (!mounted) return;

    final index =
        appFeatureStore.setlists.length - 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SetlistDetailScreen(
          setlistIndex: index,
        ),
      ),
    );
  }

  Future<void> _deleteSetlist(
    int index,
  ) async {
    final setlist =
        appFeatureStore.setlists[index];

    final name =
        setlist['name'] ?? 'Setlist';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Delete Setlist'),
          content: Text(
            'Are you sure you want to delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    appFeatureStore.setlists.removeAt(index);

    await appFeatureStore.saveSetlists();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appFeatureStore,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Worship Setlists',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: ccmRed,
            actions: [
              IconButton(
                tooltip:
                    'Published Setlists',
                icon: const Icon(
                  Icons.public,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PublishedSetlistsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          body: appFeatureStore
                  .setlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play,
                        size: 72,
                        color:
                            Colors.grey[300],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        'No setlists yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      const Text(
                        'Create a worship setlist to get started.',
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      ElevatedButton.icon(
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              ccmRed,
                        ),
                        onPressed:
                            _createSetlist,
                        icon: const Icon(
                          Icons.add,
                          color: ccmWhite,
                        ),
                        label: const Text(
                          'Create Setlist',
                          style: TextStyle(
                            color:
                                ccmWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  itemCount:
                      appFeatureStore
                          .setlists.length,
                  itemBuilder:
                      (context, index) {
                    final setlist =
                        appFeatureStore
                            .setlists[index];

                    final name =
                        setlist['name'] ??
                            'Untitled Setlist';

                    final songIds =
                        (setlist['songIds']
                                as List<dynamic>?)
                            ?.cast<String>() ??
                        <String>[];

                    final published =
                        setlist['published'] ==
                            true;

                    return Card(
                      margin:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: ListTile(
                        leading:
                            CircleAvatar(
                          backgroundColor:
                              published
                                  ? ccmBlue
                                  : ccmRed,
                          child: Icon(
                            published
                                ? Icons.public
                                : Icons
                                    .playlist_play,
                            color: ccmWhite,
                          ),
                        ),
                        title: Text(
                          name,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${songIds.length} song${songIds.length == 1 ? '' : 's'}'
                          '${published ? ' • Published' : ''}',
                        ),
                        trailing:
                            PopupMenuButton<
                                String>(
                          onSelected:
                              (value) {
                            if (value ==
                                'delete') {
                              _deleteSetlist(
                                index,
                              );
                            }
                          },
                          itemBuilder:
                              (context) => [
                            const PopupMenuItem(
                              value:
                                  'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .delete,
                                    color:
                                        Colors.red,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      SetlistDetailScreen(
                                setlistIndex:
                                    index,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

          floatingActionButton:
              FloatingActionButton.extended(
            backgroundColor: ccmRed,
            onPressed: _createSetlist,
            icon: const Icon(
              Icons.add,
              color: ccmWhite,
            ),
            label: const Text(
              'New Setlist',
              style: TextStyle(
                color: ccmWhite,
              ),
            ),
          ),
        );
      },
    );
  }
}