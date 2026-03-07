// lib/features/logbook/presentation/pages/weekly_summary_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../student/controllers/student_controllers.dart';
import '../../data/models/weekly_logbook_summary_model.dart';
import '../../controllers/logbook_controller.dart' as logbook_ctrl;

class WeeklySummaryFormPage extends ConsumerStatefulWidget {
  final int weekNumber;
  final WeeklyLogbookSummaryModel? existingSummary;

  const WeeklySummaryFormPage({
    super.key,
    required this.weekNumber,
    this.existingSummary,
  });

  @override
  ConsumerState<WeeklySummaryFormPage> createState() =>
      _WeeklySummaryFormPageState();
}

class _WeeklySummaryFormPageState
    extends ConsumerState<WeeklySummaryFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _overviewController = TextEditingController();
  final _accomplishmentsController = TextEditingController();
  final _challengesController = TextEditingController();
  final _skillsController = TextEditingController();
  final _lessonsController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  double _totalHours = 0.0;
  List<String> _dailyEntryIds = [];
  DateTime? _weekStartDate;
  DateTime? _weekEndDate;

  // ── Ensure weekNumber is never 0 ──────────────────────────────────────────
  // Guard here so even if the caller passes 0, we treat it as 1.
  int get _safeWeekNumber => widget.weekNumber < 1 ? 1 : widget.weekNumber;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.existingSummary != null) {
        _loadExistingSummary();
      } else {
        await _compileFromDailyEntries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not auto-load daily entries: $e'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        // Don't block the form — let them fill manually
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadExistingSummary() {
    final s = widget.existingSummary!;
    _overviewController.text = s.weeklyOverview;
    _accomplishmentsController.text = s.keyAccomplishments ?? '';
    _challengesController.text = s.challengesSummary ?? '';
    _skillsController.text = s.skillsAcquired ?? '';
    _lessonsController.text = s.lessonsLearned ?? '';
    _totalHours = s.totalHoursWorked;
    _dailyEntryIds = s.dailyEntryIds;
    _weekStartDate = s.weekStartDate;
    _weekEndDate = s.weekEndDate;
  }

  Future<void> _compileFromDailyEntries() async {
    final controller =
        ref.read(logbook_ctrl.logbookControllerProvider);
    final compiled =
        await controller.compileDailyEntriesForWeek(_safeWeekNumber);

    if (mounted) {
      setState(() {
        _dailyEntryIds = List<String>.from(compiled['dailyEntryIds']);
        _totalHours = compiled['totalHours'] as double;
        _weekStartDate = compiled['weekStartDate'] as DateTime;
        _weekEndDate = compiled['weekEndDate'] as DateTime;
        _overviewController.text = compiled['compiledTasks'] as String;
        if (compiled['compiledChallenges'] != null) {
          _challengesController.text =
              compiled['compiledChallenges'] as String;
        }
        if (compiled['compiledSkills'] != null) {
          _skillsController.text = compiled['compiledSkills'] as String;
        }
      });
    }
  }

  @override
  void dispose() {
    _overviewController.dispose();
    _accomplishmentsController.dispose();
    _challengesController.dispose();
    _skillsController.dispose();
    _lessonsController.dispose();
    super.dispose();
  }

  Future<void> _submitSummary() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekStartDate == null || _weekEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Week date range could not be determined. Please ensure you have daily entries for this week.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final studentProfile =
          await ref.read(studentProfileProvider.future);
      if (studentProfile == null) {
        throw Exception('Student profile not found');
      }

      final placementId = studentProfile.currentPlacementId;
      if (placementId == null || placementId.isEmpty) {
        throw Exception('No active placement found');
      }

      final summary = WeeklyLogbookSummaryModel(
        id: widget.existingSummary?.id,
        studentId: user.uid,
        placementId: placementId,
        weekNumber: _safeWeekNumber,
        weekStartDate: _weekStartDate!,
        weekEndDate: _weekEndDate!,
        weeklyOverview: _overviewController.text.trim(),
        totalHoursWorked: _totalHours,
        keyAccomplishments:
            _accomplishmentsController.text.trim().isEmpty
                ? null
                : _accomplishmentsController.text.trim(),
        challengesSummary: _challengesController.text.trim().isEmpty
            ? null
            : _challengesController.text.trim(),
        skillsAcquired: _skillsController.text.trim().isEmpty
            ? null
            : _skillsController.text.trim(),
        lessonsLearned: _lessonsController.text.trim().isEmpty
            ? null
            : _lessonsController.text.trim(),
        dailyEntryIds: _dailyEntryIds,
        status: 'submitted',
        submittedAt: DateTime.now(),
        createdAt: widget.existingSummary?.createdAt ?? DateTime.now(),
      );

      if (widget.existingSummary != null) {
        await ref
            .read(logbook_ctrl.logbookControllerProvider)
            .updateWeeklySummary(widget.existingSummary!.id!, summary);
      } else {
        await ref
            .read(logbook_ctrl.logbookControllerProvider)
            .submitWeeklySummary(summary);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingSummary != null
                  ? 'Week $_safeWeekNumber summary updated!'
                  : 'Week $_safeWeekNumber summary submitted for review!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Week $_safeWeekNumber Summary')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Compiling your weekly data...'),
            ],
          ),
        ),
      );
    }

    if (_isSubmitting) {
      return Scaffold(
        appBar: AppBar(title: Text('Week $_safeWeekNumber Summary')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Submitting summary...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingSummary != null
              ? 'Edit Week $_safeWeekNumber Summary'
              : 'Submit Weekly Logbook',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Week info banner ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Week\n$_safeWeekNumber',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _weekStartDate != null && _weekEndDate != null
                              ? '${DateFormat('MMM d').format(_weekStartDate!)} – '
                                  '${DateFormat('MMM d, yyyy').format(_weekEndDate!)}'
                              : 'Date range not available',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_totalHours.toStringAsFixed(1)} hours • '
                          '${_dailyEntryIds.length} daily entries',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Activities Performed (required) ──────────────────────
            _FieldLabel(
                label: 'Activities Performed', isRequired: true),
            const SizedBox(height: 4),
            Text(
              'Summarize the main work you accomplished this week',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _overviewController,
              decoration: const InputDecoration(
                hintText:
                    'Describe what you worked on this week...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Activities performed is required';
                }
                if (value.trim().length < 30) {
                  return 'Please provide more detail (at least 30 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Skills Learned ───────────────────────────────────────
            _FieldLabel(label: 'Skills Learned'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _skillsController,
              decoration: const InputDecoration(
                hintText: 'What new skills or knowledge did you gain?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // ── Challenges Faced ─────────────────────────────────────
            _FieldLabel(label: 'Challenges Faced'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _challengesController,
              decoration: const InputDecoration(
                hintText:
                    'Any difficulties or obstacles you encountered?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // ── Key Accomplishments ──────────────────────────────────
            _FieldLabel(label: 'Key Accomplishments'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accomplishmentsController,
              decoration: const InputDecoration(
                hintText: 'What were your major achievements this week?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // ── Lessons Learned ──────────────────────────────────────
            _FieldLabel(label: 'Lessons Learned'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lessonsController,
              decoration: const InputDecoration(
                hintText:
                    'What insights or lessons did you take away?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 36),

            // ── Submit button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitSummary,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.existingSummary != null
                      ? 'Update Summary'
                      : 'Submit for Review',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Field label widget ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _FieldLabel({required this.label, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
      ],
    );
  }
}