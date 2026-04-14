// lib/features/supervisor/presentation/screens/supervisor_overview_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../providers/supervisor_providers.dart';
import '../../../placements/data/models/placement_model.dart';
import '../../../student/data/models/student_profile_model.dart';
import '../../controllers/supervisor_controller.dart';
import 'student_details_screen.dart';
import 'placement_letter_review_page.dart';
import 'logbook_entry_review_screen.dart';
import 'final_report_review_screen.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final pendingLetterReviewsProvider =
    StreamProvider<List<PlacementModel>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  final uid = userAsync.value?.uid;
  if (uid == null) return const Stream.empty();

  return ref
      .read(supervisorControllerProvider)
      .getPendingLetterReviews(uid);
});

// ── FIX 1: Defined at TOP LEVEL — never inside a build() method ─────────────
// The previous version defined this FutureProvider.family inline inside
// _StudentNameLoader.build(), which caused Riverpod to create a brand new
// provider instance on every rebuild — so it never resolved and stayed
// stuck on "Loading..." forever. Top-level definition fixes this.
final _studentInfoByIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, studentId) async {
  final doc = await FirebaseFirestore.instance
      .collection('students')
      .doc(studentId)
      .get();
  return doc.data();
});

// ============================================================================
// OVERVIEW CONTENT
// ============================================================================

