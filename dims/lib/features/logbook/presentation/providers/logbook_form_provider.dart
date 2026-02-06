import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/logbook_entry_model.dart';
import '../../../student/controllers/student_controllers.dart';
import '../../../student/data/models/student_profile_model.dart';

// ──────────────────────────────────────────────────────────────────────────────
// FORM PROVIDER (supports both create and edit)
// ──────────────────────────────────────────────────────────────────────────────

final logbookFormProvider = StateNotifierProvider.autoDispose<
    LogbookFormNotifier, LogbookFormState>((ref) {
  final studentProfileAsync = ref.watch(studentProfileProvider);
  final studentProfile = studentProfileAsync.value;

  // Pass ref so we can access controllers inside notifier
  return LogbookFormNotifier(ref, studentProfile);
});

class LogbookFormState {
  final DateTime? selectedDate;
  final String tasksPerformed;
  final String? challenges;
  final String? skillsLearned;
  final double hoursWorked;
  final bool isSubmitting;
  final String? errorMessage;
  final bool formSubmittedSuccessfully;

  const LogbookFormState({
    this.selectedDate,
    this.tasksPerformed = '',
    this.challenges,
    this.skillsLearned,
    this.hoursWorked = 0.0,
    this.isSubmitting = false,
    this.errorMessage,
    this.formSubmittedSuccessfully = false,
  });

  bool get isValid =>
      selectedDate != null &&
      tasksPerformed.trim().isNotEmpty &&
      hoursWorked > 0;

  LogbookFormState copyWith({
    DateTime? selectedDate,
    String? tasksPerformed,
    String? challenges,
    String? skillsLearned,
    double? hoursWorked,
    bool? isSubmitting,
    String? errorMessage,
    bool? formSubmittedSuccessfully,
  }) {
    return LogbookFormState(
      selectedDate: selectedDate ?? this.selectedDate,
      tasksPerformed: tasksPerformed ?? this.tasksPerformed,
      challenges: challenges ?? this.challenges,
      skillsLearned: skillsLearned ?? this.skillsLearned,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      formSubmittedSuccessfully:
          formSubmittedSuccessfully ?? this.formSubmittedSuccessfully,
    );
  }
}

class LogbookFormNotifier extends StateNotifier<LogbookFormState> {
  final Ref _ref;
  final StudentProfileModel? _studentProfile;
  String? _editingEntryId; // Track if we're editing (set when loading entry)

  LogbookFormNotifier(this._ref, this._studentProfile)
      : super(LogbookFormState(selectedDate: DateTime.now()));

  void resetForm() {
    _editingEntryId = null;
    state = LogbookFormState(selectedDate: DateTime.now());
  }

  // ── NEW: Load existing entry for edit mode ────────────────────────────────
  void loadExistingEntry(LogbookEntryModel entry) {
    _editingEntryId = entry.id;
    state = state.copyWith(
      selectedDate: entry.date,
      tasksPerformed: entry.tasksPerformed,
      challenges: entry.challenges,
      skillsLearned: entry.skillsLearned,
      hoursWorked: entry.hoursWorked,
    );
  }

  void updateDate(DateTime? date) {
    state = state.copyWith(selectedDate: date);
  }

  void updateTasks(String value) {
    state = state.copyWith(tasksPerformed: value);
  }

  void updateChallenges(String? value) {
    state = state.copyWith(
      challenges: value?.trim().isEmpty ?? true ? null : value?.trim(),
    );
  }

  void updateSkillsLearned(String? value) {
    state = state.copyWith(
      skillsLearned: value?.trim().isEmpty ?? true ? null : value?.trim(),
    );
  }

  void updateHours(double value) {
    state = state.copyWith(hoursWorked: value.clamp(0.0, 24.0));
  }

  /// ── Submit: Handles BOTH create and update ────────────────────────────────
  Future<bool> submit() async {
    if (_studentProfile == null) {
      state = state.copyWith(errorMessage: 'No student profile found');
      return false;
    }

    // Check if the student actually has a supervisor assigned
    final supervisorId = _studentProfile!.currentSupervisorId; // Ensure this field name matches your StudentProfileModel
    if (supervisorId == null || supervisorId.isEmpty) {
      state = state.copyWith(errorMessage: 'No supervisor assigned. Please contact admin.');
      return false;
    }

    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'Please fill required fields');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final entry = LogbookEntryModel(
        id: _editingEntryId, 
        studentRefPath: 'students/${currentUser.uid}',
        placementRefPath: _studentProfile!.currentPlacementId ?? '',
        supervisorId: supervisorId, // <--- ADD THIS LINE (Fixes the error)
        date: state.selectedDate!,
        dayNumber: 1, // You could calculate this based on existing entries
        tasksPerformed: state.tasksPerformed.trim(),
        challenges: state.challenges,
        skillsLearned: state.skillsLearned,
        hoursWorked: state.hoursWorked,
        status: 'pending', // Usually, students submit straight to 'pending' for review
        createdAt: DateTime.now(),
      );

      if (_editingEntryId != null) {
        // EDIT MODE
        await _ref.read(logbookControllerProvider).updateEntry(_editingEntryId!, entry);
      } else {
        // CREATE MODE
        await _ref.read(logbookControllerProvider).submitEntry(entry);
      }

      state = state.copyWith(
        isSubmitting: false,
        formSubmittedSuccessfully: true,
        errorMessage: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to save: $e',
      );
      return false;
    }
  }}