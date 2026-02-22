/// Possible game results — extracted to avoid circular imports
/// between game_state.dart and variant_interface.dart.
enum GameResult {
  ongoing,
  whiteWins,
  blackWins,
  draw,
  stalemate,
}

extension GameResultExtension on GameResult {
  String get pgnResult {
    switch (this) {
      case GameResult.whiteWins:
        return '1-0';
      case GameResult.blackWins:
        return '0-1';
      case GameResult.draw:
      case GameResult.stalemate:
        return '1/2-1/2';
      case GameResult.ongoing:
        return '*';
    }
  }

  bool get isOver => this != GameResult.ongoing;
}
