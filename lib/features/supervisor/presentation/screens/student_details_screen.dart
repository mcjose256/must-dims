// lib/features/supervisor/presentation/screens/student_details_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../student/data/models/student_profile_model.dart';
import '../../../student/data/models/internship_report_model.dart';
import '../../../placements/data/models/placement_model.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import 'student_evaluation_screen.dart';
import 'logbook_entry_review_screen.dart';
import 'final_report_review_screen.dart';

// ============================================================================
// PROVIDERS — scoped to this student
// ============================================================================

/// Current placement for this student
final _studentPlacementProvider =
    FutureProvider.family<PlacementModel?, String>((ref, studentId) async {
  final snap = await FirebaseFirestore.instance
      .collection('placements')
      .where('studentId', isEqualTo: studentId)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .get();

  if (snap.docs.isEmpty) return null;
  return PlacementModel.fromFirestore(snap.docs.first, null);
});

/// All weekly logbook entries submitted by this student
final _studentWeeklySummariesProvider =
    StreamProvider.family<List<LogbookEntryModel>, String>(
        (ref, studentId) {
  return FirebaseFirestore.instance
      .collection('logbookEntries')
      .where('studentId', isEqualTo: studentId)
      .orderBy('weekNumber', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => LogbookEntryModel.fromFirestore(doc, null))
          .toList());
});

final _studentFinalReportProvider =
    StreamProvider.family<InternshipReportModel?, String>((ref, studentId) {
  return FirebaseFirestore.instance
      .collection('internshipReports')
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((snap) {
        final reports = snap.docs
            .map((doc) => InternshipReportModel.fromFirestore(doc, null))
            .toList()
          ..sort((a, b) {
            final aDate = a.submittedAt ?? a.createdAt ?? DateTime(1970);
            final bDate = b.submittedAt ?? b.createdAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });
        if (reports.isEmpty) return null;
        return reports.first;
      });
});

// ============================================================================
// SCREEN
// ============================================================================

class StudentDetailsScreen extends ConsumerWidget {
  final StudentProfileModel student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final placementAsync = ref.watch(_studentPlacementProvider(student.uid));
    final summariesAsync =
        ref.watch(_studentWeeklySummariesProvider(student.uid));
    final reportAsync = ref.watch(_studentFinalReportProvider(student.uid));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Student Details'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_studentPlacementProvider(student.uid));
          ref.invalidate(_studentWeeklySummariesProvider(student.uid));
          ref.invalidate(_studentFinalReportProvider(student.uid));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Student identity card ──────────────────────────────────
            _buildIdentityCard(context, theme),
            const SizedBox(height: 16),

            // ── Internship status card ─────────────────────────────────
            _buildStatusCard(context, theme),
            const SizedBox(height: 16),

