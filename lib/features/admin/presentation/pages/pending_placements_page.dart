import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../placements/data/models/placement_model.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final pendingPlacementsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('placements')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final List<Map<String, dynamic>> placementsWithDetails = [];

    for (var placementDoc in snapshot.docs) {
      final placement = PlacementModel.fromFirestore(placementDoc, null);

      // Get student details
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(placement.studentId)
          .get();

      // Get company details
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(placement.companyId)
          .get();

      placementsWithDetails.add({
        'placement': placement,
        'student': studentDoc.data(),
        'company': companyDoc.data(),
      });
    }

    return placementsWithDetails;
  });
});

// ============================================================================
// PENDING PLACEMENTS PAGE
// ============================================================================

class PendingPlacementsPage extends ConsumerWidget {
  const PendingPlacementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementsAsync = ref.watch(pendingPlacementsProvider);

    return Scaffold(
      body: placementsAsync.when(
        data: (placements) {
          if (placements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No pending placements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('All acceptance letters have been reviewed'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: placements.length,
            itemBuilder: (context, index) {
              final data = placements[index];
              final placement = data['placement'] as PlacementModel;
              final student = data['student'] as Map<String, dynamic>?;
              final company = data['company'] as Map<String, dynamic>?;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      student?['fullName']?[0]?.toUpperCase() ?? 'S',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    student?['fullName'] ?? 'Unknown Student',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company?['name'] ?? 'Unknown Company'),
                      Text(
                        'Uploaded: ${placement.createdAt != null ? DateFormat('MMM dd, yyyy').format(placement.createdAt!) : 'N/A'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student Info
                          _InfoRow(
                              'Student', student?['fullName'] ?? 'Unknown'),
                          _InfoRow('Reg Number',
                              student?['registrationNumber'] ?? 'N/A'),
                          _InfoRow('Program', student?['program'] ?? 'N/A'),
                          const Divider(height: 24),

                          // Company Info
                          _InfoRow('Company', company?['name'] ?? 'Unknown'),
                          _InfoRow('Industry', company?['industry'] ?? 'N/A'),
                          _InfoRow('Location', company?['location'] ?? 'N/A'),
                          const Divider(height: 24),

                          // Supervisor Info
                          _InfoRow('Supervisor Name',
                              placement.companySupervisorName ?? 'N/A'),
                          _InfoRow('Supervisor Email',
                              placement.companySupervisorEmail ?? 'N/A'),
                          _InfoRow('Supervisor Phone',
                              placement.companySupervisorPhone ?? 'N/A'),
                          const Divider(height: 24),

                          // Acceptance Letter Viewer
                          AcceptanceLetterViewer(
                            fileUrl: placement.acceptanceLetterUrl,
                            fileName: placement.acceptanceLetterFileName ??
                                'acceptance_letter',
                          ),
                          const SizedBox(height: 16),

                          // Student Notes
                          if (placement.studentNotes != null &&
                              placement.studentNotes!.isNotEmpty) ...[
                            const Text(
                              'Student Notes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(placement.studentNotes!),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _rejectPlacement(context, ref, placement),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: () =>
                                    _approvePlacement(context, ref, placement),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(pendingPlacementsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approvePlacement(
    BuildContext context,
    WidgetRef ref,
    PlacementModel placement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Placement?'),
        content: const Text(
          'This will approve the acceptance letter and allow the student to start their internship.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get current admin UID
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

      await FirebaseFirestore.instance
          .collection('placements')
          .doc(placement.id)
          .update({
        'status': PlacementStatus.approved.name,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedByAdminId': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update student profile status
      await FirebaseFirestore.instance
          .collection('students')
          .doc(placement.studentId)
          .update({
        'internshipStatus': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Placement approved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectPlacement(
    BuildContext context,
    WidgetRef ref,
    PlacementModel placement,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reject Placement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text('Please provide a reason for rejection.'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection Reason',
                    border: OutlineInputBorder(),
                    hintText:
                        'e.g., Invalid acceptance letter, missing information...',
                  ),
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: () {
                              if (reasonController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please provide a reason'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(context, true);
                            },
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            if (reasonController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please provide a reason'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Reject'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

      await FirebaseFirestore.instance
          .collection('placements')
          .doc(placement.id)
          .update({
        'status': PlacementStatus.rejected.name,
        'adminNotes': reasonController.text.trim(),
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedByAdminId': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Placement rejected'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ============================================================================
// ACCEPTANCE LETTER VIEWER WIDGET
// ============================================================================

class AcceptanceLetterViewer extends StatelessWidget {
  final String? fileUrl;
  final String fileName;

  const AcceptanceLetterViewer({
    super.key,
    required this.fileUrl,
    this.fileName = 'acceptance_letter',
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
    if (fileUrl == null || fileUrl!.isEmpty) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No acceptance letter uploaded',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isImage = fileUrl!.toLowerCase().contains('.jpg') ||
        fileUrl!.toLowerCase().contains('.jpeg') ||
        fileUrl!.toLowerCase().contains('.png') ||
        fileUrl!.toLowerCase().contains('.webp');
    final isPdf = fileUrl!.toLowerCase().contains('.pdf');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf : Icons.image,
                    color: isPdf ? Colors.red : Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acceptance Letter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPdf ? 'PDF Document' : 'Image File',
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

            // Action Buttons
            Row(
              children: [
                // View/Download Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openFile,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(isPdf ? 'Open PDF' : 'View Image'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Copy URL Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyUrl(context),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Link'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Preview for images
            if (isImage) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fileUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Failed to load image'),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
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
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: Image.network(fileUrl!),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
