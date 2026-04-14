import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../evaluations/data/models/evaluation_model.dart';
import '../../../placements/data/models/placement_model.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import '../pages/logbook_review_page.dart';


// Provider for student details
final studentDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, studentId) async {
  // Get student profile
  final studentDoc = await FirebaseFirestore.instance
      .collection('students')
      .doc(studentId)
      .get();

  // Get placement
  final placementSnapshot = await FirebaseFirestore.instance
      .collection('placements')
      .where('studentId', isEqualTo: studentId)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .get();

  PlacementModel? placement;
  if (placementSnapshot.docs.isNotEmpty) {
    placement = PlacementModel.fromFirestore(placementSnapshot.docs.first, null);
  }

  // Get university supervisor
  Map<String, dynamic>? universitySupervisor;
  if (studentDoc.data()?['currentSupervisorId'] != null) {
    final supervisorDoc = await FirebaseFirestore.instance
        .collection('supervisorProfiles')
        .doc(studentDoc.data()!['currentSupervisorId'])
        .get();
    universitySupervisor = supervisorDoc.data();
  }

  return {
    'student': studentDoc.data(),
    'studentId': studentId,
    'placement': placement,
    'universitySupervisor': universitySupervisor,
  };
});

// Provider for student's logbook entries
final studentLogbooksProvider = StreamProvider.family<List<LogbookEntryModel>, String>((ref, studentId) {
  return FirebaseFirestore.instance
      .collection('logbookEntries')
      .where('studentId', isEqualTo: studentId)
      .orderBy('weekNumber', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => LogbookEntryModel.fromFirestore(doc, null))
            .toList();
      });
});

final placementCompanyEvaluationProvider =
    StreamProvider.family<EvaluationModel?, String>((ref, placementId) {
  return FirebaseFirestore.instance
      .collection('evaluations')
      .where('placementId', isEqualTo: placementId)
      .where(
        'evaluatorType',
        isEqualTo: EvaluationType.companySupervisor.name,
      )
      .snapshots()
      .map((snapshot) {
        final evaluations = snapshot.docs
            .map((doc) => EvaluationModel.fromFirestore(doc, null))
            .toList()
          ..sort((a, b) {
            final aDate = a.submittedAt ?? a.createdAt ?? DateTime(1970);
            final bDate = b.submittedAt ?? b.createdAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });

        if (evaluations.isEmpty) {
          return null;
        }
        return evaluations.first;
      });
});

class StudentDetailsPage extends ConsumerWidget {
  final String studentId;

