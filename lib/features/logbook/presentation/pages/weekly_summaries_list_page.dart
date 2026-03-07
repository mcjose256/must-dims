// lib/features/logbook/presentation/pages/weekly_summaries_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../controllers/logbook_controller.dart' as logbook_ctrl;
import '../../data/models/weekly_logbook_summary_model.dart';
import 'weekly_summary_form_page.dart';
import 'weekly_summary_details_page.dart';

class WeeklySummariesListPage extends ConsumerWidget {
  const WeeklySummariesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(logbook_ctrl.weeklySummariesProvider);
    final theme = Theme.of(context);

    return summariesAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.summarize_outlined,
                        size: 56,
                        color: theme.colorScheme.primary.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 20),
                  Text('No Weekly Summaries Yet',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a week of daily entries, then\nsubmit your first weekly summary.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    // ── FIX: first summary is always week 1 ──────────────
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const WeeklySummaryFormPage(weekNumber: 1),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Week 1 Summary'),
                  ),
                ],
              ),
            ),
          );
        }

        // summaries are ordered descending — .first = highest week number
        // next week = highest existing + 1
        final nextWeekNumber = summaries.first.weekNumber + 1;

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(logbook_ctrl.weeklySummariesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: summaries.length,
            itemBuilder: (context, index) =>
                _WeeklySummaryCard(summary: summaries[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(logbook_ctrl.weeklySummariesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WEEKLY SUMMARY CARD
// ============================================================================

class _WeeklySummaryCard extends ConsumerWidget {
  final WeeklyLogbookSummaryModel summary;
  const _WeeklySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WeeklySummaryDetailsPage(summary: summary),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Week ${summary.weekNumber}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${DateFormat('MMM d').format(summary.weekStartDate)} – '
                      '${DateFormat('MMM d').format(summary.weekEndDate)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  _StatusBadge(status: summary.status),
                ],
              ),
              const SizedBox(height: 12),

              // ── Overview preview ───────────────────────────────────
              Text(
                summary.weeklyOverview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),

              // ── Stats row ──────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.totalHoursWorked}h',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.event_note,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.dailyEntryIds.length} days',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),

              // ── Review badges ──────────────────────────────────────
              if (summary.isReviewedByCompanySupervisor ||
                  summary.isReviewedByUniversitySupervisor) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (summary.isReviewedByCompanySupervisor)
                      _ReviewBadge(
                          label: 'Company ✓', color: Colors.green),
                    if (summary.isReviewedByUniversitySupervisor)
                      _ReviewBadge(
                          label: 'University ✓', color: Colors.blue),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SMALL WIDGETS
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        label = 'DRAFT';
        break;
      case 'submitted':
        color = Colors.orange;
        label = 'PENDING';
        break;
      case 'reviewed':
        color = Colors.green;
        label = 'REVIEWED';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ReviewBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}