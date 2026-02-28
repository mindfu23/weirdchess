import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/game_state.dart'; // exports GameResult
import '../core/piece.dart';

/// Win/loss/draw statistics for a single variant.
class VariantStats {
  final int wins;
  final int losses;
  final int draws;

  const VariantStats({this.wins = 0, this.losses = 0, this.draws = 0});

  int get gamesPlayed => wins + losses + draws;

  Map<String, dynamic> toJson() => {
        'wins': wins,
        'losses': losses,
        'draws': draws,
      };

  factory VariantStats.fromJson(Map<String, dynamic> json) => VariantStats(
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        draws: json['draws'] as int? ?? 0,
      );

  VariantStats copyWith({int? wins, int? losses, int? draws}) => VariantStats(
        wins: wins ?? this.wins,
        losses: losses ?? this.losses,
        draws: draws ?? this.draws,
      );
}

/// Manages win/loss/draw scoreboard persisted via SharedPreferences.
class ScoreboardNotifier extends Notifier<Map<String, VariantStats>> {
  static const _prefsKey = 'weirdchess_scoreboard';

  @override
  Map<String, VariantStats> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json == null) return;
    final map = jsonDecode(json) as Map<String, dynamic>;
    state = map.map((k, v) =>
        MapEntry(k, VariantStats.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_prefsKey, json);
  }

  /// Record the outcome of a finished game.
  Future<void> recordResult(
    String variantId,
    GameResult result,
    PieceColor humanColor,
  ) async {
    if (result == GameResult.ongoing) return;

    final current = state[variantId] ?? const VariantStats();
    VariantStats updated;

    switch (result) {
      case GameResult.whiteWins:
        updated = humanColor == PieceColor.white
            ? current.copyWith(wins: current.wins + 1)
            : current.copyWith(losses: current.losses + 1);
        break;
      case GameResult.blackWins:
        updated = humanColor == PieceColor.black
            ? current.copyWith(wins: current.wins + 1)
            : current.copyWith(losses: current.losses + 1);
        break;
      case GameResult.draw:
      case GameResult.stalemate:
        updated = current.copyWith(draws: current.draws + 1);
        break;
      case GameResult.ongoing:
        return;
    }

    state = {...state, variantId: updated};
    await _save();
  }
}

final scoreboardProvider =
    NotifierProvider<ScoreboardNotifier, Map<String, VariantStats>>(
        ScoreboardNotifier.new);
