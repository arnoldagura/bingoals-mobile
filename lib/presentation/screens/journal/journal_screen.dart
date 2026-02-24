import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/typography.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/providers/journal_provider.dart';
import '../../widgets/common/gradient_mesh_background.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final journalAsync = ref.watch(journalProvider);

    return GradientMeshScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(cs: cs),
            Expanded(
              child: journalAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('Could not load journal',
                          style: AppTypography.bodyMedium
                              .copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(journalProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return _EmptyState(cs: cs);
                  }
                  return _Timeline(entries: entries, cs: cs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ColorScheme cs;
  const _Header({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Journal',
            style: AppTypography.displaySmall.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            'Timeline of milestones & reflections',
            style: AppTypography.bodySmall.copyWith(
              color: cs.onSurface.withValues(alpha: 0.45),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline ────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final List<JournalEntry> entries;
  final ColorScheme cs;

  const _Timeline({required this.entries, required this.cs});

  @override
  Widget build(BuildContext context) {
    // Group entries by calendar date.
    final groups = <String, List<JournalEntry>>{};
    for (final e in entries) {
      final key = DateFormat('yyyy-MM-dd').format(e.timestamp.toLocal());
      groups.putIfAbsent(key, () => []).add(e);
    }
    final dateKeys = groups.keys.toList(); // already sorted newest-first

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: dateKeys.length,
      itemBuilder: (context, gi) {
        final dayEntries = groups[dateKeys[gi]]!;
        final date = DateTime.parse(dateKeys[gi]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateLabel(date: date, cs: cs),
            ...dayEntries.map((e) => _EntryCard(entry: e, cs: cs)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ─── Date label ──────────────────────────────────────────────────────────────

class _DateLabel extends StatelessWidget {
  final DateTime date;
  final ColorScheme cs;

  const _DateLabel({required this.date, required this.cs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    String label;
    if (d == today) {
      label = 'Today';
    } else if (d == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: cs.onSurface.withValues(alpha: 0.4),
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Entry card ──────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final ColorScheme cs;

  const _EntryCard({required this.entry, required this.cs});

  Color _dotColor() {
    switch (entry.type) {
      case 'goal_completed':
        return const Color(0xFF4CAF50);
      case 'milestone_reached':
        return const Color(0xFF2196F3);
      case 'reflection_added':
        return const Color(0xFFFF7043);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _typeLabel() {
    switch (entry.type) {
      case 'goal_completed':
        return 'GOAL COMPLETED';
      case 'milestone_reached':
        return 'MILESTONE REACHED';
      case 'reflection_added':
        return 'REFLECTION';
      default:
        return 'EVENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dot = _dotColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge row
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _typeLabel(),
                  style: AppTypography.caption.copyWith(
                    color: dot,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('h:mm a').format(entry.timestamp.toLocal()),
                  style: AppTypography.caption.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Goal title
            Text(
              entry.goalTitle.isNotEmpty ? entry.goalTitle : entry.boardTitle,
              style: AppTypography.headlineSmall.copyWith(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Board label
            if (entry.boardTitle.isNotEmpty && entry.goalTitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                entry.boardTitle,
                style: AppTypography.caption.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
            // Content (reflection text or milestone title)
            if (entry.content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.07),
                  ),
                ),
                child: Text(
                  '"${entry.content}"',
                  style: AppTypography.bodyMedium.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            // Image
            if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: entry.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            // Navigate to board button
            if (entry.boardId.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => context.push('/board/${entry.boardId}'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'View board',
                      style: AppTypography.caption.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyState({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Your story starts here',
              style: AppTypography.headlineSmall.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete goals and add reflections\nto build your journal.',
              style: AppTypography.bodyMedium.copyWith(
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
