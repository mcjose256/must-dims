import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../logbook/data/models/daily_logbook_entry_model.dart';

final studentActivePlacementProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final studentDoc = await FirebaseFirestore.instance
      .collection('students')
      .doc(user.uid)
      .get();

  final placementId = studentDoc.data()?['currentPlacementId'] as String?;
  if (placementId == null) return null;

  final placementDoc = await FirebaseFirestore.instance
      .collection('placements')
      .doc(placementId)
      .get();

  if (!placementDoc.exists) return null;

  final placementData = placementDoc.data()!;
  final startDate = (placementData['startDate'] as Timestamp?)?.toDate();
  if (startDate == null) return null;

  final now = DateTime.now();
  final daysSinceStart = now.difference(startDate).inDays;
  final currentWeek = daysSinceStart < 0 ? 1 : (daysSinceStart ~/ 7) + 1;

  return {
    'placementId': placementId,
    'placement': placementData,
    'currentWeek': currentWeek,
    'startDate': startDate,
  };
});

class EnhancedLogbookFormPage extends ConsumerStatefulWidget {
  const EnhancedLogbookFormPage({super.key});

  @override
  ConsumerState<EnhancedLogbookFormPage> createState() =>
      _EnhancedLogbookFormPageState();
}

class _EnhancedLogbookFormPageState
    extends ConsumerState<EnhancedLogbookFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _activitiesController = TextEditingController();
  final _skillsController = TextEditingController();
  final _challengesController = TextEditingController();
  final _hoursWorkedController = TextEditingController();

  final List<File> _selectedFiles = [];
  bool _isSubmitting = false;
  int? _prefilledWeekNumber;
  int? _selectedWeekNumber;

  @override
  void dispose() {
    _activitiesController.dispose();
    _skillsController.dispose();
    _challengesController.dispose();
    _hoursWorkedController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
      allowMultiple: true,
    );

    if (result == null) return;

    setState(() {
      final existingPaths = _selectedFiles.map((file) => file.path).toSet();
      for (final path in result.paths.whereType<String>()) {
        if (existingPaths.contains(path)) continue;
        _selectedFiles.add(File(path));
      }
    });
  }

  Future<_WeekSelectionData> _loadWeekSelection(
    Map<String, dynamic> placementData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final placementId = placementData['placementId'] as String;
    final placement = placementData['placement'] as Map<String, dynamic>;
    final currentWeek = placementData['currentWeek'] as int;
    final startDate = placementData['startDate'] as DateTime;
    final totalWeeks = _readTotalWeeks(placement);

    final dailySnapshot = await FirebaseFirestore.instance
        .collection('dailyLogbookEntries')
        .where('studentId', isEqualTo: user.uid)
        .get();
    final weeklySnapshot = await FirebaseFirestore.instance
        .collection('logbookEntries')
        .where('studentId', isEqualTo: user.uid)
        .where('placementId', isEqualTo: placementId)
        .get();

    final submittedWeeks = weeklySnapshot.docs
        .map((doc) => (doc.data()['weekNumber'] as num?)?.toInt())
        .whereType<int>()
        .toSet();

    final allDailyEntries = dailySnapshot.docs
        .map((doc) => DailyLogbookEntryModel.fromFirestore(doc, null))
        .toList();

    final placementEntries = allDailyEntries
        .where((entry) => entry.placementId == placementId)
        .toList();

    var sources = _buildWeekSources(
      entries: placementEntries,
      submittedWeeks: submittedWeeks,
      fallbackStartDate: startDate,
      totalWeeks: totalWeeks,
    );

    // Fallback for testing/data mismatch cases where entries exist
    // but are not lining up with the current placement record yet.
    if (sources.isEmpty && placementEntries.isEmpty && allDailyEntries.isNotEmpty) {
      sources = _buildWeekSources(
        entries: allDailyEntries,
        submittedWeeks: submittedWeeks,
        fallbackStartDate: startDate,
        totalWeeks: totalWeeks,
      );
    }

    return _WeekSelectionData(
      sources: sources,
      selectedWeekNumber: _pickSelectedWeekNumber(
        sources,
        currentWeek: currentWeek,
      ),
    );
  }

  int _readTotalWeeks(Map<String, dynamic> placement) {
    final totalWeeks = placement['totalWeeks'];
    if (totalWeeks is int) return totalWeeks;
    if (totalWeeks is num) return totalWeeks.toInt();
    return 12;
  }

  int _weekNumberForDate(DateTime date, DateTime startDate) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    return (normalizedDate.difference(normalizedStart).inDays ~/ 7) + 1;
  }

  List<_WeekSource> _buildWeekSources({
    required List<DailyLogbookEntryModel> entries,
    required Set<int> submittedWeeks,
    required DateTime fallbackStartDate,
    required int totalWeeks,
  }) {
    if (entries.isEmpty) return const <_WeekSource>[];

    final sortedEntries = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final earliestDate = sortedEntries.first.date;
    final referenceStartDate = _normalizedDate(
      earliestDate.isBefore(fallbackStartDate) ? earliestDate : fallbackStartDate,
    );

    var effectiveTotalWeeks = totalWeeks;
    for (final entry in sortedEntries) {
      final weekNumber = _weekNumberForDate(entry.date, referenceStartDate);
      if (weekNumber > effectiveTotalWeeks) {
        effectiveTotalWeeks = weekNumber;
      }
    }

    final weeks = <int, List<DailyLogbookEntryModel>>{};
    for (final entry in sortedEntries) {
      final weekNumber = _weekNumberForDate(entry.date, referenceStartDate);
      if (weekNumber < 1 || weekNumber > effectiveTotalWeeks) continue;
      weeks.putIfAbsent(weekNumber, () => []).add(entry);
    }

    return weeks.entries
        .where((entry) => entry.value.isNotEmpty)
        .where((entry) => !submittedWeeks.contains(entry.key))
        .map((entry) {
          final weekEntries = [...entry.value]
            ..sort((a, b) => a.date.compareTo(b.date));
          final totalHoursForWeek = weekEntries.fold<double>(
            0,
            (sum, item) => sum + item.hoursWorked,
          );
          final weekStartDate = referenceStartDate.add(
            Duration(days: (entry.key - 1) * 7),
          );
          final weekEndDate = weekStartDate.add(const Duration(days: 6));

          return _WeekSource(
            weekNumber: entry.key,
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            entries: weekEntries,
            totalHours: totalHoursForWeek,
            activitiesSummary: _combineActivities(weekEntries),
            skillsSummary: _combineOptional(
              weekEntries.map((item) => item.skillsLearned),
            ),
            challengesSummary: _combineOptional(
              weekEntries.map((item) => item.challenges),
            ),
          );
        })
        .toList()
      ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
  }

  DateTime _normalizedDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int? _pickSelectedWeekNumber(
    List<_WeekSource> sources, {
    required int currentWeek,
  }) {
    if (sources.isEmpty) return null;

    final selectedWeekNumber = _selectedWeekNumber;
    if (selectedWeekNumber != null &&
        sources.any((source) => source.weekNumber == selectedWeekNumber)) {
      return selectedWeekNumber;
    }

    if (sources.any((source) => source.weekNumber == currentWeek)) {
      return currentWeek;
    }

    return sources.last.weekNumber;
  }

  String _combineActivities(List<DailyLogbookEntryModel> entries) {
    if (entries.isEmpty) return '';
    return entries
        .map((entry) =>
            '${_weekday(entry.date)} ${entry.date.day}/${entry.date.month}: ${entry.tasksPerformed.trim()}')
        .join('\n\n');
  }

  String _combineOptional(Iterable<String?> values) {
    final items = <String>[];
    for (final value in values) {
      final text = value?.trim();
      if (text == null || text.isEmpty || items.contains(text)) continue;
      items.add(text);
    }
    return items.join('\n');
  }

  String _weekday(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  void _prefillControllers(_WeekSource source) {
    if (_prefilledWeekNumber == source.weekNumber) return;

    _activitiesController.text = source.activitiesSummary;
    _skillsController.text = source.skillsSummary;
    _challengesController.text = source.challengesSummary;
    _hoursWorkedController.text = source.totalHours
        .toStringAsFixed(source.totalHours.truncateToDouble() == source.totalHours
            ? 0
            : 1);
    _prefilledWeekNumber = source.weekNumber;
  }

  Future<void> _submitLogbook(
    Map<String, dynamic> placementData,
    _WeekSource source,
  ) async {
    if (source.entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add daily entries for this week first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final placementId = placementData['placementId'] as String;
      final existingWeekSnapshot = await FirebaseFirestore.instance
          .collection('logbookEntries')
          .where('studentId', isEqualTo: user.uid)
          .where('placementId', isEqualTo: placementId)
          .get();

      final existingWeeks = existingWeekSnapshot.docs
          .map((doc) => (doc.data()['weekNumber'] as num?)?.toInt())
          .whereType<int>()
          .toSet();

      if (existingWeeks.contains(source.weekNumber)) {
        throw Exception(
          'Week ${source.weekNumber} already has a weekly logbook.',
        );
      }

      final attachmentUrls = <String>[];
      for (final file in _selectedFiles) {
        final fileName =
            'logbook_attachments/${user.uid}_week${source.weekNumber}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        await storageRef.putFile(file);
        
        attachmentUrls.add(await storageRef.getDownloadURL());
      }

      await FirebaseFirestore.instance.collection('logbookEntries').add({
        'studentId': user.uid,
        'placementId': placementId,
        'weekNumber': source.weekNumber,
        'weekStartDate': Timestamp.fromDate(source.weekStartDate),
        'weekEndDate': Timestamp.fromDate(source.weekEndDate),
        'activitiesPerformed': _activitiesController.text.trim(),
        'skillsLearned': _skillsController.text.trim(),
        'challengesFaced': _challengesController.text.trim(),
        'hoursWorked': source.totalHours,
        'attachmentUrls': attachmentUrls,
        'submittedAt': FieldValue.serverTimestamp(),
        'isReviewedByUniversitySupervisor': false,
        'isReviewedByCompanySupervisor': false,
        'status': 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final placement = placementData['placement'] as Map<String, dynamic>;
      final totalWeeks = _readTotalWeeks(placement);
      final weeksCompleted = <int>{...existingWeeks, source.weekNumber}.fold<int>(
        0,
        (maxWeek, week) => week > maxWeek ? week : maxWeek,
      );
      final recordedWeeksCompleted =
          weeksCompleted > totalWeeks ? totalWeeks : weeksCompleted;
      final progressRatio = (weeksCompleted / totalWeeks).clamp(0.0, 1.0);

      await FirebaseFirestore.instance
          .collection('placements')
          .doc(placementId)
          .update({
        'weeksCompleted': recordedWeeksCompleted,
        'progressPercentage': progressRatio,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('students').doc(user.uid).update({
        'progressPercentage': progressRatio * 100,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        final pageContext = context;
        showDialog(
          context: pageContext,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Weekly logbook submitted'),
            content: Text('Week ${source.weekNumber} is ready for review.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  if (Navigator.canPop(pageContext)) {
                    Navigator.pop(pageContext);
                  } else {
                    pageContext.go('/student/dashboard');
                  }
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
    final placementAsync = ref.watch(studentActivePlacementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Logbook'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : context.go('/student/dashboard'),
        ),
      ),
      body: placementAsync.when(
        data: (placementData) {
          if (placementData == null) {
            return _MissingPlacementState(
              onTap: () => context.go('/student/dashboard'),
            );
          }

          final placement = placementData['placement'] as Map<String, dynamic>;
          final totalWeeks = _readTotalWeeks(placement);

          return FutureBuilder<_WeekSelectionData>(
            future: _loadWeekSelection(placementData),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load daily entries for this week.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                );
              }

              final selection = snapshot.data!;
              final source = selection.selectedSource;

              if (source == null) {
                return _NoWeekReadyState(
                  onTap: () => context.push('/student/submit-daily-logbook'),
                );
              }

              _prefillControllers(source);

              return _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (selection.sources.length > 1) ...[
                            DropdownButtonFormField<int>(
                              value: source.weekNumber,
                              decoration: const InputDecoration(
                                labelText: 'Week',
                                border: OutlineInputBorder(),
                              ),
                              items: selection.sources
                                  .map(
                                    (item) => DropdownMenuItem<int>(
                                      value: item.weekNumber,
                                      child: Text(
                                        'Week ${item.weekNumber} (${item.entries.length} daily entries)',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedWeekNumber = value;
                                  _prefilledWeekNumber = null;
                                  _selectedFiles.clear();
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          _WeekHeaderCard(
                            weekNumber: source.weekNumber,
                            totalWeeks: totalWeeks,
                            entryCount: source.entries.length,
                            totalHours: source.totalHours,
                            weekStartDate: source.weekStartDate,
                            weekEndDate: source.weekEndDate,
                          ),
                          const SizedBox(height: 16),
                          if (source.entries.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No daily entries for this week.',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add daily logbook entries first, then return here.',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.push('/student/submit-daily-logbook'),
                                      icon: const Icon(Icons.edit_note),
                                      label: const Text('Add Daily Log'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            _DailySourceCard(entries: source.entries),
                            const SizedBox(height: 16),
                            Text(
                              'Weekly Summary',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Generated from this week\'s daily logs. Edit before submitting.',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _activitiesController,
                              decoration: const InputDecoration(
                                hintText: 'Summary of the week',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 8,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Add the weekly summary';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Skills',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _skillsController,
                              decoration: const InputDecoration(
                                hintText: 'Skills gained this week',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Challenges',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _challengesController,
                              decoration: const InputDecoration(
                                hintText: 'Challenges faced this week',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Total Hours',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _hoursWorkedController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                suffixText: 'hours',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Pictures or Files',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add pictures from the week or any supporting file.',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(Icons.attach_file),
                              label: Text(_selectedFiles.isEmpty
                                  ? 'Add pictures or files'
                                  : '${_selectedFiles.length} selected'),
                            ),
                            if (_selectedFiles.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedFiles
                                    .map(
                                      (file) => Chip(
                                        label: Text(file.path.split('/').last),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedFiles.remove(file);
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () =>
                                    _submitLogbook(placementData, source),
                                child: const Text('Submit Weekly Logbook'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _WeekSource {
  final int weekNumber;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final List<DailyLogbookEntryModel> entries;
  final double totalHours;
  final String activitiesSummary;
  final String skillsSummary;
  final String challengesSummary;

  const _WeekSource({
    required this.weekNumber,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.entries,
    required this.totalHours,
    required this.activitiesSummary,
    required this.skillsSummary,
    required this.challengesSummary,
  });
}

class _WeekSelectionData {
  final List<_WeekSource> sources;
  final int? selectedWeekNumber;

  const _WeekSelectionData({
    required this.sources,
    required this.selectedWeekNumber,
  });

  _WeekSource? get selectedSource {
    final weekNumber = selectedWeekNumber;
    if (weekNumber == null) return null;

    for (final source in sources) {
      if (source.weekNumber == weekNumber) return source;
    }
    return null;
  }
}

class _WeekHeaderCard extends StatelessWidget {
  final int weekNumber;
  final int totalWeeks;
  final int entryCount;
  final double totalHours;
  final DateTime weekStartDate;
  final DateTime weekEndDate;

  const _WeekHeaderCard({
    required this.weekNumber,
    required this.totalWeeks,
    required this.entryCount,
    required this.totalHours,
    required this.weekStartDate,
    required this.weekEndDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week $weekNumber of $totalWeeks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${weekStartDate.day}/${weekStartDate.month} - ${weekEndDate.day}/${weekEndDate.month}/${weekEndDate.year}',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HeaderMetric(
                    label: 'Daily Entries',
                    value: '$entryCount',
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderMetric(
                    label: 'Hours',
                    value: totalHours.toStringAsFixed(
                        totalHours.truncateToDouble() == totalHours ? 0 : 1),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

class _DailySourceCard extends StatelessWidget {
  final List<DailyLogbookEntryModel> entries;

  const _DailySourceCard({required this.entries});

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
              'Daily entries used',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        '${entry.date.day}/${entry.date.month}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.tasksPerformed,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingPlacementState extends StatelessWidget {
  final VoidCallback onTap;

  const _MissingPlacementState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('No active placement found'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTap,
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoWeekReadyState extends StatelessWidget {
  final VoidCallback onTap;

  const _NoWeekReadyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No week ready for summary.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'There are no unsummarized daily entries available yet. Add daily logs or check that the saved dates belong to the week you want to submit.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Add Daily Log'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