            // ── Placement info ─────────────────────────────────────────
            placementAsync.when(
              data: (placement) => placement != null
                  ? _buildPlacementCard(context, placement, theme)
                  : _buildNoPlacementCard(theme),
              loading: () => const _LoadingCard(message: 'Loading placement...'),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            const SizedBox(height: 16),

            // ── Weekly logbook entries ─────────────────────────────────
            _SectionTitle(
              title: 'Logbook Submissions',
              icon: Icons.book_outlined,
              color: Colors.indigo,
            ),
            const SizedBox(height: 12),
            summariesAsync.when(
              data: (summaries) => summaries.isEmpty
                  ? _buildNoLogbooksCard(theme)
                  : _buildLogbookList(context, summaries, theme),
              loading: () =>
                  const _LoadingCard(message: 'Loading logbooks...'),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            const SizedBox(height: 16),

            _SectionTitle(
              title: 'Final Report',
              icon: Icons.assignment_outlined,
              color: Colors.teal,
            ),
            const SizedBox(height: 12),
            reportAsync.when(
              data: (report) => report == null
                  ? _buildNoFinalReportCard(theme)
                  : _buildFinalReportCard(context, report, theme),
              loading: () =>
                  const _LoadingCard(message: 'Loading final report...'),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            const SizedBox(height: 24),

            // ── Final evaluation button ────────────────────────────────
            _buildEvaluationButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Identity card ─────────────────────────────────────────────────────────

  Widget _buildIdentityCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar with initial
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                student.fullName.isNotEmpty
                    ? student.fullName[0].toUpperCase()
                    : 'S',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show fullName, not registration number
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.registrationNumber,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.program,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (student.currentLevel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Year ${student.academicYear} • ${student.currentLevel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status card ───────────────────────────────────────────────────────────

  Widget _buildStatusCard(BuildContext context, ThemeData theme) {
    final statusInfo = _getStatusInfo(student.internshipStatus);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusInfo.color.withOpacity(0.3)),
      ),
      color: statusInfo.color.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusInfo.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(statusInfo.icon,
                  color: statusInfo.color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Internship Status',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  statusInfo.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: statusInfo.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Placement card ────────────────────────────────────────────────────────

  Widget _buildPlacementCard(
      BuildContext context, PlacementModel placement, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
                icon: Icons.business_outlined,
                title: 'Placement',
                color: Colors.indigo),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _InfoRow(label: 'Company', value: placement.companyId),
            if (placement.companySupervisorName != null)
              _InfoRow(
                  label: 'Company Supervisor',
                  value: placement.companySupervisorName!),
            if (placement.startDate != null)
              _InfoRow(
                label: 'Start Date',
                value:
                    '${placement.startDate!.day}/${placement.startDate!.month}/${placement.startDate!.year}',
              ),
            _InfoRow(
                label: 'Duration', value: '${placement.totalWeeks} weeks'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlacementCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'This student has not submitted a placement letter yet.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logbook list ──────────────────────────────────────────────────────────

  Widget _buildLogbookList(BuildContext context,
      List<LogbookEntryModel> summaries, ThemeData theme) {
    // Summary stats row
    final reviewed =
        summaries.where((s) => s.isReviewedByUniversitySupervisor).length;
    final pending = summaries.length - reviewed;

    return Column(
      children: [
        // Stats row
        Row(
          children: [
            _MiniStat(
              label: 'Submitted',
              value: '${summaries.length}',
              color: Colors.indigo,
              icon: Icons.upload_outlined,
            ),
            _MiniStat(
              label: 'Reviewed',
              value: '$reviewed',
              color: Colors.green,
              icon: Icons.done_all,
            ),
            _MiniStat(
              label: 'Pending',
              value: '$pending',
              color: pending > 0 ? Colors.orange : Colors.grey,
              icon: Icons.hourglass_top_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of weekly logbooks
        ...summaries.map((summary) {
          final isReviewed = summary.isReviewedByUniversitySupervisor;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isReviewed
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isReviewed
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                child: Text(
                  'W${summary.weekNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isReviewed
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
              title: Text(
                'Week ${summary.weekNumber} Logbook',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '${summary.hoursWorked.toStringAsFixed(summary.hoursWorked.truncateToDouble() == summary.hoursWorked ? 0 : 1)}h worked • '
                '${summary.attachmentUrls.length} attachment${summary.attachmentUrls.length == 1 ? '' : 's'} • '
                '${isReviewed ? 'Reviewed ✓' : 'Pending review'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isReviewed
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isReviewed
                    ? Colors.green.shade400
                    : Colors.orange.shade400,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LogbookEntryReviewScreen(
                    entry: summary,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoLogbooksCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.indigo.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.book_outlined,
                size: 40, color: Colors.indigo.shade200),
            const SizedBox(height: 12),
            Text(
              'No logbook entries yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This student has not submitted any weekly logbooks.',
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Evaluation button ─────────────────────────────────────────────────────

  Widget _buildNoFinalReportCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.assignment_late_outlined,
                color: Colors.teal.shade400),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No final report submitted yet.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalReportCard(
    BuildContext context,
    InternshipReportModel report,
    ThemeData theme,
  ) {
    final statusColor = report.isApproved
        ? Colors.green
        : report.isRejected
            ? Colors.red
            : Colors.orange;
    final statusLabel = report.isApproved
        ? 'Approved'
        : report.isRejected
            ? 'Returned'
            : 'Submitted';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red),
        ),
        title: Text(
          report.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (report.supervisorFeedback != null &&
                report.supervisorFeedback!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  report.supervisorFeedback!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FinalReportReviewScreen(report: report),
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StudentEvaluationScreen(student: student),
          ),
        ),
        icon: const Icon(Icons.grade_outlined),
        label: const Text(
          'Submit Final Evaluation',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Status helper ─────────────────────────────────────────────────────────

  _StatusInfo _getStatusInfo(StudentInternshipStatus status) {
    switch (status) {
      case StudentInternshipStatus.notStarted:
        return _StatusInfo(
            label: 'Not Started',
            icon: Icons.pending_outlined,
            color: Colors.grey);
      case StudentInternshipStatus.awaitingApproval:
        return _StatusInfo(
            label: 'Awaiting Supervisor Review',
            icon: Icons.hourglass_top_rounded,
            color: Colors.orange);
      case StudentInternshipStatus.approved:
        return _StatusInfo(
            label: 'Approved — Ready to Begin',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green);
      case StudentInternshipStatus.rejected:
        return _StatusInfo(
            label: 'Revision Required',
            icon: Icons.cancel_outlined,
            color: Colors.red);
      case StudentInternshipStatus.inProgress:
        return _StatusInfo(
            label: 'In Progress',
            icon: Icons.play_circle_outline_rounded,
            color: Colors.blue);
      case StudentInternshipStatus.completed:
        return _StatusInfo(
            label: 'Completed',
            icon: Icons.task_alt_rounded,
            color: Colors.green);
      case StudentInternshipStatus.deferred:
        return _StatusInfo(
            label: 'Deferred',
            icon: Icons.pause_circle_outline_rounded,
            color: Colors.purple);
      case StudentInternshipStatus.terminated:
        return _StatusInfo(
            label: 'Terminated',
            icon: Icons.block_rounded,
            color: Colors.red);
    }
  }
}

// ============================================================================
// HELPER DATA CLASS
// ============================================================================

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusInfo(
      {required this.label, required this.icon, required this.color});
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String message;
  const _LoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(message,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: Colors.red.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Error: $message',
                  style: TextStyle(
                      color: Colors.red.shade700, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
