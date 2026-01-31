import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/game_service.dart';

/// Home screen with variant selection
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = ref.watch(variantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeirdChess'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.grid_on,
                    size: 64,
                    color: Colors.brown,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose a Variant',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classic and variant chess with unique pieces',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),

            // Variant cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: variants.length,
                itemBuilder: (context, index) {
                  final variant = variants[index];
                  return _VariantCard(
                    name: variant.name,
                    description: variant.description,
                    boardSize: variant.boardSize,
                    lightColor: variant.lightSquareColor,
                    darkColor: variant.darkSquareColor,
                    onTap: () {
                      ref.read(selectedVariantProvider.notifier).select(variant);
                      ref.read(gameNotifierProvider.notifier).newGame(variant);
                      context.go('/game');
                    },
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'More variants coming soon!',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final String name;
  final String description;
  final int boardSize;
  final Color lightColor;
  final Color darkColor;
  final VoidCallback onTap;

  const _VariantCard({
    required this.name,
    required this.description,
    required this.boardSize,
    required this.lightColor,
    required this.darkColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mini board preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.brown[300]!),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    final row = index ~/ 4;
                    final col = index % 4;
                    final isLight = (row + col) % 2 == 0;
                    return Container(
                      color: isLight ? lightColor : darkColor,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${boardSize}x$boardSize board',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.brown,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
