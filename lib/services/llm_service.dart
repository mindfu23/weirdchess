import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/move.dart';
import '../core/piece.dart';
import 'config_service.dart';

/// Configuration for LLM API endpoints.
class LlmConfig {
  /// Base URL for API calls.
  final String baseUrl;

  /// Endpoint path for chat completions.
  final String endpoint;

  /// Selected LLM provider.
  final LlmProvider provider;

  /// Model to use (provider-specific).
  final String model;

  /// Whether commentary is enabled.
  final bool enabled;

  /// Whether to call the provider API directly (bypasses Netlify function).
  final bool directMode;

  /// Maximum number of retry attempts for failed API calls.
  final int maxRetries;

  /// Maximum tokens for response.
  final int maxTokens;

  const LlmConfig({
    this.baseUrl = '/.netlify/functions',
    this.endpoint = '/chess-commentary',
    this.provider = LlmProvider.anthropic,
    this.model = 'claude-3-haiku-20240307',
    this.enabled = true,
    this.directMode = true,
    this.maxRetries = 3,
    this.maxTokens = 200,
  });

  LlmConfig copyWith({
    String? baseUrl,
    String? endpoint,
    LlmProvider? provider,
    String? model,
    bool? enabled,
    bool? directMode,
    int? maxRetries,
    int? maxTokens,
  }) {
    return LlmConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      endpoint: endpoint ?? this.endpoint,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      enabled: enabled ?? this.enabled,
      directMode: directMode ?? this.directMode,
      maxRetries: maxRetries ?? this.maxRetries,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }
}

/// Variant-specific personality for AI commentary.
class VariantPersonality {
  final String variantId;
  final String name;
  final String systemPrompt;
  final List<String> examplePhrases;

  const VariantPersonality({
    required this.variantId,
    required this.name,
    required this.systemPrompt,
    this.examplePhrases = const [],
  });
}

/// Pre-defined personalities for each variant.
class VariantPersonalities {
  static const grandChess = VariantPersonality(
    variantId: 'grand_chess',
    name: 'Grand Master',
    systemPrompt: '''You are a dignified chess grandmaster commentating on a Grand Chess match.
Your tone is refined and strategic. You appreciate the elegance of the Marshal and Cardinal pieces.
Keep commentary to 1-2 sentences. Reference piece names correctly (Marshal, Cardinal).
Occasionally reference the Dutch origins of Grand Chess or Christian Freeling's design.''',
    examplePhrases: [
      'A fine development of the Marshal.',
      'The Cardinal eyes the long diagonal with purpose.',
      'Freeling would appreciate this positional nuance.',
    ],
  );

  static const omegaChess = VariantPersonality(
    variantId: 'omega_chess',
    name: 'Omega Observer',
    systemPrompt: '''You are a modern, slightly nerdy commentator for Omega Chess.
Reference the unique Champion and Wizard pieces. The Champion leaps powerfully;
the Wizard makes mystical diagonal moves. Keep commentary to 1-2 sentences.
Occasionally make references to the commercial/tournament origins of Omega Chess.''',
    examplePhrases: [
      'The Wizard conjures a threat from afar!',
      'Champion leaps into the fray!',
      'A tournament-worthy maneuver.',
    ],
  );

  static const decimalChess = VariantPersonality(
    variantId: 'decimal_chess',
    name: 'Decimal Analyst',
    systemPrompt: '''You are a precise, analytical commentator for Decimal Falcon-Hunter Chess.
The Falcon moves diagonally forward, orthogonally backward. The Hunter is the reverse.
Appreciate the directional asymmetry of these pieces. Keep commentary to 1-2 sentences.''',
    examplePhrases: [
      'The Falcon swoops forward with deadly intent.',
      'Hunter retreats diagonally—clever positioning.',
      'Directional pieces create fascinating imbalances.',
    ],
  );

