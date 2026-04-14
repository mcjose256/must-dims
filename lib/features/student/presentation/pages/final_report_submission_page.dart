import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/student_controllers.dart';
import '../../data/models/internship_report_model.dart';
import '../../../placements/data/models/placement_model.dart';

class FinalReportSubmissionPage extends ConsumerStatefulWidget {
  const FinalReportSubmissionPage({super.key});

  @override
  ConsumerState<FinalReportSubmissionPage> createState() =>
      _FinalReportSubmissionPageState();
}

class _FinalReportSubmissionPageState
    extends ConsumerState<FinalReportSubmissionPage> {
  File? _selectedFile;
  String? _selectedFileName;
  bool _isSubmitting = false;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;
    if (file.size > 10 * 1024 * 1024) {
      _showMessage('PDF too large. Maximum size is 10MB.', isError: true);
      return;
    }

    setState(() {
      _selectedFile = File(file.path!);
      _selectedFileName = file.name;
    });
  }

  bool _isReportUnlocked(PlacementModel placement) {
    if (placement.status == PlacementStatus.completed) return true;
    if (placement.weeksCompleted >= placement.totalWeeks) return true;

    final endDate = placement.endDate;
    if (endDate == null) return false;

    final today = DateTime.now();
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return !todayDay.isBefore(endDay);
  }

  Future<void> _submitReport(
    PlacementModel placement,
    InternshipReportModel? existingReport,
  ) async {
    if (!_isReportUnlocked(placement)) {
      _showMessage('Final report opens at the end of the internship.',
          isError: true);
      return;
    }
    if (_selectedFile == null || _selectedFileName == null) {
      _showMessage('Select a PDF report first.', isError: true);
      return;
    }
    if (existingReport?.isApproved == true) {
      _showMessage('This report has already been approved.', isError: true);
      return;
    }
    if (existingReport?.isSubmitted == true) {
      _showMessage('This report is already awaiting review.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final storagePath =
          'final_reports/${user.uid}_${placement.id}_${DateTime.now().millisecondsSinceEpoch}_${_selectedFileName!}';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      await storageRef.putFile(_selectedFile!);
      final downloadUrl = await storageRef.getDownloadURL();

      final payload = {
        'studentId': user.uid,
        'placementId': placement.id,
        'fileName': _selectedFileName,
        'fileUrl': downloadUrl,
        'status': 'submitted',
        'supervisorFeedback': null,
        'reviewedBy': null,
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'createdAt': existingReport == null
            ? FieldValue.serverTimestamp()
            : existingReport.createdAt != null
                ? Timestamp.fromDate(existingReport.createdAt!)
                : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final reports = FirebaseFirestore.instance.collection('internshipReports');
      if (existingReport != null) {
        await reports.doc(existingReport.id).set(payload, SetOptions(merge: true));
      } else {
        await reports.add(payload);
      }

      if (!mounted) return;
      _showMessage('Final report submitted.');
      context.pop();
    } catch (e) {
      _showMessage('Submission failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage('Invalid PDF link.', isError: true);
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showMessage('Unable to open the PDF.', isError: true);
    }
  }

  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    _showMessage('Link copied.');
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placementAsync = ref.watch(currentPlacementProvider);
    final reportAsync = ref.watch(finalInternshipReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Report'),
      ),
      body: placementAsync.when(
        data: (placement) {
          if (placement == null) {
            return const Center(child: Text('No active placement.'));
          }

          return reportAsync.when(
            data: (report) {
              final isUnlocked = _isReportUnlocked(placement);
              final canSubmit = report == null || report.isRejected;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatusCard(
                    placement: placement,
                    report: report,
                    isUnlocked: isUnlocked,
                  ),
                  const SizedBox(height: 16),
                  if (report != null) ...[
                    _ExistingSubmissionCard(
                      report: report,
                      onOpen: () => _openPdf(report.fileUrl),
                      onCopy: () => _copyLink(report.fileUrl),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            canSubmit ? 'Upload PDF' : 'Submission Locked',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: canSubmit ? _pickPdf : null,
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(
                              _selectedFileName ?? 'Choose PDF',
                            ),
                          ),
                          if (_selectedFileName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _selectedFileName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSubmitting || !canSubmit
                                  ? null
                                  : () => _submitReport(placement, report),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file_outlined),
                              label: Text(
                                _isSubmitting
                                    ? 'Submitting...'
                                    : report?.isRejected == true
                                        ? 'Resubmit Report'
                                        : 'Submit Report',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error loading report: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error loading placement: $error'),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final PlacementModel placement;
  final InternshipReportModel? report;
  final bool isUnlocked;

  const _StatusCard({
    required this.placement,
    required this.report,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = report == null
        ? (isUnlocked ? 'Ready' : 'Not yet open')
        : report!.isApproved
            ? 'Approved'
            : report!.isRejected
                ? 'Returned'
                : 'Under review';
    final statusColor = report == null
        ? (isUnlocked ? Colors.green : Colors.orange)
        : report!.isApproved
            ? Colors.green
            : report!.isRejected
                ? Colors.red
                : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Final Internship Report',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isUnlocked
                  ? 'Submit the final PDF report for supervisor review.'
                  : 'This opens after the internship end date or final week.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (report?.supervisorFeedback != null &&
                report!.supervisorFeedback!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
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
                    Text(report!.supervisorFeedback!),
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

class _ExistingSubmissionCard extends StatelessWidget {
  final InternshipReportModel report;
  final VoidCallback onOpen;
  final VoidCallback onCopy;

  const _ExistingSubmissionCard({
    required this.report,
    required this.onOpen,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(
          report.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          report.submittedAt != null
              ? 'Submitted ${report.submittedAt!.day}/${report.submittedAt!.month}/${report.submittedAt!.year}'
              : 'Submitted',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open PDF',
            ),
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copy link',
            ),
          ],
        ),
      ),
    );
  }
}
