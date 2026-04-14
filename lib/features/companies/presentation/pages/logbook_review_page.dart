import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../logbook/data/models/logbook_entry_model.dart';

// Provider for logbook entry details
final logbookEntryProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, logbookId) {
  return FirebaseFirestore.instance
      .collection('logbookEntries')
      .doc(logbookId)
      .snapshots()
      .asyncMap((doc) async {
        if (!doc.exists) {
          throw Exception('Logbook entry not found');
        }

        final logbook = LogbookEntryModel.fromFirestore(doc, null);

        // Get student details
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(logbook.studentId)
            .get();

        // Get placement details
        final placementDoc = await FirebaseFirestore.instance
            .collection('placements')
            .doc(logbook.placementId)
            .get();

        return {
          'logbook': logbook,
          'student': studentDoc.data(),
          'placement': placementDoc.data(),
        };
      });
});

class LogbookReviewPage extends ConsumerStatefulWidget {
  final String logbookId;

  const LogbookReviewPage({
    super.key,
    required this.logbookId,
  });

  @override
  ConsumerState<LogbookReviewPage> createState() => _LogbookReviewPageState();
}

class _LogbookReviewPageState extends ConsumerState<LogbookReviewPage> {
  final _commentController = TextEditingController();
  int _rating = 0;
  int? _codeQualityRating;
  int? _problemSolvingRating;
  int? _initiativeRating;
  int? _communicationRating;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(LogbookEntryModel logbook) async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an overall rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide feedback comments'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('logbookEntries')
          .doc(widget.logbookId)
          .update({
        'isReviewedByCompanySupervisor': true,
        'companySupervisorComment': _commentController.text.trim(),
        'companySupervisorRating': _rating,
        'codeQualityRating': _codeQualityRating,
        'problemSolvingRating': _problemSolvingRating,
        'initiativeRating': _initiativeRating,
        'communicationRating': _communicationRating,
        'companyReviewedAt': FieldValue.serverTimestamp(),
        'status': logbook.isReviewedByUniversitySupervisor
            ? 'approved'
            : logbook.status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text('Review Submitted!'),
            content: const Text(
              'Your feedback has been submitted successfully. The student will be notified.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous page
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryAsync = ref.watch(logbookEntryProvider(widget.logbookId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Logbook Entry'),
      ),
      body: entryAsync.when(
        data: (data) {
          final logbook = data['logbook'] as LogbookEntryModel;
          final student = data['student'] as Map<String, dynamic>?;

          // Pre-fill if already reviewed
          if (logbook.isReviewedByCompanySupervisor && _rating == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _rating = logbook.companySupervisorRating ?? 0;
                _codeQualityRating = logbook.codeQualityRating;
                _problemSolvingRating = logbook.problemSolvingRating;
                _initiativeRating = logbook.initiativeRating;
                _communicationRating = logbook.communicationRating;
                _commentController.text = logbook.companySupervisorComment ?? '';
              });
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            student?['fullName']?[0]?.toUpperCase() ?? 'S',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student?['fullName'] ?? 'Unknown Student',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Week ${logbook.weekNumber} • ${DateFormat('MMM dd - dd, yyyy').format(logbook.weekStartDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Logbook Content
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${logbook.weekNumber} Report',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _SectionHeader('Activities Performed'),
                        const SizedBox(height: 8),
                        Text(logbook.activitiesPerformed),
                        const SizedBox(height: 16),
                        if (logbook.skillsLearned != null && logbook.skillsLearned!.isNotEmpty) ...[
                          _SectionHeader('Skills Learned'),
                          const SizedBox(height: 8),
                          Text(logbook.skillsLearned!),
                          const SizedBox(height: 16),
                        ],
                        if (logbook.challengesFaced != null && logbook.challengesFaced!.isNotEmpty) ...[
                          _SectionHeader('Challenges Faced'),
                          const SizedBox(height: 8),
                          Text(logbook.challengesFaced!),
                          const SizedBox(height: 16),
                        ],
                        _SectionHeader('Hours Worked'),
                        const SizedBox(height: 8),
                        Text('${logbook.hoursWorked} hours'),
                        if (logbook.attachmentUrls.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionHeader('Attachments'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: logbook.attachmentUrls.map((url) {
                              return Chip(
                                avatar: const Icon(Icons.attachment, size: 16),
                                label: const Text('View Attachment'),
                                onDeleted: () {
                                  // TODO: Open attachment
                                },
                                deleteIcon: const Icon(Icons.open_in_new, size: 16),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Review Form
                if (!logbook.isReviewedByCompanySupervisor) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Feedback',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          
                          // Overall Rating
                          _SectionHeader('Overall Performance Rating *'),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < _rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 36,
                                ),
                                onPressed: () {
                                  setState(() => _rating = index + 1);
                                },
                              );
                            }),
                          ),
                          if (_rating > 0)
                            Text(
                              _getRatingText(_rating),
                              style: TextStyle(
                                color: _getRatingColor(_rating),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Specific Ratings (Optional)
                          _SectionHeader('Detailed Ratings (Optional)'),
                          const SizedBox(height: 12),
                          _RatingRow(
                            'Code Quality',
                            _codeQualityRating,
                            (rating) => setState(() => _codeQualityRating = rating),
                          ),
                          _RatingRow(
                            'Problem Solving',
                            _problemSolvingRating,
                            (rating) => setState(() => _problemSolvingRating = rating),
                          ),
                          _RatingRow(
                            'Initiative',
                            _initiativeRating,
                            (rating) => setState(() => _initiativeRating = rating),
                          ),
                          _RatingRow(
                            'Communication',
                            _communicationRating,
                            (rating) => setState(() => _communicationRating = rating),
                          ),
                          const SizedBox(height: 24),

                          // Comments
                          _SectionHeader('Comments & Feedback *'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Provide detailed feedback on the student\'s performance this week...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _submitReview(logbook),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Submit Review'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Already Reviewed
                  Card(
                    color: Colors.green.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Already Reviewed',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _SectionHeader('Your Rating'),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (logbook.companySupervisorRating ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          _SectionHeader('Your Comments'),
                          const SizedBox(height: 8),
                          Text(logbook.companySupervisorComment ?? 'No comments'),
                          const SizedBox(height: 16),
                          Text(
                            'Reviewed on: ${logbook.companyReviewedAt != null ? DateFormat('MMM dd, yyyy').format(logbook.companyReviewedAt!) : 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // University Supervisor Review (if exists)
                if (logbook.isReviewedByUniversitySupervisor) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'University Supervisor Feedback',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Text('Rating: '),
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < (logbook.universitySupervisorRating ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (logbook.universitySupervisorComment != null)
                            Text(logbook.universitySupervisorComment!),
                        ],
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

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating == 3) return Colors.orange;
    return Colors.green;
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int? rating;
  final Function(int?) onRatingChanged;

  const _RatingRow(this.label, this.rating, this.onRatingChanged);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label),
          ),
          ...List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < (rating ?? 0) ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              ),
              onPressed: () {
                onRatingChanged(index + 1);
              },
            );
          }),
          if (rating != null)
            TextButton(
              onPressed: () => onRatingChanged(null),
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }
}
