import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../logbook/data/models/logbook_entry_model.dart';
import '../../controllers/supervisor_controller.dart';

class LogbookEntryReviewScreen extends ConsumerStatefulWidget {
  final LogbookEntryModel entry;

  const LogbookEntryReviewScreen({super.key, required this.entry});

  @override
  ConsumerState<LogbookEntryReviewScreen> createState() =>
      _LogbookEntryReviewScreenState();
}

class _LogbookEntryReviewScreenState
    extends ConsumerState<LogbookEntryReviewScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _commentController.text = widget.entry.universitySupervisorComment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _processReview(bool isApproved) async {
    if (!isApproved && _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a short reason before returning this logbook.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final controller = ref.read(supervisorControllerProvider);
      if (isApproved) {
        await controller.approveLogbookEntry(
          widget.entry.id!,
          _commentController.text,
        );
      } else {
        await controller.rejectLogbookEntry(
          widget.entry.id!,
          _commentController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final isReviewed = entry.isReviewedByUniversitySupervisor;
    final status = entry.status.toLowerCase();
    final isApproved = isReviewed && status != 'rejected';

    return Scaffold(
      appBar: AppBar(
        title: Text('Week ${entry.weekNumber} Logbook'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${entry.weekNumber}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${DateFormat('MMM d, yyyy').format(entry.weekStartDate)} - ${DateFormat('MMM d, yyyy').format(entry.weekEndDate)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.schedule_outlined,
                              label:
                                  '${entry.hoursWorked.toStringAsFixed(entry.hoursWorked.truncateToDouble() == entry.hoursWorked ? 0 : 1)} hours',
                            ),
                            _InfoChip(
                              icon: Icons.attach_file,
                              label:
                                  '${entry.attachmentUrls.length} attachment${entry.attachmentUrls.length == 1 ? '' : 's'}',
                            ),
                            _InfoChip(
                              icon: isApproved
                                  ? Icons.check_circle
                                  : status == 'rejected'
                                      ? Icons.cancel
                                      : Icons.hourglass_top,
                              label: isApproved
                                  ? 'Approved'
                                  : status == 'rejected'
                                      ? 'Returned'
                                      : 'Submitted',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ReviewSection(
                  title: 'Activities Performed',
                  content: entry.activitiesPerformed,
                ),
                if (entry.skillsLearned != null &&
                    entry.skillsLearned!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ReviewSection(
                    title: 'Skills Learned',
                    content: entry.skillsLearned!,
                  ),
                ],
                if (entry.challengesFaced != null &&
                    entry.challengesFaced!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ReviewSection(
                    title: 'Challenges Faced',
                    content: entry.challengesFaced!,
                  ),
                ],
                if (entry.attachmentUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachments',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.attachmentUrls
                                .asMap()
                                .entries
                                .map(
                                  (item) => Chip(
                                    avatar: const Icon(
                                      Icons.attachment,
                                      size: 16,
                                    ),
                                    label: Text('File ${item.key + 1}'),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReviewed ? 'Supervisor Feedback' : 'Review',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            labelText: 'Comment',
                            hintText:
                                'Add approval notes or any correction request',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                          readOnly: isReviewed,
                        ),
                        if (entry.isReviewedByCompanySupervisor &&
                            entry.companySupervisorComment != null &&
                            entry.companySupervisorComment!.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Company Feedback',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(entry.companySupervisorComment!),
                        ],
                        if (isReviewed) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                isApproved
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 18,
                                color: isApproved
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isApproved
                                    ? 'This logbook has been approved.'
                                    : 'This logbook was returned for update.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isApproved
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isReviewed) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _processReview(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Return'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _processReview(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final String content;

  const _ReviewSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
