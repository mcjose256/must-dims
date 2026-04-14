import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../logbook/controllers/logbook_controller.dart' as legacy_logbook;
import '../../controllers/student_controllers.dart';
import '../../data/models/student_profile_model.dart';

class LogbookPage extends ConsumerWidget {
  const LogbookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(studentProfileProvider);
    final placementAsync = ref.watch(currentPlacementProvider);
    final weeklyEntriesAsync = ref.watch(logbookEntriesProvider);
    final dailyEntriesAsync = ref.watch(legacy_logbook.dailyEntriesProvider);
    final pendingCount = ref.watch(pendingLogbookCountProvider);
    final approvedCount = ref.watch(approvedLogbookCountProvider);

    return profileAsync.when(
      data: (profile) {
        final status =
            profile?.internshipStatus ?? StudentInternshipStatus.notStarted;

        if (status == StudentInternshipStatus.notStarted ||
            status == StudentInternshipStatus.awaitingApproval ||
            status == StudentInternshipStatus.rejected) {
          return _buildNotStartedState(context, theme, status);
        }

        final dailyEntries = dailyEntriesAsync.value ?? [];
        final weeklyEntries = weeklyEntriesAsync.value ?? [];
        final dailyCount = dailyEntries.length;
        final weeklyCount = weeklyEntries.length;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentPlacementProvider);
            ref.invalidate(logbookEntriesProvider);
            ref.invalidate(legacy_logbook.dailyEntriesProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              placementAsync.when(
                data: (placement) {
                  final weeksCompleted = placement?.weeksCompleted ?? 0;
                  final totalWeeks = placement?.totalWeeks ?? 12;
                  final progressRatio =
                      (placement?.progressPercentage ?? 0.0)
                          .clamp(0.0, 1.0)
                          .toDouble();

                  return _LogbookSummaryCard(
                    weeksCompleted: weeksCompleted,
                    totalWeeks: totalWeeks,
                    progressRatio: progressRatio,
                    dailyCount: dailyCount,
                    weeklyCount: weeklyCount,
                    pendingCount: pendingCount,
                    approvedCount: approvedCount,
                  );
                },
                loading: () => _LogbookSummaryCard(
                  weeksCompleted: 0,
                  totalWeeks: 12,
                  progressRatio: 0,
                  dailyCount: dailyCount,
                  weeklyCount: weeklyCount,
                  pendingCount: pendingCount,
                  approvedCount: approvedCount,
                ),
                error: (_, __) => _LogbookSummaryCard(
                  weeksCompleted: approvedCount,
                  totalWeeks: 12,
                  progressRatio: (approvedCount / 12).clamp(0.0, 1.0),
                  dailyCount: dailyCount,
                  weeklyCount: weeklyCount,
                  pendingCount: pendingCount,
                  approvedCount: approvedCount,
                ),
              ),
              const SizedBox(height: 16),
              _LogbookRouteCard(
                icon: Icons.edit_note_rounded,
                color: Colors.blue,
                title: 'Daily Logbook',
                subtitle: 'View, search and manage daily entries.',
                chips: [
                  _RouteChipData(label: '$dailyCount entries'),
                  if (dailyEntries.isNotEmpty)
                    _RouteChipData(
                      label:
                          'Latest ${_formatShortDate(dailyEntries.first.date)}',
                    ),
                ],
                primaryLabel: 'Open Daily',
                onPrimaryTap: () => context.push('/student/logbook/daily'),
                secondaryLabel: 'New Entry',
                onSecondaryTap: () =>
                    context.push('/student/submit-daily-logbook'),
              ),
              const SizedBox(height: 12),
              _LogbookRouteCard(
                icon: Icons.summarize_outlined,
                color: Colors.green,
                title: 'Weekly Logbook',
                subtitle: 'Review weekly submissions and feedback.',
                chips: [
                  _RouteChipData(label: '$weeklyCount entries'),
                  _RouteChipData(label: '$approvedCount approved'),
                  _RouteChipData(label: '$pendingCount pending'),
                ],
                primaryLabel: 'View Entries',
                onPrimaryTap: () => context.push('/student/logbook/weekly'),
                secondaryLabel: 'Create Weekly',
                onSecondaryTap: () => context.push('/student/submit-logbook'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading logbook')),
    );
  }

  Widget _buildNotStartedState(
    BuildContext context,
    ThemeData theme,
    StudentInternshipStatus status,
  ) {
    const bottomActionClearance = 112.0;
    final isPending = status == StudentInternshipStatus.awaitingApproval;
    final isRejected = status == StudentInternshipStatus.rejected;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            32,
            32,
            32,
            bottomActionClearance,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > bottomActionClearance
                  ? constraints.maxHeight - bottomActionClearance
                  : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.shade50
                        : isRejected
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPending
                        ? Icons.hourglass_top
                        : isRejected
                            ? Icons.cancel_outlined
                            : Icons.book_outlined,
                    size: 56,
                    color: isPending
                        ? Colors.orange.shade400
                        : isRejected
                            ? Colors.red.shade400
                            : Colors.blue.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isPending
                      ? 'Awaiting Approval'
                      : isRejected
                          ? 'Letter Needs Revision'
                          : 'Logbook Not Available',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isPending
                      ? 'Daily and weekly logbooks open after your placement is approved.'
                      : isRejected
                          ? 'Revise your acceptance letter before continuing.'
                          : 'Upload and secure approval for your acceptance letter first.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (status == StudentInternshipStatus.notStarted)
                  FilledButton.icon(
                    onPressed: () => context.go('/student/upload-letter'),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload Acceptance Letter'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => context.go('/student/placement-status'),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View Status'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatShortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _LogbookSummaryCard extends StatelessWidget {
  final int weeksCompleted;
  final int totalWeeks;
  final double progressRatio;
  final int dailyCount;
  final int weeklyCount;
  final int pendingCount;
  final int approvedCount;

  const _LogbookSummaryCard({
    required this.weeksCompleted,
    required this.totalWeeks,
    required this.progressRatio,
    required this.dailyCount,
    required this.weeklyCount,
    required this.pendingCount,
    required this.approvedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (progressRatio * 100).round();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Logbook',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$progressPercent%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Daily entries feed the weekly logbook.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$weeksCompleted of $totalWeeks weeks logged',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Daily',
                    value: '$dailyCount',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryStat(
                    label: 'Weekly',
                    value: '$weeklyCount',
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Pending',
                    value: '$pendingCount',
                    color: pendingCount > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryStat(
                    label: 'Approved',
                    value: '$approvedCount',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogbookRouteCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<_RouteChipData> chips;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String secondaryLabel;
  final VoidCallback onSecondaryTap;

  const _LogbookRouteCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map((chip) => _RouteChip(label: chip.label, color: color))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrimaryTap,
                    child: Text(primaryLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onSecondaryTap,
                    child: Text(secondaryLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteChipData {
  final String label;

  const _RouteChipData({required this.label});
}

class _RouteChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RouteChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
