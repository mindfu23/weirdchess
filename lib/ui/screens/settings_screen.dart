import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/config_service.dart';
import '../../services/llm_service.dart';

/// Settings screen for configuring API keys and preferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Map<LlmProvider, TextEditingController> _apiKeyControllers = {};
  final _baseUrlController = TextEditingController();
  bool _obscureApiKeys = true;
  LlmProvider _selectedProvider = LlmProvider.anthropic;

  @override
  void initState() {
    super.initState();
    for (final provider in LlmProvider.values) {
      _apiKeyControllers[provider] = TextEditingController();
    }
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final llmConfig = ref.read(llmConfigProvider);
    _selectedProvider = llmConfig.provider;
    _baseUrlController.text = llmConfig.baseUrl;
  }

  @override
  void dispose() {
    for (final controller in _apiKeyControllers.values) {
      controller.dispose();
    }
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final configService = ref.read(configServiceProvider);
    final baseUrl = _baseUrlController.text.trim();

    // Save provider selection
    await configService.saveProvider(_selectedProvider);
    ref.read(llmConfigProvider.notifier).setProvider(_selectedProvider);

    // Save API keys for all providers
    for (final provider in LlmProvider.values) {
      final apiKey = _apiKeyControllers[provider]!.text.trim();
      if (apiKey.isNotEmpty) {
        await configService.saveApiKey(provider, apiKey);
        // If this is the selected provider, update auth
        if (provider == _selectedProvider) {
          ref.read(authProvider.notifier).setApiKey(apiKey);
        }
      }
    }

    // Save base URL
    if (baseUrl.isNotEmpty) {
      await configService.saveApiBaseUrl(baseUrl);
      ref.read(llmConfigProvider.notifier).setBaseUrl(baseUrl);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final llmConfig = ref.watch(llmConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Commentary Section
            _buildSectionHeader('AI Commentary'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Enable AI Commentary'),
                      subtitle: Text(
                        auth.isAuthenticated
                            ? 'AI will comment on moves during gameplay'
                            : 'Requires API key to be configured',
                      ),
                      value: llmConfig.enabled && auth.isAuthenticated,
                      onChanged: auth.isAuthenticated
                          ? (value) {
                              ref.read(llmConfigProvider.notifier).setEnabled(value);
                            }
                          : null,
                    ),
                    if (!auth.isAuthenticated)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Enter an API key below to enable commentary',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Provider Selection Section
            _buildSectionHeader('LLM Provider'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select your preferred AI provider:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ...LlmProvider.values.map((provider) => RadioListTile<LlmProvider>(
                          title: Text(provider.displayName),
                          subtitle: Text('Model: ${provider.defaultModel}'),
                          value: provider,
                          groupValue: _selectedProvider,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedProvider = value;
                              });
                            }
                          },
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // API Keys Section
            _buildSectionHeader('API Keys'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Configure API keys for each provider:',
                          style: TextStyle(fontSize: 14),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _obscureApiKeys = !_obscureApiKeys;
                            });
                          },
                          icon: Icon(
                            _obscureApiKeys
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 18,
                          ),
                          label: Text(_obscureApiKeys ? 'Show' : 'Hide'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...LlmProvider.values.map((provider) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextField(
                            controller: _apiKeyControllers[provider],
                            obscureText: _obscureApiKeys,
                            decoration: InputDecoration(
                              labelText: provider.displayName,
                              hintText: 'Enter ${provider.name} API key',
                              prefixIcon: Icon(
                                _selectedProvider == provider
                                    ? Icons.check_circle
                                    : Icons.key,
                                color: _selectedProvider == provider
                                    ? Colors.green
                                    : null,
                              ),
                              border: const OutlineInputBorder(),
                              suffixIcon: _selectedProvider == provider
                                  ? const Chip(
                                      label: Text('Active'),
                                      backgroundColor: Colors.green,
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Advanced Settings
            _buildSectionHeader('Advanced'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'API Base URL',
                        hintText: '/.netlify/functions',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                        helperText: 'Leave default for Netlify deployment',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Section
            _buildSectionHeader('About AI Commentary'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.smart_toy,
                      'Personality',
                      'Each variant has a unique AI personality that comments on moves',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.psychology,
                      'Barsoomian Warrior',
                      'Jetan features dramatic Martian warrior commentary',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.account_balance,
                      'Court Chronicler',
                      'Hyderabad Chess has an 18th-century Indian chronicler',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.school,
                      'Grand Master',
                      'Grand Chess features refined strategic commentary',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Future Auth Section (placeholder)
            _buildSectionHeader('Authentication'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: const Text('Sign In / Sign Up'),
                      subtitle: const Text('Coming soon - connect your account'),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: false,
                      onTap: () {
                        // Placeholder for future auth flow
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Account integration will allow syncing settings '
                        'and game history across devices.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