  static const hyderabadChess = VariantPersonality(
    variantId: 'hyderabad_chess',
    name: 'Court Chronicler',
    systemPrompt: '''You are an 18th-century Indian court chronicler observing Hyderabad Chess.
Your tone is formal and historic. Reference the Zurafa (Giraffe), Wazir, and Dabbaba pieces.
Appreciate the fusion of Persian and Indian chess traditions. Keep commentary to 1-2 sentences.''',
    examplePhrases: [
      'The Zurafa strides across the board with regal grace.',
      'A Dabbaba advances—the elephant of war.',
      'As they played in the courts of Hyderabad...',
    ],
  );

  static const jetan = VariantPersonality(
    variantId: 'jetan',
    name: 'Barsoomian Warrior',
    systemPrompt: '''You are a fierce Barsoomian warrior from Edgar Rice Burroughs' Mars!
Speak with dramatic, martial flair. Reference the pieces by their Barsoomian names:
Chief (Jeddak), Princess (Tara), Flier, Dwar (captain), Padwar (lieutenant),
Warrior, Thoat (mount), Panthan (mercenary).
Use phrases like "By Issus!" and reference the red Martian landscape.
Keep commentary to 1-2 sentences. Be dramatic but not silly.''',
    examplePhrases: [
      'By Issus! The Dwar advances with honor!',
      'A Panthan mercenary knows no fear.',
      'The Princess must be protected at all costs!',
      'Such moves are worthy of a Jeddak!',
      'The Flier sweeps across the board like a Barsoomian warship!',
    ],
  );

  static const standardChess = VariantPersonality(
    variantId: 'standard_chess',
    name: 'Classical Commentator',
    systemPrompt: '''You are a classical chess commentator with deep appreciation for the game.
Your tone is knowledgeable and engaging. Reference famous games and players when relevant.
Keep commentary to 1-2 sentences. Use proper chess terminology.''',
    examplePhrases: [
      'A solid developing move.',
      'The center is contested fiercely.',
      'Reminiscent of the great masters.',
    ],
  );

  static VariantPersonality forVariant(String variantId) {
    switch (variantId) {
      case 'grand_chess':
        return grandChess;
      case 'omega_chess':
        return omegaChess;
      case 'decimal_chess':
        return decimalChess;
      case 'hyderabad_chess':
        return hyderabadChess;
      case 'jetan':
        return jetan;
      case 'standard_chess':
        return standardChess;
      default:
        return grandChess; // Default fallback
    }
  }
}

/// Response from LLM commentary request.
class CommentaryResponse {
  final String text;
  final bool isError;
  final int? retryCount;

  const CommentaryResponse({
    required this.text,
    this.isError = false,
    this.retryCount,
  });

  factory CommentaryResponse.error(String message, {int? retryCount}) {
    return CommentaryResponse(text: message, isError: true, retryCount: retryCount);
  }
}

/// Service for generating AI commentary on chess moves.
class LlmService {
  final http.Client _client;
  final LlmConfig config;

  LlmService({
    http.Client? client,
    this.config = const LlmConfig(),
  }) : _client = client ?? http.Client();

  /// Generate commentary for a move with retry logic.
  Future<CommentaryResponse> generateCommentary({
    required String variantId,
    required Move move,
    required Piece piece,
    required PieceColor color,
    Piece? capturedPiece,
    bool isCheck = false,
    bool isCheckmate = false,
    String? authHeader,
  }) async {
    if (!config.enabled) {
      return const CommentaryResponse(text: '');
    }
    if (config.directMode && authHeader == null) {
      return const CommentaryResponse(text: '');
    }

    final personality = VariantPersonalities.forVariant(variantId);
    final colorName = color == PieceColor.white ? 'White' : 'Black';
    final moveDesc = _describeMove(move, piece, capturedPiece, isCheck, isCheckmate);

    final prompt = '''$colorName played: $moveDesc

Generate a brief (1-2 sentence) commentary on this move in character.''';

    // Retry with exponential backoff
    int attempt = 0;
    Duration delay = const Duration(milliseconds: 500);

    while (attempt < config.maxRetries) {
      try {
        final response = config.directMode
            ? await _callProviderDirect(personality.systemPrompt, prompt, authHeader!)
            : await _callNetlifyFunction(personality.systemPrompt, prompt, variantId, authHeader);

        if (!response.isError) {
          return response;
        }

        // Check if error is retryable
        if (_isRetryableError(response.text)) {
          attempt++;
          if (attempt < config.maxRetries) {
            debugPrint('LLM API call failed (attempt $attempt/${config.maxRetries}), retrying in ${delay.inMilliseconds}ms');
            await Future.delayed(delay);
            delay *= 2; // Exponential backoff
            continue;
          }
        }

        return CommentaryResponse.error(response.text, retryCount: attempt);
      } catch (e) {
        attempt++;
        if (attempt < config.maxRetries && _isRetryableException(e)) {
          debugPrint('LLM API exception (attempt $attempt/${config.maxRetries}): $e');
          await Future.delayed(delay);
          delay *= 2;
          continue;
        }
        return CommentaryResponse.error('Connection error: $e', retryCount: attempt);
      }
    }

    return CommentaryResponse.error('Max retries exceeded', retryCount: attempt);
  }

