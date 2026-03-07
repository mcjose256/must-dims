// lib/features/supervisor/presentation/screens/placement_letter_review_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/placements/data/models/placement_model.dart';
import '../../../../features/supervisor/controllers/supervisor_controller.dart';
import '../../../../features/auth/controllers/auth_controller.dart';

// ============================================================================
// PROVIDER — student snapshot for display info
// ============================================================================

final _studentInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, studentId) async {
  final doc = await FirebaseFirestore.instance
      .collection('students')
      .doc(studentId)
      .get();
  return doc.data();
});

final _companyInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, companyId) async {
  if (companyId.isEmpty) return null;
  final doc = await FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .get();
  return doc.data();
});

// ============================================================================
// PAGE
// ============================================================================

class PlacementLetterReviewPage extends ConsumerStatefulWidget {
  final PlacementModel placement;

  const PlacementLetterReviewPage({
    super.key,
    required this.placement,
  });

  @override
  ConsumerState<PlacementLetterReviewPage> createState() =>
      _PlacementLetterReviewPageState();
}

class _PlacementLetterReviewPageState
    extends ConsumerState<PlacementLetterReviewPage> {
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // ── Open letter in browser / PDF viewer ─────────────────────────────────

  Future<void> _openLetter() async {
    final url = widget.placement.acceptanceLetterUrl;
    if (url == null || url.isEmpty) {
      _showSnack('No letter URL available.', isError: true);
      return;
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack('Could not open the letter. Try again.', isError: true);
    }
  }

  // ── Approve ──────────────────────────────────────────────────────────────

  Future<void> _approve() async {
    final confirmed = await _showConfirmDialog(
      title: 'Approve Placement',
      message:
          'Are you sure you want to approve this placement letter? '
          'The student will be able to begin their internship.',
      confirmLabel: 'Approve',
      confirmColor: Colors.green,
    );
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      final supervisorId =
          ref.read(authStateProvider).value?.uid ?? '';

      await ref.read(supervisorControllerProvider).approvePlacement(
            placementId: widget.placement.id,
            studentId: widget.placement.studentId,
            supervisorId: supervisorId,
          );

      if (mounted) {
        _showSnack('Placement approved successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to approve: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Reject ───────────────────────────────────────────────────────────────

  Future<void> _reject() async {
    // Show the rejection bottom sheet — feedback is required before
    // the reject button becomes active
    final feedback = await _showRejectionSheet();
    if (feedback == null || feedback.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final supervisorId =
          ref.read(authStateProvider).value?.uid ?? '';

      await ref.read(supervisorControllerProvider).rejectPlacement(
            placementId: widget.placement.id,
            studentId: widget.placement.studentId,
            supervisorId: supervisorId,
            feedback: feedback,
          );

      if (mounted) {
        _showSnack('Feedback sent to student.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to reject: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Rejection bottom sheet ───────────────────────────────────────────────
  // Returns the feedback string, or null if supervisor cancelled.

  Future<String?> _showRejectionSheet() async {
    final controller = TextEditingController();
    String? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.feedback_outlined,
                            color: Colors.red.shade600, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Provide Feedback',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'The student will see this and must fix it before resubmitting',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Feedback field
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    autofocus: true,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. The letter must be on official company letterhead and signed by the HR manager...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Character count hint
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${controller.text.trim().length} chars',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          // Disabled until there's actual feedback text
                          onPressed: controller.text.trim().isEmpty
                              ? null
                              : () {
                                  result = controller.text.trim();
                                  Navigator.pop(ctx);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Send Feedback & Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  }

  // ── Confirm dialog ───────────────────────────────────────────────────────

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title),
            content: Text(message, style: const TextStyle(height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: confirmColor),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placement = widget.placement;
    final studentAsync =
        ref.watch(_studentInfoProvider(placement.studentId));
    final companyAsync =
        ref.watch(_companyInfoProvider(placement.companyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Acceptance Letter'),
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Student info card ──────────────────────────────────
                _buildStudentCard(studentAsync, theme),
                const SizedBox(height: 12),

                // ── Company info card ──────────────────────────────────
                _buildCompanyCard(companyAsync, placement, theme),
                const SizedBox(height: 12),

                // ── Company supervisor card ────────────────────────────
                _buildCompanySupervisorCard(placement, theme),
                const SizedBox(height: 12),

                // ── Timeline card ──────────────────────────────────────
                _buildTimelineCard(placement, theme),
                const SizedBox(height: 12),

                // ── Student notes (if any) ─────────────────────────────
                if (placement.studentNotes != null &&
                    placement.studentNotes!.isNotEmpty)
                  _buildStudentNotesCard(placement, theme),

                if (placement.studentNotes != null &&
                    placement.studentNotes!.isNotEmpty)
                  const SizedBox(height: 12),

                // ── Acceptance letter ──────────────────────────────────
                _buildLetterCard(placement, theme),
                const SizedBox(height: 32),

                // ── Action buttons ─────────────────────────────────────
                _buildActionButtons(theme),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ── Student card ─────────────────────────────────────────────────────────

  Widget _buildStudentCard(
      AsyncValue<Map<String, dynamic>?> studentAsync, ThemeData theme) {
    return _InfoCard(
      title: 'Student',
      icon: Icons.person_outline,
      color: Colors.blue,
      child: studentAsync.when(
        data: (data) => data == null
            ? const Text('Student info not found')
            : _InfoGrid(items: {
                'Name': data['fullName'] ?? 'N/A',
                'Reg. No.': data['registrationNumber'] ?? 'N/A',
                'Program': data['program'] ?? 'N/A',
                'Academic Year': data['academicYear']?.toString() ?? 'N/A',
              }),
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }

  // ── Company card ─────────────────────────────────────────────────────────

  Widget _buildCompanyCard(
    AsyncValue<Map<String, dynamic>?> companyAsync,
    PlacementModel placement,
    ThemeData theme,
  ) {
    return _InfoCard(
      title: 'Company',
      icon: Icons.business_outlined,
      color: Colors.indigo,
      child: companyAsync.when(
        data: (data) => data == null
            ? const Text('Company info not found')
            : _InfoGrid(items: {
                'Name': data['name'] ?? 'N/A',
                'Industry': data['industry'] ?? 'N/A',
                'Location': data['location'] ?? 'N/A',
              }),
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }

  // ── Company supervisor card ───────────────────────────────────────────────

  Widget _buildCompanySupervisorCard(
      PlacementModel placement, ThemeData theme) {
    return _InfoCard(
      title: 'Company Supervisor',
      icon: Icons.badge_outlined,
      color: Colors.purple,
      child: _InfoGrid(items: {
        'Name': placement.companySupervisorName ?? 'N/A',
        'Email': placement.companySupervisorEmail ?? 'N/A',
        if (placement.companySupervisorPhone != null)
          'Phone': placement.companySupervisorPhone!,
      }),
    );
  }

  // ── Timeline card ─────────────────────────────────────────────────────────

  Widget _buildTimelineCard(PlacementModel placement, ThemeData theme) {
    String _fmt(DateTime? dt) {
      if (dt == null) return 'Not specified';
      return '${dt.day}/${dt.month}/${dt.year}';
    }

    return _InfoCard(
      title: 'Internship Timeline',
      icon: Icons.schedule_outlined,
      color: Colors.orange,
      child: _InfoGrid(items: {
        'Start Date': _fmt(placement.startDate),
        'End Date': _fmt(placement.endDate),
        'Duration': '${placement.totalWeeks} weeks',
        'Submitted': _fmt(placement.letterUploadedAt),
      }),
    );
  }

  // ── Student notes card ────────────────────────────────────────────────────

  Widget _buildStudentNotesCard(PlacementModel placement, ThemeData theme) {
    return _InfoCard(
      title: 'Student\'s Notes',
      icon: Icons.notes_outlined,
      color: Colors.teal,
      child: Text(
        placement.studentNotes!,
        style: const TextStyle(fontSize: 14, height: 1.6),
      ),
    );
  }

  // ── Letter card ───────────────────────────────────────────────────────────

  Widget _buildLetterCard(PlacementModel placement, ThemeData theme) {
    final hasLetter = placement.acceptanceLetterUrl != null &&
        placement.acceptanceLetterUrl!.isNotEmpty;

    return _InfoCard(
      title: 'Acceptance Letter',
      icon: Icons.description_outlined,
      color: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (placement.acceptanceLetterFileName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.attach_file,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      placement.acceptanceLetterFileName!,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasLetter ? _openLetter : null,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open Acceptance Letter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade400),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (!hasLetter)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No letter file available.',
                style:
                    TextStyle(fontSize: 12, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        // Approve
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _approve,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'Approve Placement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Reject
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _reject,
            icon: Icon(Icons.cancel_outlined, color: Colors.red.shade600),
            label: Text(
              'Request Revision',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade400, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Guidance text — helps supervisor understand the weight of each action
        Text(
          'Approving allows the student to begin their internship immediately. '
          'Requesting a revision will notify the student with your feedback.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final Map<String, String> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  '${e.key}:',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}