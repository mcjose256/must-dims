import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../student/controllers/student_controllers.dart';
import '../../data/models/daily_logbook_entry_model.dart';
import '../../controllers/logbook_controller.dart' as logbook_ctrl;

class DailyEntryFormPage extends ConsumerStatefulWidget {
  final DailyLogbookEntryModel? existingEntry;

  const DailyEntryFormPage({
    super.key,
    this.existingEntry,
  });

  @override
  ConsumerState<DailyEntryFormPage> createState() => _DailyEntryFormPageState();
}

class _DailyEntryFormPageState extends ConsumerState<DailyEntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _tasksController = TextEditingController();
  final _hoursController = TextEditingController(text: '8');
  final _challengesController = TextEditingController();
  final _skillsController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _loadExistingEntry();
    }
  }

  void _loadExistingEntry() {
    final entry = widget.existingEntry!;
    _tasksController.text = entry.tasksPerformed;
    _hoursController.text = entry.hoursWorked.toString();
    _challengesController.text = entry.challenges ?? '';
    _skillsController.text = entry.skillsLearned ?? '';
    _notesController.text = entry.notes ?? '';
    _selectedDate = entry.date;
  }

  @override
  void dispose() {
    _tasksController.dispose();
    _hoursController.dispose();
    _challengesController.dispose();
    _skillsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 120)),
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final studentProfile = await ref.read(studentProfileProvider.future);
      if (studentProfile == null) throw Exception('Student profile not found');

      final placementId = studentProfile.currentPlacementId;
      if (placementId == null || placementId.isEmpty) {
        throw Exception('No active placement');
      }

      final existingEntriesSnapshot = await FirebaseFirestore.instance
          .collection('dailyLogbookEntries')
          .where('studentId', isEqualTo: user.uid)
          .get();

      final duplicateForDate = existingEntriesSnapshot.docs.any((doc) {
        if (widget.existingEntry?.id == doc.id) return false;
        final data = doc.data();
        if (data['placementId'] != placementId) return false;

        final date = (data['date'] as Timestamp).toDate();
        return date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
      });

      if (duplicateForDate) {
        throw Exception('A daily log already exists for this date');
      }

      // Get next day number
      int dayNumber;
      if (widget.existingEntry != null) {
        dayNumber = widget.existingEntry!.dayNumber;
      } else {
        dayNumber = await ref.read(logbook_ctrl.logbookControllerProvider).getNextDayNumber(user.uid);
      }

      final entry = DailyLogbookEntryModel(
        id: widget.existingEntry?.id,
        studentId: user.uid,
        placementId: placementId,
        date: _selectedDate,
        dayNumber: dayNumber,
        tasksPerformed: _tasksController.text.trim(),
        hoursWorked: double.parse(_hoursController.text.trim()),
        challenges: _challengesController.text.trim().isEmpty 
            ? null 
            : _challengesController.text.trim(),
        skillsLearned: _skillsController.text.trim().isEmpty 
            ? null 
            : _skillsController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
      );

      if (widget.existingEntry != null) {
        await ref.read(logbook_ctrl.logbookControllerProvider).updateDailyEntry(
          widget.existingEntry!.id!,
          entry,
        );
      } else {
        await ref.read(logbook_ctrl.logbookControllerProvider).submitDailyEntry(entry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingEntry != null 
                  ? 'Daily log updated'
                  : 'Daily log saved',
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry != null
            ? 'Edit Daily Log'
            : 'Daily Logbook'),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving daily log...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Date Selector
                  Text(
                    'Date',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tasks Performed
                  Text(
                    'Work Done',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tasksController,
                    decoration: const InputDecoration(
                      hintText: 'What did you work on today?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe your tasks';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Hours Worked
                  Text(
                    'Hours',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _hoursController,
                    decoration: const InputDecoration(
                      hintText: '8',
                      border: OutlineInputBorder(),
                      suffixText: 'hours',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final hours = double.tryParse(value);
                      if (hours == null || hours <= 0 || hours > 24) {
                        return 'Enter valid hours (0-24)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Challenges (Optional)
                  Text(
                    'Challenges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _challengesController,
                    decoration: const InputDecoration(
                      hintText: 'Any blockers or issues?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Skills Learned (Optional)
                  Text(
                    'Skills',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      hintText: 'Skills gained today',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Notes (Optional)
                  Text(
                    'Notes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Anything else to note',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitEntry,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.existingEntry != null
                            ? 'Update Daily Log'
                            : 'Save Daily Log',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