  /// Check if an error response is retryable.
  bool _isRetryableError(String errorText) {
    final retryableCodes = ['429', '500', '502', '503', '504', 'timeout', 'rate limit'];
    final lowerError = errorText.toLowerCase();
    return retryableCodes.any((code) => lowerError.contains(code));
  }

  /// Check if an exception is retryable.
  bool _isRetryableException(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    return errorStr.contains('timeout') ||
        errorStr.contains('connection') ||
        errorStr.contains('socket') ||
        errorStr.contains('network');
  }

  /// Call the Netlify function endpoint.
  Future<CommentaryResponse> _callNetlifyFunction(
    String personality,
    String prompt,
    String variantId,
    String? authHeader,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authHeader != null) {
      headers['Authorization'] = authHeader;
    }

    final response = await _client.post(
      Uri.parse('${config.baseUrl}${config.endpoint}'),
      headers: headers,
      body: jsonEncode({
        'provider': config.provider.name,
        'model': config.model,
        'personality': personality,
        'prompt': prompt,
        'variantId': variantId,
        'maxTokens': config.maxTokens,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CommentaryResponse(text: data['commentary'] ?? '');
    } else if (response.statusCode == 429) {
      return CommentaryResponse.error('Rate limit exceeded (429)');
    } else {
      return CommentaryResponse.error('API error: ${response.statusCode}');
    }
  }

  /// Call the provider API directly (bypasses Netlify).
  Future<CommentaryResponse> _callProviderDirect(
    String personality,
    String prompt,
    String authHeader,
  ) async {
    final apiKey = authHeader.startsWith('Bearer ')
        ? authHeader.substring(7)
        : authHeader;

    switch (config.provider) {
      case LlmProvider.anthropic:
        return await _callAnthropicDirect(apiKey, personality, prompt);
      case LlmProvider.openai:
        return await _callOpenAIDirect(apiKey, personality, prompt);
      case LlmProvider.google:
        return await _callGoogleDirect(apiKey, personality, prompt);
    }
  }

  Future<CommentaryResponse> _callAnthropicDirect(
    String apiKey,
    String personality,
    String prompt,
  ) async {
    final response = await _client.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': config.model,
        'max_tokens': config.maxTokens,
        'system': personality,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'] as List?;
      if (content != null && content.isNotEmpty) {
        return CommentaryResponse(text: content[0]['text'] ?? '');
      }
      return const CommentaryResponse(text: '');
    } else if (response.statusCode == 429) {
      return CommentaryResponse.error('Rate limit exceeded (429)');
    } else {
      try {
        final error = jsonDecode(response.body);
        return CommentaryResponse.error(
          'Anthropic error: ${error['error']?['message'] ?? response.statusCode}',
        );
      } catch (_) {
        return CommentaryResponse.error('Anthropic error: ${response.statusCode}');
      }
    }
  }

