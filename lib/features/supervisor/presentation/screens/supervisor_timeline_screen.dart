import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../training_schedule/controllers/training_schedule_controller.dart';
import '../../../training_schedule/data/training_schedule_item.dart';
import '../providers/supervisor_providers.dart';

class SupervisorTimelineScreen extends ConsumerWidget {
  const SupervisorTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(supervisedStudentProgressProvider);
    final scheduleItems = ref.watch(effectiveVisibleTrainingScheduleProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(supervisedStudentProgressProvider);
        ref.invalidate(trainingScheduleCollectionProvider);
      },
      child: progressAsync.when(
        data: (progressItems) {
          final supervisedCount = progressItems.length;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shared training timeline',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is the one published internship timeline used across the system.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          const _MetaChip(
                            label: 'Single shared timeline',
                            color: Colors.green,
                          ),
                          _MetaChip(
                            label:
                                '$supervisedCount supervised student${supervisedCount == 1 ? '' : 's'}',
                            color: Colors.indigo,
                          ),
                          _MetaChip(
                            label: scheduleItems.isEmpty
                                ? 'No items'
                                : 'Published',
                            color: scheduleItems.isEmpty
                                ? Colors.orange
                                : Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.timeline_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Industrial Training Schedule',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Visible to supervisors and students',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            label: 'Shared timeline',
                            color: Colors.blue,
                          ),
                          _MetaChip(
                            label: 'Published items',
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (scheduleItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'No timeline available.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        ...List.generate(scheduleItems.length, (index) {
                          final item = scheduleItems[index];
                          final isLast = index == scheduleItems.length - 1;
                          return _SupervisorTimelineTile(
                            index: index + 1,
                            entry: item,
                            showConnector: !isLast,
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            _MessageState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load timeline',
              description: '$error',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleAppearance {
  final IconData icon;
  final Color color;

  const _ScheduleAppearance({
    required this.icon,
    required this.color,
  });
}

const _scheduleAppearances = [
  _ScheduleAppearance(icon: Icons.campaign_rounded, color: Colors.indigo),
  _ScheduleAppearance(icon: Icons.search_rounded, color: Colors.blue),
  _ScheduleAppearance(
    icon: Icons.assignment_returned_rounded,
    color: Colors.deepPurple,
  ),
  _ScheduleAppearance(icon: Icons.groups_rounded, color: Colors.teal),
  _ScheduleAppearance(icon: Icons.work_history_rounded, color: Colors.green),
  _ScheduleAppearance(icon: Icons.looks_one_rounded, color: Colors.orange),
  _ScheduleAppearance(icon: Icons.drafts_rounded, color: Colors.amber),
  _ScheduleAppearance(icon: Icons.looks_two_rounded, color: Colors.deepOrange),
  _ScheduleAppearance(icon: Icons.picture_as_pdf_rounded, color: Colors.red),
  _ScheduleAppearance(icon: Icons.fact_check_rounded, color: Colors.brown),
  _ScheduleAppearance(icon: Icons.summarize_rounded, color: Colors.blueGrey),
];

_ScheduleAppearance _scheduleAppearanceForIndex(int index) {
  return _scheduleAppearances[index % _scheduleAppearances.length];
}

class _SupervisorTimelineTile extends StatelessWidget {
  const _SupervisorTimelineTile({
    required this.index,
    required this.entry,
    required this.showConnector,
  });

  final int index;
  final TrainingScheduleItem entry;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = _scheduleAppearanceForIndex(index - 1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appearance.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: appearance.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: appearance.color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: appearance.color.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: appearance.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          appearance.icon,
                          color: appearance.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: appearance.color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                entry.dateRange,
                                style: TextStyle(
                                  color: appearance.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'In charge: ${entry.personInCharge}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  if ((entry.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      entry.description!.trim(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
