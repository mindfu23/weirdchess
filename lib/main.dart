import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/screens/home_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'services/config_service.dart';
import 'services/auth_service.dart';
import 'services/llm_service.dart';

void main() {
  runApp(const ProviderScope(child: WeirdChessApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class WeirdChessApp extends ConsumerStatefulWidget {
  const WeirdChessApp({super.key});

  @override
  ConsumerState<WeirdChessApp> createState() => _WeirdChessAppState();
}

class _WeirdChessAppState extends ConsumerState<WeirdChessApp> {
  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  Future<void> _initializeConfig() async {
    final configService = ref.read(configServiceProvider);
    final config = await configService.loadConfig();

    // Initialize auth with API key for the selected provider
    final currentApiKey = config.currentApiKey;
    if (currentApiKey != null && currentApiKey.isNotEmpty) {
      ref.read(authProvider.notifier).setApiKey(currentApiKey);
    }

    // Configure LLM service with provider and model
    final llmNotifier = ref.read(llmConfigProvider.notifier);
    if (config.apiBaseUrl != null) {
      llmNotifier.setBaseUrl(config.apiBaseUrl!);
    }
    llmNotifier.setProviderWithModel(config.provider, config.currentModel);
    llmNotifier.setEnabled(config.commentaryEnabled);
    llmNotifier.setDirectMode(config.directMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WeirdChess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9B8A),
          onPrimary: Color(0xFF1A1A1A),
          primaryContainer: Color(0xFF2D3542),
          onPrimaryContainer: Color(0xFFF5E6D3),
          secondary: Color(0xFF9B8E85),
          onSecondary: Color(0xFF1A1A1A),
          secondaryContainer: Color(0xFF2D3542),
          onSecondaryContainer: Color(0xFFF5E6D3),
          surface: Color(0xFF2D3542),
          onSurface: Color(0xFFF5E6D3),
          onSurfaceVariant: Color(0xFF9B8E85),
          error: Color(0xFFFF6B6B),
          onError: Color(0xFF1A1A1A),
          errorContainer: Color(0xFF4A2020),
          onErrorContainer: Color(0xFFFFB3B3),
          outline: Color(0xFF4A5568),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Color(0xFFF5E6D3),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFFF9B8A)),
          titleTextStyle: TextStyle(
            fontFamily: 'Righteous',
            color: Color(0xFFF5E6D3),
            fontSize: 22,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2D3542),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF4A5568),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D3542),
            foregroundColor: const Color(0xFFF5E6D3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF9B8A),
            foregroundColor: const Color(0xFF1A1A1A),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1A1A1A),
          labelStyle: TextStyle(color: Color(0xFF9B8E85)),
          hintStyle: TextStyle(color: Color(0xFF9B8E85)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4A5568)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF9B8A)),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Righteous',
            color: Color(0xFFF5E6D3),
          ),
          titleMedium: TextStyle(
            fontFamily: 'Righteous',
            color: Color(0xFFF5E6D3),
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: Color(0xFFF5E6D3)),
          bodyMedium: TextStyle(color: Color(0xFFF5E6D3)),
          bodySmall: TextStyle(color: Color(0xFF9B8E85)),
          labelMedium: TextStyle(color: Color(0xFF9B8E85)),
        ),
      ),
      routerConfig: _router,
    );
  }
}
