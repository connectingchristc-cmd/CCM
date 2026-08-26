import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AppFeatureStore extends ChangeNotifier {
  static const _favoritesKey = 'favorite_song_ids';
  static const _cachedSongsKey = 'cached_songs';
  static const _setlistsKey = 'worship_setlists';

  SharedPreferences? _preferences;

  final List<String> favoriteSongIds = <String>[];

  final Map<String, Map<String, dynamic>> cachedSongs =
      <String, Map<String, dynamic>>{};

  List<Map<String, dynamic>> setlists =
      <Map<String, dynamic>>[];

  Future<void> load() async {
    try {
      _preferences =
          await SharedPreferences.getInstance();

      final savedFavs =
          _preferences?.getStringList(
                _favoritesKey,
              ) ??
              <String>[];

      favoriteSongIds.clear();
      favoriteSongIds.addAll(savedFavs);

      final cached =
          _preferences?.getString(
            _cachedSongsKey,
          );

      if (cached != null) {
        final decoded =
            jsonDecode(cached) as List<dynamic>;

        for (final item in decoded) {
          final song =
              Map<String, dynamic>.from(
            item as Map,
          );

          final id = song['id']?.toString();

          if (id != null) {
            cachedSongs[id] = song;
          }
        }
      }

      final storedSetlists =
          _preferences?.getString(
            _setlistsKey,
          );

      if (storedSetlists != null) {
        setlists =
            (jsonDecode(storedSetlists)
                    as List<dynamic>)
                .map(
                  (item) =>
                      Map<String, dynamic>.from(
                    item as Map,
                  ),
                )
                .toList();
      }

      notifyListeners();
    } catch (error) {
      debugPrint(
        'Local feature storage unavailable: $error',
      );
    }
  }

  bool isFavorite(String songId) {
    return favoriteSongIds.contains(songId);
  }

  Future<void> toggleFavorite(
    String songId,
  ) async {
    if (favoriteSongIds.contains(songId)) {
      favoriteSongIds.remove(songId);
    } else {
      favoriteSongIds.add(songId);
    }

    await _preferences?.setStringList(
      _favoritesKey,
      favoriteSongIds,
    );

    notifyListeners();
  }

  Future<void> reorderFavorites(
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item =
        favoriteSongIds.removeAt(oldIndex);

    favoriteSongIds.insert(
      newIndex,
      item,
    );

    await _preferences?.setStringList(
      _favoritesKey,
      favoriteSongIds,
    );

    notifyListeners();
  }

  Future<void> cacheSongs(
    Iterable<QueryDocumentSnapshot> docs,
  ) async {
    for (final doc in docs) {
      cachedSongs[doc.id] = <String, dynamic>{
        'id': doc.id,
        ...(doc.data()
            as Map<String, dynamic>),
      };
    }

    await _preferences?.setString(
      _cachedSongsKey,
      jsonEncode(
        cachedSongs.values.toList(),
      ),
    );
  }

  Future<void> saveSetlists() async {
    await _preferences?.setString(
      _setlistsKey,
      jsonEncode(setlists),
    );

    notifyListeners();
  }
}

final appFeatureStore =
    AppFeatureStore();