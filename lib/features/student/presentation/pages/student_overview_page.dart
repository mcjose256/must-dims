// lib/features/student/presentation/pages/student_overview_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../logbook/data/models/logbook_entry_model.dart';
import '../../controllers/student_controllers.dart';
import '../../data/models/student_profile_model.dart';
import '../../presentation/student_dashboard.dart';
import '../../../placements/data/models/placement_model.dart';
import '../../../training_schedule/controllers/training_schedule_controller.dart';
import '../../../training_schedule/data/training_schedule_item.dart';

const _approvedTimelineStatuses = {
  PlacementStatus.approved,
  PlacementStatus.active,
  PlacementStatus.completed,
  PlacementStatus.extended,
};

class StudentOverviewPage extends ConsumerWidget {
  const StudentOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);
    final placementAsync = ref.watch(currentPlacementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileProvider);
          ref.invalidate(currentPlacementProvider);
          ref.invalidate(logbookEntriesProvider);
          ref.invalidate(trainingScheduleCollectionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Header ──────────────────────────────────────────
              _buildWelcomeHeader(context, profileAsync, theme),
              const SizedBox(height: 20),

              // ── Progress / Status Card ──────────────────────────────────
              _buildStatusCard(
                  context, ref, profileAsync, placementAsync, theme),
              const SizedBox(height: 20),

              // ── Quick Actions (dynamic per stage) ──────────────────────
              _buildIndustrialTrainingSchedule(
                ref,
                placementAsync,
                theme,
              ),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDynamicQuickActions(
                  context, ref, profileAsync, placementAsync),

              const SizedBox(height: 24),

              // ── Recent Activity ─────────────────────────────────────────
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildRecentActivity(context, ref),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Welcome header ──────────────────────────────────────────────────────

  Widget _buildWelcomeHeader(
    BuildContext context,
    AsyncValue<StudentProfileModel?> profileAsync,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              profileAsync.when(
                data: (profile) => Text(
                  profile?.fullName ?? 'Student',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Student'),
              ),
              profileAsync.when(
                data: (profile) => Text(
                  profile?.registrationNumber ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        profileAsync.when(
          data: (profile) =>
              _InternshipStatusBadge(status: profile?.internshipStatus),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  // ── Status / progress card ──────────────────────────────────────────────

  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<StudentProfileModel?> profileAsync,
    AsyncValue<PlacementModel?> placementAsync,
    ThemeData theme,
  ) {
    final approvedCount = ref.watch(approvedLogbookCountProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up,
                    color: theme.colorScheme.primary, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Internship Progress',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              data: (profile) {
                final status = profile?.internshipStatus ??
                    StudentInternshipStatus.notStarted;
                final placement = placementAsync.value;
                final placementProgress = placement != null
                    ? placement.progressPercentage * 100
                    : null;
                final progress =
                    placementProgress ?? profile?.progressPercentage ?? 0.0;

                if (status == StudentInternshipStatus.notStarted) {
                  return _buildNotStartedContent(theme);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$approvedCount weeks approved',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          '${progress.toStringAsFixed(0)}% complete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 10,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    placementAsync.when(
                      data: (placement) {
                        if (placement == null) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Icon(Icons.business_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              '${placement.weeksCompleted}/${placement.totalWeeks} weeks at company',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading progress'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotStartedContent(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Upload your acceptance letter to begin the internship process.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Dynamic quick actions ───────────────────────────────────────────────

  /// Returns context-aware quick actions based on the student's current stage.
  Widget _buildIndustrialTrainingSchedule(
    WidgetRef ref,
    AsyncValue<PlacementModel?> placementAsync,
    ThemeData theme,
  ) {
    return placementAsync.when(
      data: (placement) {
        if (placement == null ||
            !_approvedTimelineStatuses.contains(placement.status)) {
          return const SizedBox.shrink();
        }

        final scheduleItems =
            ref.watch(effectiveVisibleTrainingScheduleProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                                'Shared timeline for all interns',
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ScheduleTag(
                          label: 'Shared timeline',
                          color: theme.colorScheme.primary,
                        ),
                        _ScheduleTag(
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
                        final entry = scheduleItems[index];
                        final isLast = index == scheduleItems.length - 1;
                        return _ScheduleTimelineTile(
                          index: index + 1,
                          entry: entry,
                          showConnector: !isLast,
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDynamicQuickActions(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<StudentProfileModel?> profileAsync,
    AsyncValue<PlacementModel?> placementAsync,
  ) {
    return profileAsync.when(
      data: (profile) {
        final status =
            profile?.internshipStatus ?? StudentInternshipStatus.notStarted;
        final placement = placementAsync.value;
        final effectiveStatus = placement?.status == PlacementStatus.completed
            ? StudentInternshipStatus.completed
            : status;

        switch (effectiveStatus) {
          // ── Stage 1: Not started — nudge to upload ──────────────────────
          case StudentInternshipStatus.notStarted:
            return _QuickActionsGrid(actions: [
              _QuickAction(
                icon: Icons.upload_file_rounded,
                title: 'Upload Letter',
                subtitle: 'Start process',
                color: Colors.blue,
                onTap: () => context.go('/student/upload-letter'),
              ),
              _QuickAction(
                icon: Icons.business_outlined,
                title: 'Internship',
                subtitle: 'View details',
                color: Colors.grey,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 2,
              ),
              _QuickAction(
                icon: Icons.person_outlined,
                title: 'Profile',
                subtitle: 'Edit info',
                color: Colors.purple,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 3,
              ),
            ]);

          // ── Stage 2: Awaiting approval ──────────────────────────────────
          case StudentInternshipStatus.awaitingApproval:
            return _QuickActionsGrid(actions: [
              _QuickAction(
                icon: Icons.visibility_outlined,
                title: 'View Status',
                subtitle: 'Track application',
                color: Colors.orange,
                onTap: () => context.go('/student/placement-status'),
              ),
              _QuickAction(
                icon: Icons.business_outlined,
                title: 'Internship',
                subtitle: 'View details',
                color: Colors.teal,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 2,
              ),
              _QuickAction(
                icon: Icons.person_outlined,
                title: 'Profile',
                subtitle: 'Edit info',
                color: Colors.purple,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 3,
              ),
            ]);

          // ── Stage 3: In progress — full logbook actions ─────────────────
          case StudentInternshipStatus.inProgress:
            return _QuickActionsGrid(actions: [
              _QuickAction(
                icon: Icons.add_circle_outline,
                title: 'Daily Log',
                subtitle: 'Add today',
                color: Colors.blue,
                onTap: () => context.push('/student/submit-daily-logbook'),
              ),
              _QuickAction(
                icon: Icons.summarize_outlined,
                title: 'Weekly Log',
                subtitle: 'Submit week',
                color: Colors.green,
                onTap: () => context.push('/student/submit-logbook'),
              ),
              _QuickAction(
                icon: Icons.book_outlined,
                title: 'Logbook',
                subtitle: 'View entries',
                color: Colors.teal,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 1,
              ),
              _QuickAction(
                icon: Icons.business_outlined,
                title: 'Internship',
                subtitle: 'View details',
                color: Colors.orange,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 2,
              ),
            ]);

          // ── Stage 4: Completed ──────────────────────────────────────────
          case StudentInternshipStatus.completed:
            return _QuickActionsGrid(actions: [
              _QuickAction(
                icon: Icons.book_outlined,
                title: 'Weekly Logbook',
                subtitle: 'View all',
                color: Colors.green,
                onTap: () => context.push('/student/logbook/weekly'),
              ),
              _QuickAction(
                icon: Icons.assessment_outlined,
                title: 'Evaluation',
                subtitle: 'View results',
                color: Colors.orange,
                onTap: () => context.push('/student/assessment'),
              ),
              _QuickAction(
                icon: Icons.person_outlined,
                title: 'Profile',
                subtitle: 'Edit info',
                color: Colors.purple,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 3,
              ),
            ]);

          default:
            return _QuickActionsGrid(actions: [
              _QuickAction(
                icon: Icons.business_outlined,
                title: 'Internship',
                subtitle: 'View details',
                color: Colors.teal,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 2,
              ),
              _QuickAction(
                icon: Icons.person_outlined,
                title: 'Profile',
                subtitle: 'Edit info',
                color: Colors.purple,
                onTap: () =>
                    ref.read(selectedStudentTabProvider.notifier).state = 3,
              ),
            ]);
        }
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Recent activity ─────────────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(logbookEntriesProvider);
    final theme = Theme.of(context);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No logbook entries yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your recent submissions will appear here',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: entries.take(3).map((entryData) {
            final entry = entryData['entry'] as LogbookEntryModel;
            return _ActivityTile(entry: entry, ref: ref);
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(
        'Error loading recent activity',
        style: TextStyle(color: Colors.red.shade400),
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _ScheduleAppearance {
  final IconData icon;
  final Color color;

  const _ScheduleAppearance({
    required this.icon,
    required this.color,
  });
}

class _ScheduleTag extends StatelessWidget {
  const _ScheduleTag({
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

class _ScheduleTimelineTile extends StatelessWidget {
  const _ScheduleTimelineTile({
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
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
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
              margin: const EdgeInsets.only(bottom: 14),
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

class _InternshipStatusBadge extends StatelessWidget {
  final StudentInternshipStatus? status;

  const _InternshipStatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final s = status ?? StudentInternshipStatus.notStarted;
    Color color;
    String label;

    switch (s) {
      case StudentInternshipStatus.inProgress:
        color = Colors.blue;
        label = 'In Progress';
        break;
      case StudentInternshipStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case StudentInternshipStatus.awaitingApproval:
        color = Colors.orange;
        label = 'Pending';
        break;
      case StudentInternshipStatus.deferred:
        color = Colors.amber;
        label = 'Deferred';
        break;
      case StudentInternshipStatus.terminated:
        color = Colors.red;
        label = 'Terminated';
        break;
      case StudentInternshipStatus.notStarted:
      default:
        color = Colors.grey;
        label = 'Not Started';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
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

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionsGrid extends StatelessWidget {
  final List<_QuickAction> actions;

  const _QuickActionsGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    // Always use 2 columns — prevents cramped single-row layouts
    // childAspectRatio: 1.1 gives enough height for icon + title + subtitle
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: actions.map((a) => _QuickActionCard(action: a)).toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, size: 24, color: action.color),
              ),
              const SizedBox(height: 10),
              Text(
                action.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final LogbookEntryModel entry;
  final WidgetRef ref;

  const _ActivityTile({required this.entry, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = entry.status.toLowerCase();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          'Week ${entry.weekNumber}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${entry.weekStartDate.day}/${entry.weekStartDate.month}/${entry.weekStartDate.year} • ${entry.status.toUpperCase()}',
          style: TextStyle(
              fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: theme.colorScheme.onSurfaceVariant),
        onTap: () => ref.read(selectedStudentTabProvider.notifier).state = 1,
      ),
    );
  }
}
