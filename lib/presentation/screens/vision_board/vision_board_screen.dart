import 'package:cached_network_image/cached_network_image.dart';
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
            final boards = <String, String>{};
            for (final item in items) {
              boards[item.boardId] = item.boardTitle;
            }

            final filtered = items.where((item) {
              if (_filter == 'all') return true;
              if (_filter == 'completed') return item.isComplete;
              return item.boardId == _filter;
            }).toList();

            filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Build layout rows: groups of 3 → 1 full-width + pair of 2
            final rows = _buildRows(filtered);

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
                          '"Collect moments, not things."',
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
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

                // ── Gallery or empty state ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyGallery(colorScheme: colorScheme),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final row = rows[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildRow(context, row, colorScheme),
                          );
                        },
                        childCount: rows.length,
                      ),
                    ),
                  ),
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

  /// Groups items into rows: every 3 items → [featured, small, small]
  List<_GalleryRow> _buildRows(List<GalleryItem> items) {
    final rows = <_GalleryRow>[];
    int i = 0;
    while (i < items.length) {
      final featured = items[i];
      final pair = <GalleryItem>[];
      if (i + 1 < items.length) pair.add(items[i + 1]);
      if (i + 2 < items.length) pair.add(items[i + 2]);
      rows.add(_GalleryRow(featured: featured, pair: pair));
      i += 3;
    }
    return rows;
  }

  Widget _buildRow(
      BuildContext context, _GalleryRow row, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full-width featured card
        _FeaturedCard(
          item: row.featured,
          colorScheme: colorScheme,
          onTap: () => context.push('/boards/${row.featured.boardId}'),
        ),
        if (row.pair.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              for (int j = 0; j < row.pair.length; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(
                  child: _SmallCard(
                    item: row.pair[j],
                    index: j,
                    colorScheme: colorScheme,
                    onTap: () =>
                        context.push('/boards/${row.pair[j].boardId}'),
                  ),
                ),
              ],
              // If only one item in pair, add an empty placeholder
              if (row.pair.length == 1) ...[
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _GalleryRow {
  final GalleryItem featured;
  final List<GalleryItem> pair;

  _GalleryRow({required this.featured, required this.pair});
}

// ── Featured (full-width) card ─────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final GalleryItem item;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.item,
    required this.colorScheme,
    required this.onTap,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: Colors.grey.shade100,
                            ),
                            errorWidget: (_, _, _) =>
                                _PhotoPlaceholder(colorScheme: colorScheme),
                          )
                        : _PhotoPlaceholder(colorScheme: colorScheme),
                  ),
                ),
                // Caption strip
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label.isNotEmpty ? item.label : item.title,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatDate(item.createdAt),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black38,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (item.boardTitle.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '•',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black26),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.boardTitle.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black38,
                                  letterSpacing: 1.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tape sticker at top-center
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: 0.05,
                child: Container(
                  width: 52,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9CFC4).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small card ─────────────────────────────────────────────────────────────────

class _SmallCard extends StatelessWidget {
  final GalleryItem item;
  final int index;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  static const _kTiltAngles = <double>[-0.03, 0.025, -0.02, 0.03];

  const _SmallCard({
    required this.item,
    required this.index,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final imageUrl = hasPhoto
        ? (item.imageUrl!.startsWith('http')
            ? item.imageUrl!
            : '${ApiConstants.baseUrl}${item.imageUrl}')
        : null;

    final angle = _kTiltAngles[index % _kTiltAngles.length];

    return Transform.rotate(
      angle: angle,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(1, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Square photo
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(3),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: hasPhoto
                          ? CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: Colors.grey.shade100,
                              ),
                              errorWidget: (_, _, _) =>
                                  _PhotoPlaceholder(colorScheme: colorScheme),
                            )
                          : _PhotoPlaceholder(colorScheme: colorScheme),
                    ),
                  ),
                  // Caption
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    child: Text(
                      item.label.isNotEmpty ? item.label : item.title,
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Tape sticker
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Transform.rotate(
                  angle: index.isEven ? -0.1 : 0.08,
                  child: Container(
                    width: 36,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9CFC4).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
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
    return Container(
      color: colorScheme.onSurface.withValues(alpha: 0.04),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: colorScheme.onSurface.withValues(alpha: 0.2),
        ),
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
              'Add a photo to any goal\nand it will appear here.',
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
