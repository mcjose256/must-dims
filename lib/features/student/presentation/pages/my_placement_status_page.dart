// lib/features/student/presentation/pages/my_placement_status_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../../placements/data/models/placement_model.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final studentPlacementProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('placements')
      .where('studentId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) return null;

    final placementDoc = snapshot.docs.first;
    final placement = PlacementModel.fromFirestore(placementDoc, null);

    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(placement.companyId)
        .get();

    return {
      'placement': placement,
      'company': companyDoc.data(),
    };
  });
});

// ============================================================================
// MY PLACEMENT STATUS PAGE
// ============================================================================

class MyPlacementStatusPage extends ConsumerWidget {
  const MyPlacementStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final placementAsync = ref.watch(studentPlacementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Placement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student/dashboard'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentPlacementProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: placementAsync.when(
          data: (data) {
            if (data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_center,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No Placement Yet',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                        'Upload your acceptance letter to get started'),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          context.go('/student/upload-letter'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Acceptance Letter'),
                    ),
                  ],
                ),
              );
            }

            final placement = data['placement'] as PlacementModel;
            final company = data['company'] as Map<String, dynamic>?;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  _buildStatusBanner(context, placement),
                  const SizedBox(height: 24),

                  // Supervisor feedback card — only on rejection
                  if (placement.status == PlacementStatus.rejected &&
                      placement.supervisorFeedback != null &&
                      placement.supervisorFeedback!.isNotEmpty) ...[
                    _buildFeedbackCard(placement, theme),
                    const SizedBox(height: 16),
                  ],

                  // Company Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 24),
                          _InfoRow('Company', company?['name'] ?? 'Unknown'),
                          _InfoRow(
                              'Industry', company?['industry'] ?? 'N/A'),
                          _InfoRow(
                              'Location', company?['location'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Company Supervisor Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Supervisor',
                            style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 24),
                          _InfoRow('Name',
                              placement.companySupervisorName ?? 'N/A'),
                          _InfoRow('Email',
                              placement.companySupervisorEmail ?? 'N/A'),
                          if (placement.companySupervisorPhone != null)
                            _InfoRow(
                                'Phone', placement.companySupervisorPhone!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timeline
                  if (placement.status == PlacementStatus.approved ||
                      placement.status == PlacementStatus.active ||
                      placement.status == PlacementStatus.completed) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timeline',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24),
                            if (placement.startDate != null)
                              _InfoRow(
                                'Start Date',
                                DateFormat('MMM dd, yyyy')
                                    .format(placement.startDate!),
                              ),
                            if (placement.endDate != null)
                              _InfoRow(
                                'End Date',
                                DateFormat('MMM dd, yyyy')
                                    .format(placement.endDate!),
                              ),
                            _InfoRow(
                                'Duration', '${placement.totalWeeks} weeks'),
                            if (placement.status ==
                                PlacementStatus.active) ...[
                              _InfoRow(
                                'Completed',
                                '${placement.weeksCompleted} / '
                                    '${placement.totalWeeks} weeks',
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: placement.weeksCompleted /
                                    placement.totalWeeks,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Acceptance Letter Viewer
                  _AcceptanceLetterViewer(
                    fileUrl: placement.acceptanceLetterUrl,
                    fileName: placement.acceptanceLetterFileName ??
                        'acceptance_letter',
                    uploadedAt: placement.letterUploadedAt,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (placement.status == PlacementStatus.approved)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.go('/student/start-internship'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Internship'),
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                  if (placement.status == PlacementStatus.rejected) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.go('/student/upload-letter'),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload New Letter'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(studentPlacementProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Supervisor feedback card ─────────────────────────────────────────────
  // Prominently shows WHY the letter was rejected so the student
  // knows exactly what to fix before resubmitting.

  Widget _buildFeedbackCard(PlacementModel placement, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.feedback_outlined,
                  color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Supervisor Feedback',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            placement.supervisorFeedback!,
            style: TextStyle(
                fontSize: 14, color: Colors.red.shade800, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Status banner ────────────────────────────────────────────────────────

  Widget _buildStatusBanner(
      BuildContext context, PlacementModel placement) {
    Color color;
    IconData icon;
    String title;
    String subtitle;

    switch (placement.status) {
      // ── Updated: pending → pendingSupervisorReview ─────────────────────
      case PlacementStatus.pendingSupervisorReview:
        color = Colors.orange;
        icon = Icons.hourglass_top_rounded;
        title = 'Awaiting Supervisor Review';
        subtitle =
            'Your acceptance letter has been sent to your university supervisor';
        break;
      case PlacementStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        title = 'Approved!';
        subtitle = 'Your supervisor approved — you can now start your internship';
        break;
      case PlacementStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        title = 'Revision Required';
        // Show feedback summary in subtitle if short enough,
        // otherwise direct them to the feedback card above
        subtitle = (placement.supervisorFeedback != null &&
                placement.supervisorFeedback!.length <= 80)
            ? placement.supervisorFeedback!
            : 'See feedback below and upload a revised letter';
        break;
      case PlacementStatus.active:
        color = Colors.blue;
        icon = Icons.work;
        title = 'Active';
        subtitle =
            'Week ${placement.weeksCompleted} of ${placement.totalWeeks}';
        break;
      case PlacementStatus.completed:
        color = Colors.green;
        icon = Icons.done_all;
        title = 'Completed';
        subtitle = 'Congratulations on completing your internship!';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        title = placement.status.name;
        subtitle = '';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ACCEPTANCE LETTER VIEWER WIDGET
// ============================================================================

class _AcceptanceLetterViewer extends StatelessWidget {
  final String? fileUrl;
  final String fileName;
  final DateTime? uploadedAt;

  const _AcceptanceLetterViewer({
    required this.fileUrl,
    required this.fileName,
    this.uploadedAt,
  });

  Future<void> _openFile() async {
    if (fileUrl == null || fileUrl!.isEmpty) return;
    final uri = Uri.parse(fileUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyUrl(BuildContext context) async {
    if (fileUrl == null || fileUrl!.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: fileUrl!));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ URL copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acceptance Letter',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            if (fileUrl == null || fileUrl!.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text('No acceptance letter uploaded')),
                  ],
                ),
              ),
            ] else ...[
              Builder(
                builder: (context) {
                  final isImage =
                      fileUrl!.toLowerCase().contains('.jpg') ||
                          fileUrl!.toLowerCase().contains('.jpeg') ||
                          fileUrl!.toLowerCase().contains('.png');
                  final isPdf =
                      fileUrl!.toLowerCase().contains('.pdf');

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPdf
                                  ? Colors.red.shade50
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPdf
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              color:
                                  isPdf ? Colors.red : Colors.blue,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPdf
                                      ? 'PDF Document'
                                      : 'Image File',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _openFile,
                              icon: const Icon(Icons.open_in_new,
                                  size: 18),
                              label: Text(
                                  isPdf ? 'Open PDF' : 'View Image'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copyUrl(context),
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copy Link'),
                            ),
                          ),
                        ],
                      ),
                      if (isImage) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text('Preview',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            fileUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 48),
                                    SizedBox(height: 8),
                                    Text('Failed to load image'),
                                  ],
                                ),
                              ),
                            ),
                            loadingBuilder:
                                (_, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.black,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: InteractiveViewer(
                                          child:
                                              Image.network(fileUrl!),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.zoom_in),
                            label: const Text('View Full Size'),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
            if (uploadedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Uploaded: ${DateFormat('MMM dd, yyyy • HH:mm').format(uploadedAt!)}',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// INFO ROW WIDGET
// ============================================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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