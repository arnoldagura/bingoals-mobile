import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/gallery_item.dart';
import '../../../data/providers/boards_provider.dart';

class VisionBoardScreen extends ConsumerStatefulWidget {
  const VisionBoardScreen({super.key});

  @override
  ConsumerState<VisionBoardScreen> createState() => _VisionBoardScreenState();
}

class _VisionBoardScreenState extends ConsumerState<VisionBoardScreen> {
  String _filter = 'all'; // 'all' | 'completed' | boardId

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final galleryAsync = ref.watch(galleryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: galleryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Failed to load gallery')),
          data: (items) {
            // Build board filter options from distinct boardIds
            final boards = <String, String>{}; // boardId → boardTitle
            for (final item in items) {
              boards[item.boardId] = item.boardTitle;
            }

            // Filter items
            final filtered = items.where((item) {
              if (_filter == 'all') return true;
              if (_filter == 'completed') return item.isComplete;
              return item.boardId == _filter;
            }).toList();

            // Sort newest first
            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vision Gallery',
                          style: AppTypography.displaySmall.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'A collection of moments',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Filter chips ──
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Completed',
                          selected: _filter == 'completed',
                          onTap: () =>
                              setState(() => _filter = 'completed'),
                          colorScheme: colorScheme,
                        ),
                        ...boards.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _FilterChip(
                                label: e.value,
                                selected: _filter == e.key,
                                onTap: () =>
                                    setState(() => _filter = e.key),
                                colorScheme: colorScheme,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

                // ── Grid or empty state ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyGallery(colorScheme: colorScheme),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _PolaroidCard(
                          item: filtered[index],
                          colorScheme: colorScheme,
                          onTap: () => context.push(
                            '/boards/${filtered[index].boardId}',
                          ),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                  // "That's all for now." footer
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 24),
                      child: Text(
                        "That's all for now.",
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.35),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Polaroid card ─────────────────────────────────────────────────────────────

class _PolaroidCard extends StatelessWidget {
  final GalleryItem item;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PolaroidCard({
    required this.item,
    required this.colorScheme,
    required this.onTap,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final imageUrl = hasPhoto
        ? (item.imageUrl!.startsWith('http')
            ? item.imageUrl!
            : '${ApiConstants.baseUrl}${item.imageUrl}')
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area (polaroid top)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                ),
                child: hasPhoto
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) =>
                            _PhotoPlaceholder(colorScheme: colorScheme),
                      )
                    : _PhotoPlaceholder(colorScheme: colorScheme),
              ),
            ),

            // Polaroid label strip
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.labelMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDate(item.createdAt),
                        style: AppTypography.caption.copyWith(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      if (item.isComplete)
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: Color(0xFF7CA982),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _PhotoPlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected
                ? colorScheme.surface
                : colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyGallery extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyGallery({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_album_outlined,
              size: 56,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No memories yet',
              style: AppTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a photo to any milestone\nand it will appear here.',
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
