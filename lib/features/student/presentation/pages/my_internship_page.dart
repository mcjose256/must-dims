// lib/features/student/presentation/pages/my_internship_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/student_controllers.dart';
import '../../data/models/internship_report_model.dart';
import '../../../evaluations/data/models/evaluation_model.dart';
import '../../../placements/data/models/placement_model.dart';

class MyInternshipPage extends ConsumerWidget {
  const MyInternshipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(currentPlacementProvider);
    final companyAsync = ref.watch(placementCompanyProvider);
    final supervisorAsync = ref.watch(currentSupervisorProvider);
    final finalReportAsync = ref.watch(finalInternshipReportProvider);
    final assessmentsAsync = ref.watch(currentPlacementEvaluationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentPlacementProvider);
          ref.invalidate(placementCompanyProvider);
          ref.invalidate(currentSupervisorProvider);
          ref.invalidate(finalInternshipReportProvider);
          ref.invalidate(currentPlacementEvaluationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAcademicSupervisorCard(context, supervisorAsync, theme),
              const SizedBox(height: 16),
              placementAsync.when(
                data: (placement) {
                  if (placement == null) {
                    return _buildNoPlacementCard(context, theme);
                  }
                  return _buildPlacementContent(
                    context,
                    placement,
                    companyAsync,
                    finalReportAsync,
                    assessmentsAsync,
                    theme,
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildErrorCard(context, ref, error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Academic Supervisor Card ─────────────────────────────────────────────

  Widget _buildAcademicSupervisorCard(
    BuildContext context,
    AsyncValue supervisorAsync,
    ThemeData theme,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school,
                      color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Academic Supervisor',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            supervisorAsync.when(
              data: (supervisor) {
                if (supervisor == null) {
                  return _buildNoSupervisorInfo(theme);
                }
                return Column(
                  children: [
                    _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: supervisor.fullName),
                    const SizedBox(height: 12),
                    _InfoRow(
                        icon: Icons.business_outlined,
                        label: 'Department',
                        value: supervisor.department),
                    const SizedBox(height: 12),
                    _CopyableRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: supervisor.email),
                    if (supervisor.phoneNumber != null) ...[
                      const SizedBox(height: 12),
                      _CopyableRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: supervisor.phoneNumber!),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => _buildSupervisorError(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSupervisorInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: theme.colorScheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No academic supervisor assigned yet. Contact your department.',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Error loading supervisor information',
              style: TextStyle(fontSize: 13, color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ── No placement card ────────────────────────────────────────────────────

  Widget _buildNoPlacementCard(BuildContext context, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.business_outlined,
                  size: 48, color: Colors.blue.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Placement',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t started the internship process yet. Upload your '
              'company acceptance letter to get started.',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/student/upload-letter'),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload Acceptance Letter'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Placement content ────────────────────────────────────────────────────

  Widget _buildPlacementContent(
    BuildContext context,
    PlacementModel placement,
    AsyncValue companyAsync,
    AsyncValue<InternshipReportModel?> finalReportAsync,
    AsyncValue<List<EvaluationModel>> assessmentsAsync,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusBadge(status: placement.status),
        const SizedBox(height: 16),

        if (placement.hasActiveCountdownReminder &&
            placement.internshipDaysLeft != null) ...[
          _buildCountdownReminderCard(context, placement, theme),
          const SizedBox(height: 12),
        ],

        // Company info card
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(icon: Icons.business, title: 'Company Information'),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                companyAsync.when(
                  data: (company) => Column(
                    children: [
                      _InfoRow(
                          icon: Icons.store_outlined,
                          label: 'Name',
                          value: company?.name ?? 'Unknown'),
                      const SizedBox(height: 12),
                      _InfoRow(
                          icon: Icons.category_outlined,
                          label: 'Industry',
                          value: company?.industry ?? 'N/A'),
                      const SizedBox(height: 12),
                      _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: company?.location ?? 'N/A'),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error loading company details'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Company Supervisor card
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                    icon: Icons.supervisor_account,
                    title: 'Company Supervisor'),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Name',
                    value: placement.companySupervisorName ?? 'N/A'),
                const SizedBox(height: 12),
                _CopyableRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: placement.companySupervisorEmail ?? 'N/A'),
                if (placement.companySupervisorPhone != null) ...[
                  const SizedBox(height: 12),
                  _CopyableRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: placement.companySupervisorPhone!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Supervisor feedback card — only shown when rejected
        if (placement.status == PlacementStatus.rejected &&
            placement.supervisorFeedback != null &&
            placement.supervisorFeedback!.isNotEmpty) ...[
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.red.shade200),
            ),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.feedback_outlined,
                          color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Supervisor Feedback',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    placement.supervisorFeedback!,
                    style: TextStyle(
                        fontSize: 14, color: Colors.red.shade800, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Timeline card
        if (placement.status == PlacementStatus.approved ||
            placement.status == PlacementStatus.active ||
            placement.status == PlacementStatus.completed ||
            placement.status == PlacementStatus.extended) ...[
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                      icon: Icons.schedule, title: 'Internship Timeline'),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  if (placement.startDate != null)
                    _InfoRow(
                        icon: Icons.play_arrow_outlined,
                        label: 'Start Date',
                        value: DateFormat('MMM dd, yyyy')
                            .format(placement.startDate!)),
                  if (placement.startDate != null) const SizedBox(height: 12),
                  if (placement.endDate != null)
                    _InfoRow(
                        icon: Icons.stop_circle_outlined,
                        label: 'End Date',
                        value: DateFormat('MMM dd, yyyy')
                            .format(placement.endDate!)),
                  if (placement.endDate != null) const SizedBox(height: 12),
                  _InfoRow(
                      icon: Icons.timelapse_outlined,
                      label: 'Duration',
                      value: '${placement.totalWeeks} weeks'),
                  if (placement.status == PlacementStatus.active) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${placement.weeksCompleted} / ${placement.totalWeeks} weeks',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${placement.progressPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: placement.weeksCompleted / placement.totalWeeks,
                        minHeight: 10,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SupervisorVisitsCard(placement: placement),
          const SizedBox(height: 12),
        ],

        if (placement.status == PlacementStatus.active ||
            placement.status == PlacementStatus.completed ||
            placement.status == PlacementStatus.extended) ...[
          finalReportAsync.when(
            data: (report) => _buildFinalReportCard(
              context,
              placement,
              report,
              theme,
            ),
            loading: () => Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading final report: $error'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildAssessmentStatusCard(
            context,
            placement,
            assessmentsAsync,
            theme,
          ),
          const SizedBox(height: 12),
        ],

        // Acceptance letter
        if (placement.acceptanceLetterUrl != null)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
              ),
              title: const Text('Acceptance Letter',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                placement.acceptanceLetterFileName ?? 'View document',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy link',
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: placement.acceptanceLetterUrl!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Action buttons
        if (placement.status == PlacementStatus.approved)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/student/start-internship'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start My Internship'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        if (placement.status == PlacementStatus.rejected) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/student/upload-letter'),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload New Letter'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCountdownReminderCard(
    BuildContext context,
    PlacementModel placement,
    ThemeData theme,
  ) {
    final daysLeft = placement.internshipDaysLeft!;
    final daysElapsed = placement.internshipDaysElapsed;
    final startDate = placement.effectiveReminderStartDate;
    final endDate = placement.effectiveReminderEndDate;

    final Color accentColor = daysLeft < 0
        ? Colors.red
        : daysLeft <= 7
            ? Colors.deepOrange
            : theme.colorScheme.primary;

    final String title = daysLeft < 0
        ? 'Internship timeline overdue'
        : daysLeft == 0
            ? 'Today is your final internship day'
            : '$daysLeft day${daysLeft == 1 ? '' : 's'} left to complete your internship';

    final String subtitle = daysLeft < 0
        ? 'Your planned internship period has already passed. Update your records and contact your supervisor if your attachment is continuing.'
        : daysLeft <= 7
            ? 'You are in the final stretch. Keep your daily and weekly logbooks fully updated.'
            : 'Keep making steady progress and record your work consistently before the internship period ends.';

    final String badgeText = daysLeft < 0
        ? '${daysLeft.abs()} day${daysLeft.abs() == 1 ? '' : 's'} overdue'
        : daysLeft == 0
            ? 'Ends today'
            : '$daysLeft day${daysLeft == 1 ? '' : 's'} left';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accentColor.withOpacity(0.25)),
      ),
      color: accentColor.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    daysLeft <= 7
                        ? Icons.notifications_active_rounded
                        : Icons.timer_outlined,
                    color: accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Internship Reminder',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (startDate != null)
              _InfoRow(
                icon: Icons.play_circle_outline,
                label: 'Started',
                value: DateFormat('MMM dd, yyyy').format(startDate),
              ),
            if (startDate != null && endDate != null)
              const SizedBox(height: 12),
            if (endDate != null)
              _InfoRow(
                icon: Icons.event_outlined,
                label: 'Expected End',
                value: DateFormat('MMM dd, yyyy').format(endDate),
              ),
            if ((startDate != null || endDate != null) && daysElapsed != null)
              const SizedBox(height: 12),
            if (daysElapsed != null)
              _InfoRow(
                icon: Icons.timelapse_outlined,
                label: 'Days Elapsed',
                value: '$daysElapsed day${daysElapsed == 1 ? '' : 's'}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentStatusCard(
    BuildContext context,
    PlacementModel placement,
    AsyncValue<List<EvaluationModel>> assessmentsAsync,
    ThemeData theme,
  ) {
    return assessmentsAsync.when(
      data: (evaluations) {
        EvaluationModel? companyEvaluation;
        EvaluationModel? universityEvaluation;

        for (final evaluation in evaluations) {
          if (evaluation.evaluatorType == EvaluationType.companySupervisor &&
              companyEvaluation == null) {
            companyEvaluation = evaluation;
          }
          if (evaluation.evaluatorType == EvaluationType.universitySupervisor &&
              universityEvaluation == null) {
            universityEvaluation = evaluation;
          }
        }

        final submittedCount = [
          companyEvaluation,
          universityEvaluation,
        ].whereType<EvaluationModel>().length;
        final isUnlocked = placement.isFinalAssessmentUnlocked;
        final statusColor = submittedCount == 2
            ? Colors.green
            : isUnlocked
                ? Colors.deepOrange
                : Colors.blueGrey;
        final statusLabel = submittedCount == 2
            ? 'Completed'
            : isUnlocked
                ? 'Pending'
                : 'Not Open Yet';
        final summaryText = !isUnlocked
            ? 'Final assessment becomes available after you complete the last week or reach the internship end date.'
            : submittedCount == 0
                ? 'Your supervisors have not submitted any final assessment yet.'
                : submittedCount == 1
                    ? 'One supervisor assessment has been received. The remaining one is still pending.'
                    : 'Both final assessments are now available to review.';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assessment_outlined,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Final Assessment',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  summaryText,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.verified_outlined,
                  label: 'Assessments Received',
                  value: '$submittedCount / 2',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/student/assessment'),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('View Assessment Status'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error loading assessment status: $error'),
        ),
      ),
    );
  }

  bool _isFinalReportUnlocked(PlacementModel placement) {
    if (placement.status == PlacementStatus.completed) return true;
    if (placement.weeksCompleted >= placement.totalWeeks) return true;

    final endDate = placement.endDate;
    if (endDate == null) return false;

    final today = DateTime.now();
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return !todayDay.isBefore(endDay);
  }

  Widget _buildFinalReportCard(
    BuildContext context,
    PlacementModel placement,
    InternshipReportModel? report,
    ThemeData theme,
  ) {
    final isUnlocked = _isFinalReportUnlocked(placement);
    final canSubmit = report == null || report.isRejected;
    final statusColor = report == null
        ? (isUnlocked ? Colors.green : Colors.orange)
        : report.isApproved
            ? Colors.green
            : report.isRejected
                ? Colors.red
                : Colors.orange;
    final statusText = report == null
        ? (isUnlocked ? 'Ready for submission' : 'Not open yet')
        : report.isApproved
            ? 'Approved'
            : report.isRejected
                ? 'Returned'
                : 'Under review';
    final buttonLabel = report == null
        ? 'Submit Report'
        : report.isRejected
            ? 'Resubmit Report'
            : 'View Report';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Final Report',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              report?.fileName ??
                  (isUnlocked
                      ? 'Upload your final internship report in PDF format.'
                      : 'Available after the final week or internship end date.'),
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (report?.supervisorFeedback != null &&
                report!.supervisorFeedback!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supervisor Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(report.supervisorFeedback!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (report != null || (canSubmit && isUnlocked))
                    ? () => context.push('/student/final-report')
                    : null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error card ───────────────────────────────────────────────────────────

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, Object error) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading placement: $error',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(currentPlacementProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SUPERVISOR VISITS
// ============================================================================

class _SupervisorVisitsCard extends ConsumerStatefulWidget {
  const _SupervisorVisitsCard({required this.placement});

  final PlacementModel placement;

  @override
  ConsumerState<_SupervisorVisitsCard> createState() =>
      _SupervisorVisitsCardState();
}

class _SupervisorVisitsCardState extends ConsumerState<_SupervisorVisitsCard> {
  int? _savingVisitNumber;

  Future<void> _editVisit(SupervisorVisitRecord visit) async {
    final result = await _showVisitEditor(visit);
    if (result == null) return;

    setState(() => _savingVisitNumber = visit.visitNumber);

    try {
      await ref.read(supervisorVisitControllerProvider).updateVisit(
            placement: widget.placement,
            visitNumber: visit.visitNumber,
            status: result.status,
            visitDate: result.visitDate,
            notes: result.notes,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visit ${visit.visitNumber} updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Could not update visit ${visit.visitNumber}: $error'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingVisitNumber = null);
      }
    }
  }

  Future<_VisitEditResult?> _showVisitEditor(
    SupervisorVisitRecord visit,
  ) async {
    final notesController = TextEditingController(text: visit.notes ?? '');
    var selectedStatus = visit.status;
    var selectedDate = visit.visitDate;

    try {
      return await showModalBottomSheet<_VisitEditResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final theme = Theme.of(context);

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 16,
                ),
                child: Material(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.event_note_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Visit ${visit.visitNumber}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Record whether the supervisor visit happened.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: SupervisorVisitStatus.values
                              .map(
                                (status) => ChoiceChip(
                                  label: Text(_visitStatusLabel(status)),
                                  selected: selectedStatus == status,
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedStatus = status;
                                      if (status !=
                                          SupervisorVisitStatus.visited) {
                                        selectedDate = null;
                                      }
                                      if (status ==
                                          SupervisorVisitStatus.pending) {
                                        notesController.clear();
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                        if (selectedStatus ==
                            SupervisorVisitStatus.visited) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Visit date',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );

                              if (pickedDate != null) {
                                setModalState(() => selectedDate = pickedDate);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(
                                selectedDate == null
                                    ? 'Select date'
                                    : DateFormat('MMM dd, yyyy')
                                        .format(selectedDate!),
                              ),
                            ),
                          ),
                        ],
                        if (selectedStatus !=
                            SupervisorVisitStatus.pending) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Notes',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: selectedStatus ==
                                      SupervisorVisitStatus.notVisited
                                  ? 'Optional reason or follow-up note'
                                  : 'Optional details about the visit',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop(
                                    _VisitEditResult(
                                      status: selectedStatus,
                                      visitDate: selectedStatus ==
                                              SupervisorVisitStatus.visited
                                          ? (selectedDate ?? DateTime.now())
                                          : null,
                                      notes: notesController.text.trim(),
                                    ),
                                  );
                                },
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      notesController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visits = widget.placement.supervisorVisitSlots;
    final completedCount = widget.placement.completedSupervisorVisitCount;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardHeader(
                        icon: Icons.supervisor_account_outlined,
                        title: 'Supervisor Visits',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Two university supervisor visits are usually expected during internship. Update this section after each visit.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _VisitProgressBadge(completedCount: completedCount),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ...visits.map(
              (visit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VisitStatusTile(
                  visit: visit,
                  isSaving: _savingVisitNumber == visit.visitNumber,
                  onUpdate: () => _editVisit(visit),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitStatusTile extends StatelessWidget {
  const _VisitStatusTile({
    required this.visit,
    required this.isSaving,
    required this.onUpdate,
  });

  final SupervisorVisitRecord visit;
  final bool isSaving;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _visitStatusColor(visit.status);
    final subtitle = switch (visit.status) {
      SupervisorVisitStatus.visited when visit.visitDate != null =>
        'Visited on ${DateFormat('MMM dd, yyyy').format(visit.visitDate!)}',
      SupervisorVisitStatus.visited => 'Visit recorded',
      SupervisorVisitStatus.notVisited => visit.notes?.trim().isNotEmpty == true
          ? visit.notes!.trim()
          : 'Marked as not visited',
      SupervisorVisitStatus.pending => 'Not yet recorded',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${visit.visitNumber}',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Visit ${visit.visitNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _VisitStatusChip(status: visit.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                if (visit.status == SupervisorVisitStatus.visited &&
                    visit.notes?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    visit.notes!.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: isSaving
                      ? SizedBox(
                          height: 36,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Saving...',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: onUpdate,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Update'),
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

class _VisitProgressBadge extends StatelessWidget {
  const _VisitProgressBadge({required this.completedCount});

  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final color = completedCount == 2
        ? Colors.green
        : completedCount == 1
            ? Colors.orange
            : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$completedCount / 2 done',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VisitStatusChip extends StatelessWidget {
  const _VisitStatusChip({required this.status});

  final SupervisorVisitStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _visitStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _visitStatusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _VisitEditResult {
  const _VisitEditResult({
    required this.status,
    this.visitDate,
    this.notes,
  });

  final SupervisorVisitStatus status;
  final DateTime? visitDate;
  final String? notes;
}

Color _visitStatusColor(SupervisorVisitStatus status) {
  switch (status) {
    case SupervisorVisitStatus.visited:
      return Colors.green;
    case SupervisorVisitStatus.notVisited:
      return Colors.red;
    case SupervisorVisitStatus.pending:
      return Colors.orange;
  }
}

String _visitStatusLabel(SupervisorVisitStatus status) {
  switch (status) {
    case SupervisorVisitStatus.visited:
      return 'Visited';
    case SupervisorVisitStatus.notVisited:
      return 'Not visited';
    case SupervisorVisitStatus.pending:
      return 'Pending';
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final PlacementStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      // ── New status name ────────────────────────────────────────────────
      case PlacementStatus.pendingSupervisorReview:
        color = Colors.orange;
        label = 'AWAITING SUPERVISOR REVIEW';
        break;
      case PlacementStatus.approved:
        color = Colors.green;
        label = 'APPROVED';
        break;
      case PlacementStatus.rejected:
        color = Colors.red;
        label = 'NEEDS REVISION';
        break;
      case PlacementStatus.active:
        color = Colors.blue;
        label = 'ACTIVE';
        break;
      case PlacementStatus.completed:
        color = Colors.green;
        label = 'COMPLETED';
        break;
      case PlacementStatus.cancelled:
        color = Colors.red;
        label = 'CANCELLED';
        break;
      case PlacementStatus.terminated:
        color = Colors.red;
        label = 'TERMINATED';
        break;
      case PlacementStatus.extended:
        color = Colors.purple;
        label = 'EXTENDED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CopyableRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            Icon(Icons.copy_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