  Future<CommentaryResponse> _callOpenAIDirect(
    String apiKey,
    String personality,
    String prompt,
  ) async {
    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': config.model,
        'max_tokens': config.maxTokens,
        'messages': [
          {'role': 'system', 'content': personality},
          {'role': 'user', 'content': prompt},
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return CommentaryResponse(
          text: choices[0]['message']?['content'] ?? '',
        );
      }
      return const CommentaryResponse(text: '');
    } else if (response.statusCode == 429) {
      return CommentaryResponse.error('Rate limit exceeded (429)');
    } else {
      return CommentaryResponse.error('OpenAI error: ${response.statusCode}');
    }
  }

  Future<CommentaryResponse> _callGoogleDirect(
    String apiKey,
    String personality,
    String prompt,
  ) async {
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=$apiKey';

    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': '$personality\n\n$prompt'},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': config.maxTokens},
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return CommentaryResponse(text: parts[0]['text'] ?? '');
        }
      }
      return const CommentaryResponse(text: '');
    } else if (response.statusCode == 429) {
      return CommentaryResponse.error('Rate limit exceeded (429)');
    } else {
      return CommentaryResponse.error('Google error: ${response.statusCode}');
    }
  }

  String _describeMove(
    Move move,
    Piece piece,
    Piece? capturedPiece,
    bool isCheck,
    bool isCheckmate,
  ) {
    final buffer = StringBuffer();
    buffer.write('${piece.name} from ${move.from.toAlgebraic(10)} to ${move.to.toAlgebraic(10)}');

    if (capturedPiece != null) {
      buffer.write(', capturing ${capturedPiece.name}');
    }
    if (isCheckmate) {
      buffer.write(' - CHECKMATE!');
    } else if (isCheck) {
      buffer.write(' - Check!');
    }

    return buffer.toString();
  }

  void dispose() {
    _client.close();
  }
}

/// LLM config notifier.
class LlmConfigNotifier extends Notifier<LlmConfig> {
  @override
  LlmConfig build() => const LlmConfig();

  void setBaseUrl(String url) => state = state.copyWith(baseUrl: url);
  void setEnabled(bool enabled) => state = state.copyWith(enabled: enabled);
  void setModel(String model) => state = state.copyWith(model: model);
  void setProvider(LlmProvider provider) => state = state.copyWith(provider: provider);
  void setDirectMode(bool directMode) => state = state.copyWith(directMode: directMode);
  void setMaxRetries(int maxRetries) => state = state.copyWith(maxRetries: maxRetries);
  void setMaxTokens(int maxTokens) => state = state.copyWith(maxTokens: maxTokens);

  void setProviderWithModel(LlmProvider provider, String? model) {
    state = state.copyWith(
      provider: provider,
      model: model ?? provider.defaultModel,
    );
  }
}

final llmConfigProvider = NotifierProvider<LlmConfigNotifier, LlmConfig>(
  LlmConfigNotifier.new,
);

final llmServiceProvider = Provider<LlmService>((ref) {
  final config = ref.watch(llmConfigProvider);
  return LlmService(config: config);
});

/// Current commentary state.
class CommentaryState {
  final String text;
  final bool isLoading;
  final bool isError;

  const CommentaryState({
    this.text = '',
    this.isLoading = false,
    this.isError = false,
  });

  CommentaryState copyWith({
    String? text,
    bool? isLoading,
    bool? isError,
  }) {
    return CommentaryState(
      text: text ?? this.text,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}

/// Commentary notifier for managing current AI speech.
class CommentaryNotifier extends Notifier<CommentaryState> {
  @override
  CommentaryState build() => const CommentaryState();

  void setLoading() {
    state = state.copyWith(isLoading: true, isError: false);
  }

  void setCommentary(String text) {
    state = CommentaryState(text: text, isLoading: false, isError: false);
  }

  void setError(String error) {
    state = CommentaryState(text: error, isLoading: false, isError: true);
  }

  void clear() {
    state = const CommentaryState();
  }
}

final commentaryProvider = NotifierProvider<CommentaryNotifier, CommentaryState>(
  CommentaryNotifier.new,
);
