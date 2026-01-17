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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