class SupervisorOverviewContent extends ConsumerWidget {
  const SupervisorOverviewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(supervisorProfileProvider);
    final studentsAsync = ref.watch(assignedStudentsProvider);
    final studentsProgressAsync = ref.watch(supervisedStudentProgressProvider);
    final pendingLogbooksAsync = ref.watch(pendingLogbooksProvider);
    final pendingLettersAsync = ref.watch(pendingLetterReviewsProvider);
    final pendingFinalReportsAsync = ref.watch(pendingFinalReportsProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (profile) {
        if (profile == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Supervisor Profile Not Found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account exists, but your supervisor profile '
                    'document is missing in Firestore.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(authControllerProvider).signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout and Register Again'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingLetterReviewsProvider);
            ref.invalidate(pendingLogbooksProvider);
            ref.invalidate(pendingFinalReportsProvider);
            ref.invalidate(assignedStudentsProvider);
            ref.invalidate(supervisedStudentProgressProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Welcome header ───────────────────────────────────────
              Text(
                'Welcome, ${profile.fullName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review pending items and manage your students below.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // ── Stats row ────────────────────────────────────────────
              Row(
                children: [
                  _buildStatCard(
                    context,
                    label: 'Students',
                    value: '${profile.currentLoad}',
                    color: Colors.blue,
                    icon: Icons.people_outline,
                  ),
                  _buildStatCard(
                    context,
                    label: 'Capacity Left',
                    value: '${profile.maxStudents - profile.currentLoad}',
                    color: Colors.green,
                    icon: Icons.space_dashboard_outlined,
                  ),
                  pendingLettersAsync.when(
                    data: (letters) => _buildStatCard(
                      context,
                      label: 'Letters',
                      value: '${letters.length}',
                      color: letters.isEmpty ? Colors.grey : Colors.deepOrange,
                      icon: Icons.mark_email_unread_outlined,
                    ),
                    loading: () => _buildStatCard(
                      context,
                      label: 'Letters',
                      value: '…',
                      color: Colors.grey,
                      icon: Icons.mark_email_unread_outlined,
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Student Progress Snapshot',
                icon: Icons.insights_outlined,
                color: Colors.indigo,
              ),
              const SizedBox(height: 12),
              studentsProgressAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return _EmptyState(
                      icon: Icons.timeline_outlined,
                      message: 'No supervised students to track yet',
                      color: Colors.indigo,
                    );
                  }

                  final activeCount =
                      items.where((item) => item.isInProgress).length;
                  final awaitingStartCount =
                      items.where((item) => item.isAwaitingStart).length;
                  final completedCount =
                      items.where((item) => item.isCompleted).length;

                  return Row(
                    children: [
                      _buildStatCard(
                        context,
                        label: 'Active',
                        value: '$activeCount',
                        color: Colors.blue,
                        icon: Icons.play_circle_outline_rounded,
                      ),
                      _buildStatCard(
                        context,
                        label: 'Awaiting Start',
                        value: '$awaitingStartCount',
                        color: Colors.orange,
                        icon: Icons.hourglass_top_rounded,
                      ),
                      _buildStatCard(
                        context,
                        label: 'Completed',
                        value: '$completedCount',
                        color: Colors.green,
                        icon: Icons.task_alt_rounded,
                      ),
                    ],
                  );
                },
                loading: () => const _LoadingCard(
                  message: 'Loading student progress...',
                ),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 28),

              // ── SECTION 1: Pending acceptance letter reviews ─────────
              _SectionTitle(
                title: 'Pending Acceptance Letters',
                icon: Icons.mark_email_unread_outlined,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 12),
              pendingLettersAsync.when(
                data: (letters) => letters.isEmpty
                    ? _EmptyState(
                        icon: Icons.mark_email_read_outlined,
                        message: 'No letters awaiting review',
                        color: Colors.deepOrange,
                      )
                    : Column(
                        children: letters
                            .map((p) => _LetterReviewCard(placement: p))
                            .toList(),
                      ),
                loading: () =>
                    const _LoadingCard(message: 'Loading pending letters...'),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 28),

              // ── SECTION 2: Pending weekly logbook reviews ────────────
              _SectionTitle(
                title: 'Pending Weekly Logbooks',
                icon: Icons.book_outlined,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              pendingLogbooksAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return _EmptyState(
                      icon: Icons.done_all,
                      message: 'No weekly logbooks awaiting review',
                      color: Colors.orange,
                    );
                  }

                  return Column(
                    children: entries.map((entry) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text(
                              '${entry.weekNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: _StudentNameLoader(studentId: entry.studentId),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Week ${entry.weekNumber} • ${entry.hoursWorked.toStringAsFixed(entry.hoursWorked.truncateToDouble() == entry.hoursWorked ? 0 : 1)} hours',
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LogbookEntryReviewScreen(
                                entry: entry,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const _LoadingCard(
                    message: 'Loading weekly logbooks...'),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 28),

              // ── SECTION 3: All assigned students ─────────────────────
              _SectionTitle(
                title: 'Pending Final Reports',
                icon: Icons.assignment_outlined,
                color: Colors.teal,
              ),
              const SizedBox(height: 12),
              pendingFinalReportsAsync.when(
                data: (reports) {
                  if (reports.isEmpty) {
                    return _EmptyState(
                      icon: Icons.assignment_turned_in_outlined,
                      message: 'No final reports awaiting review',
                      color: Colors.teal,
                    );
                  }

                  return Column(
                    children: reports.map((report) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.withOpacity(0.12),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.teal,
                              size: 18,
                            ),
                          ),
                          title: _StudentNameLoader(studentId: report.studentId),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              report.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FinalReportReviewScreen(
                                report: report,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const _LoadingCard(
                  message: 'Loading final reports...',
                ),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Student Progress',
                icon: Icons.show_chart_rounded,
                color: Colors.indigo,
              ),
              const SizedBox(height: 12),
              studentsProgressAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return _EmptyState(
                      icon: Icons.timeline_outlined,
                      message: 'No student progress available yet',
                      color: Colors.indigo,
                    );
                  }

                  return Column(
                    children: students.map((student) {
                      return _SupervisorStudentProgressCard(
                        progress: student,
                      );
                    }).toList(),
                  );
                },
                loading: () => const _LoadingCard(
                  message: 'Loading progress details...',
                ),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Your Students',
                icon: Icons.people_outline,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return _EmptyState(
                      icon: Icons.person_off_outlined,
                      message: 'No students assigned yet',
                      color: Colors.blue,
                    );
                  }
                  return Column(
                    children: students.map((student) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.12),
                            child: Text(
                              student.fullName.isNotEmpty
                                  ? student.fullName[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(student.fullName),
                          subtitle: Text(
                              '${student.registrationNumber} • ${student.program}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentDetailsScreen(student: student),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () =>
                    const _LoadingCard(message: 'Loading students...'),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LETTER REVIEW CARD
// ============================================================================

class _LetterReviewCard extends ConsumerWidget {
  final PlacementModel placement;

  const _LetterReviewCard({required this.placement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepOrange.shade100, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlacementLetterReviewPage(placement: placement),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description_outlined,
                    color: Colors.deepOrange.shade600, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StudentNameLoader(studentId: placement.studentId),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (placement.letterUploadedAt != null)
                    Text(
                      _formatDate(placement.letterUploadedAt!),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right,
                      color: Colors.deepOrange.shade400, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

// ============================================================================
// STUDENT NAME LOADER
// Uses the top-level _studentInfoByIdProvider — never defined inline.
// ============================================================================

class _StudentNameLoader extends ConsumerWidget {
  final String studentId;
  const _StudentNameLoader({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── FIX 1: Uses top-level provider — resolves correctly now ─────────
    final studentAsync = ref.watch(_studentInfoByIdProvider(studentId));

    return studentAsync.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data?['fullName'] ?? 'Unknown Student',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            '${data?['registrationNumber'] ?? ''} • ${data?['program'] ?? ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      loading: () => const Text('Loading...'),
      error: (_, __) => const Text('Unknown Student'),
    );
  }
}

class _SupervisorStudentProgressCard extends StatelessWidget {
  final SupervisedStudentProgress progress;

  const _SupervisorStudentProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placement = progress.placement;
    final percent = progress.progressPercent.clamp(0.0, 100.0).toDouble();
    final statusInfo = _statusInfo(progress);
    final progressLabel = placement == null
        ? 'No placement record yet'
        : placement.status == PlacementStatus.completed
            ? 'Internship completed'
            : placement.status == PlacementStatus.approved
                ? 'Placement approved and ready to begin'
                : '${placement.weeksCompleted}/${placement.totalWeeks} weeks completed';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailsScreen(student: progress.student),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusInfo.color.withOpacity(0.12),
                    child: Text(
                      progress.student.fullName.isNotEmpty
                          ? progress.student.fullName[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: statusInfo.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.student.fullName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${progress.student.registrationNumber} • ${progress.student.program}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: statusInfo.label,
                    color: statusInfo.color,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      progressLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusInfo.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(statusInfo.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StudentProgressStatus _statusInfo(SupervisedStudentProgress progress) {
    final placement = progress.placement;
    if (placement != null) {
      switch (placement.status) {
        case PlacementStatus.completed:
          return const _StudentProgressStatus('Completed', Colors.green);
        case PlacementStatus.active:
        case PlacementStatus.extended:
          return const _StudentProgressStatus('In Progress', Colors.blue);
        case PlacementStatus.approved:
          return const _StudentProgressStatus('Ready To Start', Colors.orange);
        case PlacementStatus.pendingSupervisorReview:
          return const _StudentProgressStatus('Awaiting Review', Colors.deepOrange);
        case PlacementStatus.rejected:
          return const _StudentProgressStatus('Needs Revision', Colors.red);
        case PlacementStatus.cancelled:
        case PlacementStatus.terminated:
          return const _StudentProgressStatus('Stopped', Colors.red);
      }
    }

    switch (progress.student.internshipStatus) {
      case StudentInternshipStatus.completed:
        return const _StudentProgressStatus('Completed', Colors.green);
      case StudentInternshipStatus.inProgress:
        return const _StudentProgressStatus('In Progress', Colors.blue);
      case StudentInternshipStatus.approved:
        return const _StudentProgressStatus('Ready To Start', Colors.orange);
      case StudentInternshipStatus.awaitingApproval:
        return const _StudentProgressStatus('Awaiting Review', Colors.deepOrange);
      case StudentInternshipStatus.rejected:
        return const _StudentProgressStatus('Needs Revision', Colors.red);
      case StudentInternshipStatus.deferred:
        return const _StudentProgressStatus('Deferred', Colors.purple);
      case StudentInternshipStatus.terminated:
        return const _StudentProgressStatus('Stopped', Colors.red);
      case StudentInternshipStatus.notStarted:
        return const _StudentProgressStatus('Not Started', Colors.grey);
    }
  }
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

class _StudentProgressStatus {
  final String label;
  final Color color;

  const _StudentProgressStatus(this.label, this.color);
}

// ============================================================================
// SMALL REUSABLE WIDGETS
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color.withOpacity(0.5), size: 24),
            const SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
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
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
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
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error: $message',
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
