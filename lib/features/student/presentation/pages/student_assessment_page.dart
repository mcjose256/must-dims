import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../controllers/student_controllers.dart';
import '../../../evaluations/data/models/evaluation_model.dart';
import '../../../placements/data/models/placement_model.dart';

class StudentAssessmentPage extends ConsumerWidget {
  const StudentAssessmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final placementAsync = ref.watch(currentPlacementProvider);
    final evaluationsByType =
        ref.watch(currentPlacementEvaluationsByTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Internship Assessment'),
      ),
      body: placementAsync.when(
        data: (placement) {
          if (placement == null) {
            return _EmptyAssessmentState(
              icon: Icons.assignment_late_outlined,
              title: 'No internship record found',
              message:
                  'Your final assessment will appear here once your internship placement is active.',
            );
          }

          final companyEvaluation =
              evaluationsByType[EvaluationType.companySupervisor];
          final universityEvaluation =
              evaluationsByType[EvaluationType.universitySupervisor];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AssessmentOverviewCard(
                placement: placement,
                companyEvaluation: companyEvaluation,
                universityEvaluation: universityEvaluation,
              ),
              const SizedBox(height: 16),
              _AssessmentCard(
                title: 'Company Supervisor Assessment',
                accentColor: Colors.teal,
                icon: Icons.apartment_rounded,
                placement: placement,
                emptyMessage:
                    'Your company supervisor will submit the final workplace assessment after the internship period.',
                evaluation: companyEvaluation,
              ),
              const SizedBox(height: 16),
              _AssessmentCard(
                title: 'University Supervisor Assessment',
                accentColor: Colors.indigo,
                icon: Icons.school_outlined,
                placement: placement,
                emptyMessage:
                    'Your university supervisor will submit the academic assessment after reviewing your internship completion.',
                evaluation: universityEvaluation,
              ),
              const SizedBox(height: 24),
              Text(
                'Assessment scores are submitted by supervisors and become visible here automatically.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EmptyAssessmentState(
          icon: Icons.error_outline,
          title: 'Unable to load assessment',
          message: '$error',
        ),
      ),
    );
  }
}

class _AssessmentOverviewCard extends StatelessWidget {
  final PlacementModel placement;
  final EvaluationModel? companyEvaluation;
  final EvaluationModel? universityEvaluation;

