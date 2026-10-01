import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ScoreboardEntry {
  final DateTime date;
  final String mode;
  final String myName;
  final int myScore;
  final List<String> players;
  final List<int> scores;

  const ScoreboardEntry({
    required this.date,
    required this.mode,
    required this.myName,
    required this.myScore,
    required this.players,
    required this.scores,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mode': mode,
      'myName': myName,
      'myScore': myScore,
      'players': players,
      'scores': scores,
    };
  }

  factory ScoreboardEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return ScoreboardEntry(
      date: DateTime.tryParse(
            json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      mode: json['mode']?.toString() ?? 'Game',
      myName: json['myName']?.toString() ?? 'You',
      myScore: (json['myScore'] as num?)?.toInt() ?? 0,
      players: (json['players'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      scores: (json['scores'] as List? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}

class ScoreboardStorage {
  static const String _key = 'black_queen_scoreboard_v1';

  static Future<List<ScoreboardEntry>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .map(
            (item) => ScoreboardEntry.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGame({
    required String mode,
    required String myName,
    required int myScore,
    required List<String> players,
    required List<int> scores,
  }) async {
    final games = await loadGames();

    games.insert(
      0,
      ScoreboardEntry(
        date: DateTime.now(),
        mode: mode,
        myName: myName,
        myScore: myScore,
        players: List<String>.from(players),
        scores: List<int>.from(scores),
      ),
    );

    // Keep the scoreboard lightweight.
    if (games.length > 100) {
      games.removeRange(100, games.length);
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode(
        games.map((game) => game.toJson()).toList(),
      ),
    );
  }

  static Future<void> clearGames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
