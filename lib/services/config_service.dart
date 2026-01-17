import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported LLM providers.
enum LlmProvider {
  anthropic,
  openai,
  google,
}

extension LlmProviderExtension on LlmProvider {
  String get displayName {
    switch (this) {
      case LlmProvider.anthropic:
        return 'Anthropic (Claude)';
      case LlmProvider.openai:
        return 'OpenAI (GPT)';
      case LlmProvider.google:
        return 'Google (Gemini)';
    }
  }

  String get defaultModel {
    switch (this) {
      case LlmProvider.anthropic:
        return 'claude-3-haiku-20240307';
      case LlmProvider.openai:
        return 'gpt-4o-mini';
      case LlmProvider.google:
        return 'gemini-1.5-flash';
    }
  }
}

/// Configuration for the app, loaded from local file or environment.
class AppConfig {
  final LlmProvider provider;
  final Map<LlmProvider, String> apiKeys;
  final Map<LlmProvider, String> models;
  final String? apiBaseUrl;
  final bool directMode;
  final bool commentaryEnabled;

  const AppConfig({
    this.provider = LlmProvider.anthropic,
    this.apiKeys = const {},
    this.models = const {},
    this.apiBaseUrl,
    this.directMode = true,
    this.commentaryEnabled = true,
  });

  /// Get the API key for the current provider.
  String? get currentApiKey => apiKeys[provider];

  /// Get the model for the current provider.
  String get currentModel => models[provider] ?? provider.defaultModel;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    // Parse provider
    LlmProvider provider = LlmProvider.anthropic;
    final providerStr = json['provider'] as String?;
    if (providerStr != null) {
      provider = LlmProvider.values.firstWhere(
        (p) => p.name == providerStr,
        orElse: () => LlmProvider.anthropic,
      );
    }

    // Parse API keys
    final apiKeysJson = json['apiKeys'] as Map<String, dynamic>? ?? {};
    final apiKeys = <LlmProvider, String>{};
    for (final entry in apiKeysJson.entries) {
      final p = LlmProvider.values.firstWhere(
        (p) => p.name == entry.key,
        orElse: () => LlmProvider.anthropic,
      );
      if (entry.value is String && (entry.value as String).isNotEmpty) {
        apiKeys[p] = entry.value as String;
      }
    }

    // Parse models
    final modelsJson = json['models'] as Map<String, dynamic>? ?? {};
    final models = <LlmProvider, String>{};
    for (final entry in modelsJson.entries) {
      final p = LlmProvider.values.firstWhere(
        (p) => p.name == entry.key,
        orElse: () => LlmProvider.anthropic,
      );
      if (entry.value is String && (entry.value as String).isNotEmpty) {
        models[p] = entry.value as String;
      }
    }

    // Legacy support: if 'apiKey' exists at root level, use it for anthropic
    final legacyApiKey = json['apiKey'] as String?;
    if (legacyApiKey != null && legacyApiKey.isNotEmpty && !apiKeys.containsKey(LlmProvider.anthropic)) {
      apiKeys[LlmProvider.anthropic] = legacyApiKey;
    }

    return AppConfig(
      provider: provider,
      apiKeys: apiKeys,
      models: models,
      apiBaseUrl: json['apiBaseUrl'] as String?,
      directMode: json['directMode'] as bool? ?? true,
      commentaryEnabled: json['commentaryEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKeys': {
          for (final entry in apiKeys.entries) entry.key.name: entry.value,
        },
        'models': {
          for (final entry in models.entries) entry.key.name: entry.value,
        },
        'apiBaseUrl': apiBaseUrl,
        'directMode': directMode,
        'commentaryEnabled': commentaryEnabled,
      };

  AppConfig copyWith({
    LlmProvider? provider,
    Map<LlmProvider, String>? apiKeys,
    Map<LlmProvider, String>? models,
    String? apiBaseUrl,
    bool? directMode,
    bool? commentaryEnabled,
  }) {
    return AppConfig(
      provider: provider ?? this.provider,
      apiKeys: apiKeys ?? this.apiKeys,
      models: models ?? this.models,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      directMode: directMode ?? this.directMode,
      commentaryEnabled: commentaryEnabled ?? this.commentaryEnabled,
    );
  }
}

/// Service for loading app configuration.
class ConfigService {
  static const _prefsKeyProvider = 'weirdchess_provider';
  static const _prefsKeyApiKeyPrefix = 'weirdchess_api_key_';
  static const _prefsKeyModelPrefix = 'weirdchess_model_';
  static const _prefsKeyApiBaseUrl = 'weirdchess_api_base_url';
  static const _prefsKeyCommentaryEnabled = 'weirdchess_commentary_enabled';

  /// Load configuration from available sources.
  /// Priority: SharedPreferences > Local config file > Defaults
  Future<AppConfig> loadConfig() async {
    // Try SharedPreferences first (user-set values)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedProvider = prefs.getString(_prefsKeyProvider);

      if (savedProvider != null) {
        final provider = LlmProvider.values.firstWhere(
          (p) => p.name == savedProvider,
          orElse: () => LlmProvider.anthropic,
        );

        // Load all API keys
        final apiKeys = <LlmProvider, String>{};
        for (final p in LlmProvider.values) {
          final key = prefs.getString('$_prefsKeyApiKeyPrefix${p.name}');
          if (key != null && key.isNotEmpty) {
            apiKeys[p] = key;
          }
        }

        // Load all models
        final models = <LlmProvider, String>{};
        for (final p in LlmProvider.values) {
          final model = prefs.getString('$_prefsKeyModelPrefix${p.name}');
          if (model != null && model.isNotEmpty) {
            models[p] = model;
          }
        }

        if (apiKeys.isNotEmpty) {
          return AppConfig(
            provider: provider,
            apiKeys: apiKeys,
            models: models,
            apiBaseUrl: prefs.getString(_prefsKeyApiBaseUrl),
            commentaryEnabled: prefs.getBool(_prefsKeyCommentaryEnabled) ?? true,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load from SharedPreferences: $e');
    }

    // Try loading from local config file (for development)
    try {
      final configJson = await rootBundle.loadString('assets/config.json');
      final config = json.decode(configJson) as Map<String, dynamic>;
      return AppConfig.fromJson(config);
    } catch (e) {
      debugPrint('No local config file found: $e');
    }

    // Return defaults (no API key - commentary will be disabled)
    return const AppConfig();
  }

  /// Save provider selection.
  Future<void> saveProvider(LlmProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyProvider, provider.name);
  }

  /// Save API key for a specific provider.
  Future<void> saveApiKey(LlmProvider provider, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyApiKeyPrefix${provider.name}', apiKey);
  }

  /// Save model for a specific provider.
  Future<void> saveModel(LlmProvider provider, String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyModelPrefix${provider.name}', model);
  }

  /// Save base URL to SharedPreferences.
  Future<void> saveApiBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyApiBaseUrl, baseUrl);
  }

  /// Save commentary enabled setting.
  Future<void> saveCommentaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyCommentaryEnabled, enabled);
  }

  /// Clear saved configuration.
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyProvider);
    for (final p in LlmProvider.values) {
      await prefs.remove('$_prefsKeyApiKeyPrefix${p.name}');
      await prefs.remove('$_prefsKeyModelPrefix${p.name}');
    }
    await prefs.remove(_prefsKeyApiBaseUrl);
  }
}

/// Provider for the config service.
final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService();
});

/// Provider for loaded app config.
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final configService = ref.read(configServiceProvider);
  return configService.loadConfig();
});