  const _AssessmentOverviewCard({
    required this.placement,
    required this.companyEvaluation,
    required this.universityEvaluation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submittedCount = [
      companyEvaluation,
      universityEvaluation,
    ].whereType<EvaluationModel>().length;
    final isUnlocked = placement.isFinalAssessmentUnlocked;
    final totalScore = [
      companyEvaluation?.finalMarks,
      universityEvaluation?.finalMarks,
    ].whereType<double>().fold<double>(0, (sum, value) => sum + value);
    final averageScore =
        submittedCount == 0 ? null : (totalScore / submittedCount);

    late final Color accentColor;
    late final IconData icon;
    late final String title;
    late final String subtitle;

    if (!isUnlocked) {
      accentColor = Colors.orange;
      icon = Icons.schedule_outlined;
      title = 'Assessment opens after internship';
      subtitle =
          'Once you complete the final week or reach the internship end date, supervisor assessments will start appearing here.';
    } else if (submittedCount == 0) {
      accentColor = Colors.blue;
      icon = Icons.hourglass_top_rounded;
      title = 'Waiting for supervisor assessments';
      subtitle =
          'Your internship is now in the assessment stage. The page will update automatically when supervisors submit.';
    } else if (submittedCount == 1) {
      accentColor = Colors.deepOrange;
      icon = Icons.pending_actions_outlined;
      title = 'One assessment received';
      subtitle =
          'One supervisor has submitted a final assessment. The remaining assessment is still pending.';
    } else {
      accentColor = Colors.green;
      icon = Icons.verified_outlined;
      title = 'Assessments completed';
      subtitle =
          'Both supervisor assessments have been submitted for this internship placement.';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: accentColor.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
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
                    '$submittedCount / 2 submitted',
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
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (averageScore != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insights_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Current average score across submitted assessments',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${averageScore.toStringAsFixed(1)}/100',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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

class _AssessmentCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final IconData icon;
  final PlacementModel placement;
  final String emptyMessage;
  final EvaluationModel? evaluation;

  const _AssessmentCard({
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.placement,
    required this.emptyMessage,
    required this.evaluation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = placement.isFinalAssessmentUnlocked;
    final statusText = evaluation != null
        ? 'Submitted'
        : isUnlocked
            ? 'Pending'
            : 'Not open yet';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (evaluation == null)
              Text(
                emptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Final Score',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${evaluation!.finalMarks.toStringAsFixed(1)}/100',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                              label: 'Submitted by',
                              value:
                                  evaluation!.evaluatorName?.trim().isNotEmpty ==
                                          true
                                      ? evaluation!.evaluatorName!
                                      : 'Supervisor',
                            ),
                            if (evaluation!.submittedAt != null)
                              _DetailRow(
                                label: 'Submitted on',
                                value: DateFormat('MMM dd, yyyy').format(
                                  evaluation!.submittedAt!,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        label: 'Technical',
                        value: evaluation!.technicalSkillsRating,
                        color: accentColor,
                      ),
                      _MetricChip(
                        label: 'Work Ethic',
                        value: evaluation!.workEthicRating,
                        color: accentColor,
                      ),
                      _MetricChip(
                        label: 'Communication',
                        value: evaluation!.communicationRating,
                        color: accentColor,
                      ),
                      _MetricChip(
                        label: 'Problem Solving',
                        value: evaluation!.problemSolvingRating,
                        color: accentColor,
                      ),
                      _MetricChip(
                        label: 'Initiative',
                        value: evaluation!.initiativeRating,
                        color: accentColor,
                      ),
                      _MetricChip(
                        label: 'Teamwork',
                        value: evaluation!.teamworkRating,
                        color: accentColor,
                      ),
                    ],
                  ),
                  if (evaluation!.daysPresent != null ||
                      evaluation!.daysAbsent != null ||
                      evaluation!.wouldHireAgain != null) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    if (evaluation!.daysPresent != null)
                      _DetailRow(
                        label: 'Days Present',
                        value: '${evaluation!.daysPresent}',
                      ),
                    if (evaluation!.daysAbsent != null)
                      _DetailRow(
                        label: 'Days Absent',
                        value: '${evaluation!.daysAbsent}',
                      ),
                    if (evaluation!.wouldHireAgain != null)
                      _DetailRow(
                        label: 'Would Hire Again',
                        value: evaluation!.wouldHireAgain! ? 'Yes' : 'No',
                      ),
                  ],
                  if (_hasLongText(evaluation!.overallComments) ||
                      _hasLongText(evaluation!.strengthsHighlighted) ||
                      _hasLongText(evaluation!.areasForImprovement) ||
                      _hasLongText(evaluation!.recommendationsForFutureInterns) ||
                      _hasLongText(evaluation!.hiringConditions)) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    if (_hasLongText(evaluation!.overallComments))
                      _FeedbackBlock(
                        title: 'Overall Comments',
                        text: evaluation!.overallComments!,
                      ),
                    if (_hasLongText(evaluation!.strengthsHighlighted))
                      _FeedbackBlock(
                        title: 'Strengths Highlighted',
                        text: evaluation!.strengthsHighlighted!,
                      ),
                    if (_hasLongText(evaluation!.areasForImprovement))
                      _FeedbackBlock(
                        title: 'Areas for Improvement',
                        text: evaluation!.areasForImprovement!,
                      ),
                    if (_hasLongText(
                        evaluation!.recommendationsForFutureInterns))
                      _FeedbackBlock(
                        title: 'Recommendations',
                        text: evaluation!.recommendationsForFutureInterns!,
                      ),
                    if (_hasLongText(evaluation!.hiringConditions))
                      _FeedbackBlock(
                        title: 'Additional Notes',
                        text: evaluation!.hiringConditions!,
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool _hasLongText(String? value) => value != null && value.trim().isNotEmpty;
}

class _MetricChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(1)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _FeedbackBlock extends StatelessWidget {
  final String title;
  final String text;

  const _FeedbackBlock({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssessmentState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyAssessmentState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
