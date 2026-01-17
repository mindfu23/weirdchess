import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Authentication state for LLM API access.
/// Designed to be replaced with a full auth flow later.
class AuthState {
  final String? apiKey;
  final String? userId;
  final String? accessToken;
  final bool isAuthenticated;

  const AuthState({
    this.apiKey,
    this.userId,
    this.accessToken,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    String? apiKey,
    String? userId,
    String? accessToken,
    bool? isAuthenticated,
  }) {
    return AuthState(
      apiKey: apiKey ?? this.apiKey,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  /// Get the authorization header value for API calls.
  /// Prefers accessToken (from auth flow) over apiKey (from config).
  String? get authHeader {
    if (accessToken != null) return 'Bearer $accessToken';
    if (apiKey != null) return 'Bearer $apiKey';
    return null;
  }
}

/// Abstract auth provider interface.
/// Implement this to plug in your own auth system.
abstract class AuthProvider {
  Future<AuthState> initialize();
  Future<AuthState> signIn(String email, String password);
  Future<AuthState> signUp(String email, String password);
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;
}

/// Simple API key-based auth for local development.
/// Replace with your auth provider implementation later.
class ApiKeyAuthProvider implements AuthProvider {
  final String? _apiKey;
  AuthState _state;

  ApiKeyAuthProvider({String? apiKey})
      : _apiKey = apiKey,
        _state = const AuthState();

  @override
  Future<AuthState> initialize() async {
    if (_apiKey != null && _apiKey.isNotEmpty) {
      _state = AuthState(
        apiKey: _apiKey,
        isAuthenticated: true,
      );
    }
    return _state;
  }

  @override
  Future<AuthState> signIn(String email, String password) async {
    // Not supported in API key mode
    throw UnimplementedError('Use full auth provider for sign in');
  }

  @override
  Future<AuthState> signUp(String email, String password) async {
    // Not supported in API key mode
    throw UnimplementedError('Use full auth provider for sign up');
  }

  @override
  Future<void> signOut() async {
    _state = const AuthState();
  }

  @override
  Stream<AuthState> get authStateChanges => Stream.value(_state);
}

/// Auth notifier for Riverpod state management.
class AuthNotifier extends Notifier<AuthState> {
  AuthProvider? _provider;

  @override
  AuthState build() => const AuthState();

  /// Initialize with an auth provider.
  Future<void> initialize(AuthProvider provider) async {
    _provider = provider;
    state = await provider.initialize();
  }

  /// Set API key directly (for simple config-based auth).
  void setApiKey(String apiKey) {
    state = AuthState(apiKey: apiKey, isAuthenticated: true);
  }

  /// Sign in (delegates to provider).
  Future<void> signIn(String email, String password) async {
    if (_provider == null) throw StateError('Auth provider not initialized');
    state = await _provider!.signIn(email, password);
  }

  /// Sign up (delegates to provider).
  Future<void> signUp(String email, String password) async {
    if (_provider == null) throw StateError('Auth provider not initialized');
    state = await _provider!.signUp(email, password);
  }

  /// Sign out.
  Future<void> signOut() async {
    await _provider?.signOut();
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
