// lib/features/student/presentation/pages/start_internship_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../placements/data/models/placement_model.dart';

// ============================================================================
// PROVIDER
// ============================================================================

/// Fetches the student's approved placement.
/// NOTE: Requires a Firestore composite index on (studentId ASC, status ASC).
/// Create it at: Firebase Console → Firestore → Indexes → Add Index
/// Collection: placements | Fields: studentId ASC, status ASC
final approvedPlacementProvider = StreamProvider<PlacementModel?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('placements')
      .where('studentId', isEqualTo: user.uid)
      .where('status', isEqualTo: PlacementStatus.approved.name)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) return null;
        return PlacementModel.fromFirestore(snapshot.docs.first, null);
      });
});

// ============================================================================
// PAGE
// ============================================================================

class StartInternshipPage extends ConsumerStatefulWidget {
  const StartInternshipPage({super.key});

  @override
  ConsumerState<StartInternshipPage> createState() =>
      _StartInternshipPageState();
}

class _StartInternshipPageState extends ConsumerState<StartInternshipPage> {
  bool _isStarting = false;
  bool _agreedToTerms = false;

  Future<void> _startInternship(PlacementModel placement) async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please agree to the terms and conditions'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_circle_outline,
                    color: Colors.green.shade600, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Start Your Internship?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Once started, record daily work and submit a weekly summary for review. Are you ready to begin?',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Start Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isStarting = true);

    try {
      final now = DateTime.now();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Update placement to active
      await FirebaseFirestore.instance
          .collection('placements')
          .doc(placement.id)
          .update({
        'status': PlacementStatus.active.name,
        'actualStartDate': Timestamp.fromDate(now),
        'weeksCompleted': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ BUG 3 FIX: Correct collection is 'students', NOT 'studentProfiles'
      await FirebaseFirestore.instance
          .collection('students') // ← FIXED (was 'studentProfiles')
          .doc(user.uid)
          .update({
        'internshipStatus': 'inProgress',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 12),
                Text('Internship started successfully! 🎉'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.go('/student/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting internship: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placementAsync = ref.watch(approvedPlacementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Internship'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : context.go('/student/dashboard'),
        ),
      ),
      body: placementAsync.when(
        data: (placement) {
          if (placement == null) {
            return _buildNoPlacement(context, theme);
          }
          if (_isStarting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Starting your internship...',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return _buildContent(context, theme, placement);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, ref, error),
      ),
    );
  }

  // ── No approved placement ────────────────────────────────────────────────

  Widget _buildNoPlacement(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.hourglass_empty, size: 56, color: Colors.orange.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'No Approved Placement Found',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your placement must be approved before you can start your internship.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go('/student/placement-status'),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Placement Status'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(approvedPlacementProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main content ─────────────────────────────────────────────────────────

  Widget _buildContent(
      BuildContext context, ThemeData theme, PlacementModel placement) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero welcome card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.celebration,
                    size: 40, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Ready to Begin!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your placement has been approved. You are ready to start your ${placement.totalWeeks}-week internship journey.',
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // What to expect
          const Text(
            'What to Expect',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _ExpectationTile(
            icon: Icons.edit_note_outlined,
            color: Colors.blue,
            title: 'Daily Logbook',
            description: 'Record each workday',
          ),
          _ExpectationTile(
            icon: Icons.summarize_outlined,
            color: Colors.purple,
            title: 'Weekly Logbook',
            description:
                'Generate the weekly summary from your daily logbook',
          ),
          _ExpectationTile(
            icon: Icons.supervisor_account_outlined,
            color: Colors.teal,
            title: 'Supervisor Feedback',
            description:
                'Receive guidance from both company and university supervisors',
          ),
          _ExpectationTile(
            icon: Icons.assessment_outlined,
            color: Colors.orange,
            title: 'Final Evaluation',
            description:
                'Complete your final evaluation at the end of the internship',
          ),

          const SizedBox(height: 28),

          // Terms
          const Text(
            'Terms & Conditions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _TermRow('Keep your daily logbook up to date'),
                _TermRow('Submit the weekly logbook on time'),
                _TermRow('Maintain professional conduct at all times'),
                _TermRow('Adhere to company policies and regulations'),
                _TermRow(
                    'Complete the full ${placement.totalWeeks}-week duration'),
                _TermRow('Participate in all required evaluations'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Agreement
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: CheckboxListTile(
              value: _agreedToTerms,
              onChanged: (value) =>
                  setState(() => _agreedToTerms = value ?? false),
              title: const Text(
                'I agree to all terms and conditions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'By checking this, you accept all responsibilities for the internship period',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 28),

          // Start button
          SizedBox(
            width: double.infinity,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _agreedToTerms ? 1.0 : 0.5,
              child: FilledButton.icon(
                onPressed: _agreedToTerms
                    ? () => _startInternship(placement)
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Start My Internship',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

class _ExpectationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _ExpectationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(description,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  final String text;

  const _TermRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
