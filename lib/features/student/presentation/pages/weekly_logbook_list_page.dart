import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../logbook/data/models/logbook_entry_model.dart';
import '../../controllers/student_controllers.dart';

class WeeklyLogbookListPage extends ConsumerStatefulWidget {
  const WeeklyLogbookListPage({super.key});

  @override
  ConsumerState<WeeklyLogbookListPage> createState() =>
      _WeeklyLogbookListPageState();
}

class _WeeklyLogbookListPageState extends ConsumerState<WeeklyLogbookListPage> {
  String _searchQuery = '';

  List<Map<String, dynamic>> _filterEntries(List<Map<String, dynamic>> entries) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return entries;

    return entries.where((entryData) {
      final entry = entryData['entry'] as LogbookEntryModel;
      final text = [
        'week ${entry.weekNumber}',
        _formatWeekRange(entry),
        entry.status,
        entry.activitiesPerformed,
        entry.skillsLearned ?? '',
        entry.challengesFaced ?? '',
        entry.universitySupervisorComment ?? '',
        entry.companySupervisorComment ?? '',
      ].join(' ').toLowerCase();

      return text.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(logbookEntriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Logbook'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/student/submit-logbook'),
        icon: const Icon(Icons.summarize_outlined),
        label: const Text('New Weekly Log'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _CreateWeeklySummaryCard(
              onTap: () => context.push('/student/submit-logbook'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search weekly logbooks',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                final filteredEntries = _filterEntries(entries);

                if (entries.isEmpty) {
                  return _EmptyState(
                    icon: Icons.summarize_outlined,
                    title: 'No weekly logbooks',
                    description: 'Submit a weekly summary from your daily logs.',
                    actionLabel: 'Add Weekly Log',
                    onTap: () => context.push('/student/submit-logbook'),
                  );
                }

                if (filteredEntries.isEmpty) {
                  return const _SearchEmptyState(
                    title: 'No matching weekly logbooks',
                    description: 'Try another search term.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(logbookEntriesProvider);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      return _WeeklyLogbookCard(
                        entry: filteredEntries[index]['entry']
                            as LogbookEntryModel,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _LoadErrorState(
                title: 'Unable to load weekly logbooks',
                details: '$error',
                onRetry: () {
                  ref.invalidate(logbookEntriesProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateWeeklySummaryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateWeeklySummaryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Weekly Summary',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generate from daily logs, edit the summary, then add pictures before submitting.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.summarize_outlined),
                label: const Text('Generate Weekly Summary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatWeekRange(LogbookEntryModel entry) {
  final startDay = entry.weekStartDate.day.toString().padLeft(2, '0');
  final startMonth = entry.weekStartDate.month.toString().padLeft(2, '0');
  final endDay = entry.weekEndDate.day.toString().padLeft(2, '0');
  final endMonth = entry.weekEndDate.month.toString().padLeft(2, '0');
  return '$startDay/$startMonth/${entry.weekStartDate.year} - '
      '$endDay/$endMonth/${entry.weekEndDate.year}';
}

String _formatWeeklyHours(double hours) {
  return hours.toStringAsFixed(
    hours.truncateToDouble() == hours ? 0 : 1,
  );
}

class _WeeklyLogbookCard extends StatelessWidget {
  final LogbookEntryModel entry;

  const _WeeklyLogbookCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusInfo = _statusInfo(entry);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusInfo.color.withOpacity(0.12),
                  child: Text(
                    'W${entry.weekNumber}',
                    style: TextStyle(
                      color: statusInfo.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week ${entry.weekNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatWeekRange(entry),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  label: statusInfo.label,
                  color: statusInfo.color,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              entry.activitiesPerformed,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.schedule_outlined,
                  label: '${_formatWeeklyHours(entry.hoursWorked)} hrs',
                ),
                _InfoPill(
                  icon: Icons.attach_file,
                  label:
                      '${entry.attachmentUrls.length} attachment${entry.attachmentUrls.length == 1 ? '' : 's'}',
                ),
                _InfoPill(
                  icon: entry.isReviewedByCompanySupervisor
                      ? Icons.business
                      : Icons.business_outlined,
                  label: entry.isReviewedByCompanySupervisor
                      ? 'Company reviewed'
                      : 'Company pending',
                ),
                _InfoPill(
                  icon: entry.isReviewedByUniversitySupervisor
                      ? Icons.school
                      : Icons.school_outlined,
                  label: entry.isReviewedByUniversitySupervisor
                      ? 'Supervisor reviewed'
                      : 'Supervisor pending',
                ),
              ],
            ),
            if (entry.universitySupervisorComment != null &&
                entry.universitySupervisorComment!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _FeedbackPanel(
                title: 'Supervisor Feedback',
                message: entry.universitySupervisorComment!,
                color: statusInfo.color,
              ),
            ],
            if (entry.companySupervisorComment != null &&
                entry.companySupervisorComment!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _FeedbackPanel(
                title: 'Company Feedback',
                message: entry.companySupervisorComment!,
                color: Colors.blueGrey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(LogbookEntryModel entry) {
    final status = entry.status.toLowerCase();
    if (status == 'rejected') {
      return const _StatusInfo(label: 'Returned', color: Colors.red);
    }
    if (status == 'approved') {
      return const _StatusInfo(label: 'Approved', color: Colors.green);
    }
    return const _StatusInfo(label: 'Submitted', color: Colors.orange);
  }
}

class _StatusInfo {
  final String label;
  final Color color;

  const _StatusInfo({
    required this.label,
    required this.color,
  });
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  final String title;
  final String message;
  final Color color;

  const _FeedbackPanel({
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String title;
  final String description;

  const _SearchEmptyState({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  final String title;
  final String details;
  final VoidCallback onRetry;

  const _LoadErrorState({
    required this.title,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              details,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
