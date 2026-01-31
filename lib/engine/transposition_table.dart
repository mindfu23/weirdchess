import '../core/move.dart';

/// Entry type in the transposition table.
enum TTEntryType {
  /// Exact evaluation (no cutoff occurred).
  exact,
  /// Lower bound (beta cutoff in maximizing node).
  lowerBound,
  /// Upper bound (alpha cutoff in minimizing node).
  upperBound,
}

/// An entry in the transposition table.
class TTEntry {
  final int hash;
  final int depth;
  final double score;
  final TTEntryType type;
  final Move? bestMove;
  final int age;

  const TTEntry({
    required this.hash,
    required this.depth,
    required this.score,
    required this.type,
    this.bestMove,
    required this.age,
  });
}

/// Transposition table for storing evaluated positions.
/// Uses Zobrist hashing for efficient position identification.
class TranspositionTable {
  final Map<int, TTEntry> _table = {};
  final int maxSize;
  int _currentAge = 0;
  int _hits = 0;
  int _misses = 0;
  int _stores = 0;

  TranspositionTable({this.maxSize = 100000});

  /// Probe the table for a cached position.
  /// Returns null if not found or if stored depth is insufficient.
  TTEntry? probe(int hash, int depth) {
    final entry = _table[hash];
    if (entry == null) {
      _misses++;
      return null;
    }

    // Only use if stored depth is at least as deep as current search
    if (entry.depth >= depth) {
      _hits++;
      return entry;
    }

    _misses++;
    return null;
  }

  /// Store a position in the table.
  void store({
    required int hash,
    required int depth,
    required double score,
    required TTEntryType type,
    Move? bestMove,
  }) {
    _stores++;

    // Replacement strategy: always replace if newer age or deeper depth
    final existing = _table[hash];
    if (existing != null) {
      // Keep existing if it's from current search and deeper
      if (existing.age == _currentAge && existing.depth > depth) {
        return;
      }
    }

    // Clean up if table is too large
    if (_table.length >= maxSize) {
      _cleanup();
    }

    _table[hash] = TTEntry(
      hash: hash,
      depth: depth,
      score: score,
      type: type,
      bestMove: bestMove,
      age: _currentAge,
    );
  }

  /// Get cached best move for move ordering.
  Move? getBestMove(int hash) {
    return _table[hash]?.bestMove;
  }

  /// Increment age (call at start of each new search).
  void newSearch() {
    _currentAge++;
  }

  /// Clear the table.
  void clear() {
    _table.clear();
    _currentAge = 0;
    _hits = 0;
    _misses = 0;
    _stores = 0;
  }

  /// Remove old entries to make room.
  void _cleanup() {
    // Remove entries from older searches first
    final keysToRemove = <int>[];
    for (final entry in _table.entries) {
      if (entry.value.age < _currentAge - 2) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _table.remove(key);
    }

    // If still too large, remove half randomly
    if (_table.length > maxSize * 0.9) {
      final keys = _table.keys.toList();
      for (int i = 0; i < keys.length ~/ 2; i++) {
        _table.remove(keys[i]);
      }
    }
  }

  /// Get statistics about table usage.
  Map<String, dynamic> get stats => {
    'size': _table.length,
    'maxSize': maxSize,
    'hits': _hits,
    'misses': _misses,
    'stores': _stores,
    'hitRate': _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0,
  };
}

/// Zobrist hash generator for chess positions.
class ZobristHash {
  // Pre-computed random numbers for hashing
  // [color][piece_type][row][col] - simplified for 10x10 board
  static final List<List<List<List<int>>>> _pieceHashes = _generatePieceHashes();
  static final int _blackToMove = DateTime.now().microsecondsSinceEpoch;
  static final List<int> _enPassantHashes = List.generate(10, (i) => i * 0x123456789);

  static List<List<List<List<int>>>> _generatePieceHashes() {
    final random = _PseudoRandom(12345678);
    return List.generate(
      2, // colors
      (_) => List.generate(
        16, // piece types (more than needed for safety)
        (_) => List.generate(
          10, // rows
          (_) => List.generate(
            10, // cols
            (_) => random.next(),
          ),
        ),
      ),
    );
  }

  /// Compute hash for a piece at a position.
  static int pieceHash(int colorIndex, int pieceIndex, int row, int col) {
    return _pieceHashes[colorIndex][pieceIndex % 16][row][col];
  }

  /// Get hash component for black to move.
  static int get blackToMoveHash => _blackToMove;

  /// Get hash component for en passant file.
  static int enPassantHash(int col) => _enPassantHashes[col];
}

/// Simple pseudo-random number generator for consistent hash initialization.
class _PseudoRandom {
  int _state;

  _PseudoRandom(this._state);

  int next() {
    _state = (_state * 1103515245 + 12345) & 0x7FFFFFFF;
    return _state;
  }
}