  const StudentDetailsPage({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailsAsync = ref.watch(studentDetailsProvider(studentId));
    final logbooksAsync = ref.watch(studentLogbooksProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
      ),
      body: detailsAsync.when(
        data: (details) {
          final student = details['student'] as Map<String, dynamic>?;
          final placement = details['placement'] as PlacementModel?;
          final universitySupervisor = details['universitySupervisor'] as Map<String, dynamic>?;
          final companyEvaluationAsync = placement == null
              ? null
              : ref.watch(placementCompanyEvaluationProvider(placement.id));

          if (student == null) {
            return const Center(child: Text('Student not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Profile Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            student['fullName']?[0]?.toUpperCase() ?? 'S',
                            style: TextStyle(
                              fontSize: 32,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          student['fullName'] ?? 'Unknown Student',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student['program'] ?? 'Unknown Program',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student['registrationNumber'] ?? 'N/A',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Internship Progress Card
                if (placement != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Internship Progress',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Weeks Completed',
                                  value: '${placement.weeksCompleted}',
                                  subtitle: 'of ${placement.totalWeeks}',
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  label: 'Progress',
                                  value: '${(placement.progressPercentage * 100).toInt()}%',
                                  subtitle: 'completed',
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: placement.progressPercentage,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 16),
                          if (placement.startDate != null)
                            _InfoRow(
                              'Start Date',
                              DateFormat('MMM dd, yyyy').format(placement.startDate!),
                            ),
                          if (placement.endDate != null)
                            _InfoRow(
                              'End Date',
                              DateFormat('MMM dd, yyyy').format(placement.endDate!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // University Supervisor Card
                if (universitySupervisor != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'University Supervisor',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          _InfoRow('Name', universitySupervisor['fullName'] ?? 'N/A'),
                          _InfoRow('Email', universitySupervisor['email'] ?? 'N/A'),
                          _InfoRow('Department', universitySupervisor['department'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Logbook Entries Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weekly Logbooks',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            logbooksAsync.when(
                              data: (logbooks) {
                                final pendingCount = logbooks
                                    .where((l) => !l.isReviewedByCompanySupervisor)
                                    .length;
                                if (pendingCount == 0) return const SizedBox.shrink();
                                return Chip(
                                  label: Text('$pendingCount pending'),
                                  backgroundColor: Colors.orange,
                                  labelStyle: const TextStyle(color: Colors.white),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        logbooksAsync.when(
                          data: (logbooks) {
                            if (logbooks.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No logbook entries yet'),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: logbooks.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final logbook = logbooks[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: logbook.isReviewedByCompanySupervisor
                                        ? Colors.green
                                        : Colors.orange,
                                    child: Text(
                                      'W${logbook.weekNumber}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'Week ${logbook.weekNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    logbook.isReviewedByCompanySupervisor
                                        ? 'Reviewed - Rating: ${logbook.companySupervisorRating ?? 'N/A'}/5'
                                        : 'Pending Review',
                                  ),
                                  trailing: logbook.isReviewedByCompanySupervisor
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : const Icon(Icons.pending, color: Colors.orange),
                                  onTap: () {
                                    // TODO: Navigate to review page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LogbookReviewPage(
                                          logbookId: logbook.id!,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('Error: $error'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (placement != null) ...[
                  const SizedBox(height: 16),
                  if (companyEvaluationAsync == null)
                    _buildAssessmentCard(context, placement, null, theme)
                  else
                    companyEvaluationAsync.when(
                      data: (evaluation) => _buildAssessmentCard(
                        context,
                        placement,
                        evaluation,
                        theme,
                      ),
                      loading: () => const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (error, _) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Error loading assessment: $error'),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(
    BuildContext context,
    PlacementModel placement,
    EvaluationModel? evaluation,
    ThemeData theme,
  ) {
    final isUnlocked = placement.isFinalAssessmentUnlocked;
    final hasSubmitted = evaluation != null;
    final statusColor = hasSubmitted
        ? Colors.green
        : isUnlocked
            ? Colors.deepOrange
            : Colors.blueGrey;
    final statusLabel = hasSubmitted
        ? 'Submitted'
        : isUnlocked
            ? 'Ready'
            : 'Not Open Yet';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Final Assessment',
                  style: theme.textTheme.titleLarge?.copyWith(
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
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              hasSubmitted
                  ? 'The final workplace assessment has already been submitted for this student.'
                  : isUnlocked
                      ? 'The internship has reached the assessment stage. You can now submit the final evaluation.'
                      : 'This assessment becomes available after the final internship week or end date.',
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            if (evaluation != null) ...[
              const SizedBox(height: 16),
              _InfoRow(
                'Score',
                '${evaluation.finalMarks.toStringAsFixed(1)}/100',
              ),
              if (evaluation.submittedAt != null)
                _InfoRow(
                  'Submitted',
                  DateFormat('MMM dd, yyyy').format(evaluation.submittedAt!),
                ),
              if (evaluation.evaluatorName != null &&
                  evaluation.evaluatorName!.trim().isNotEmpty)
                _InfoRow('Evaluator', evaluation.evaluatorName!),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: !isUnlocked || hasSubmitted
                    ? null
                    : () => context.go(
                          '/company-supervisor/evaluate/${placement.id}/$studentId',
                        ),
                icon: Icon(
                  hasSubmitted
                      ? Icons.check_circle_outline
                      : Icons.assignment_outlined,
                ),
                label: Text(
                  hasSubmitted
                      ? 'Assessment Submitted'
                      : isUnlocked
                          ? 'Open Assessment Form'
                          : 'Available After Internship',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
