import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _defaultSupervisorCapacity = 15;

final allocationStudentsProvider =
    StreamProvider<List<_AllocationStudentRecord>>((ref) {
  return FirebaseFirestore.instance.collection('students').snapshots().map((
    snapshot,
  ) {
    final students = <_AllocationStudentRecord>[];

    for (final doc in snapshot.docs) {
      try {
        students.add(_AllocationStudentRecord.fromSnapshot(doc));
      } catch (error) {
        debugPrint('Failed to parse student ${doc.id}: $error');
      }
    }

    students.sort(
      (left, right) =>
          left.fullName.toLowerCase().compareTo(right.fullName.toLowerCase()),
    );
    return students;
  });
});

final allocationSupervisorsProvider =
    StreamProvider<List<_AllocationSupervisorRecord>>((ref) {
  return FirebaseFirestore.instance
      .collection('supervisorProfiles')
      .snapshots()
      .map((snapshot) {
        final supervisors = <_AllocationSupervisorRecord>[];

        for (final doc in snapshot.docs) {
          try {
            supervisors.add(_AllocationSupervisorRecord.fromSnapshot(doc));
          } catch (error) {
            debugPrint('Failed to parse supervisor ${doc.id}: $error');
          }
        }

        supervisors.sort(
          (left, right) => left.fullName
              .toLowerCase()
              .compareTo(right.fullName.toLowerCase()),
        );
        return supervisors;
      });
});

final lastAssignmentResultProvider = StateProvider<String?>((ref) => null);

Future<void> _refreshAllocationData(WidgetRef ref) async {
  ref.invalidate(allocationStudentsProvider);
  ref.invalidate(allocationSupervisorsProvider);
}

Future<void> _fixSupervisorLoads(BuildContext context) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Recalculate Supervisor Loads?'),
      content: const Text(
        'This counts the students currently linked to each supervisor and updates '
        'their load fields to match.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Recalculate'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Recalculating supervisor loads...'),
        ],
      ),
    ),
  );

  try {
    final db = FirebaseFirestore.instance;
    final studentsSnap = await db.collection('students').get();
    final supervisorStudents = <String, List<String>>{};

    for (final studentDoc in studentsSnap.docs) {
      final supervisorId = _readOptionalString(
        studentDoc.data()['currentSupervisorId'],
      );

      if (supervisorId == null) {
        continue;
      }

      supervisorStudents.putIfAbsent(supervisorId, () => <String>[]);
      supervisorStudents[supervisorId]!.add(studentDoc.id);
    }

    final supervisorsSnap = await db.collection('supervisorProfiles').get();
    final batch = db.batch();

    for (final supervisorDoc in supervisorsSnap.docs) {
      final assignedStudents =
          supervisorStudents[supervisorDoc.id] ?? <String>[];

      batch.update(supervisorDoc.reference, {
        'currentLoad': assignedStudents.length,
        'assignedStudentIds': assignedStudents,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (context.mounted) {
      Navigator.pop(context);
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          'Recalculated loads for ${supervisorsSnap.size} supervisors.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  } catch (error) {
    if (context.mounted) {
      Navigator.pop(context);
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Recalculation failed: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

String? _readOptionalString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

String _readStudentGenderLabel(Map<String, dynamic> data) {
  final rawGender = _readString(
    data,
    ['gender', 'sex', 'studentGender', 'userGender'],
  );

  if (rawGender == null) {
    return 'Not set';
  }

  final lower = rawGender.toLowerCase();
  if (lower == 'm' || lower == 'male') return 'Male';
  if (lower == 'f' || lower == 'female') return 'Female';
  return rawGender;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

DataRow _emptyRow(String label, int columnCount) {
  return DataRow(
    cells: List.generate(
      columnCount,
      (index) => DataCell(index == 0 ? Text(label) : const SizedBox.shrink()),
    ),
  );
}

class SupervisorAllocationPage extends ConsumerStatefulWidget {
  const SupervisorAllocationPage({super.key});

  @override
  ConsumerState<SupervisorAllocationPage> createState() =>
      _SupervisorAllocationPageState();
}

class _SupervisorAllocationPageState
    extends ConsumerState<SupervisorAllocationPage> {
  String _studentSearchQuery = '';
  final GlobalKey _manualAssignmentSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentsAsync = ref.watch(allocationStudentsProvider);
    final supervisorsAsync = ref.watch(allocationSupervisorsProvider);
    final lastResult = ref.watch(lastAssignmentResultProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refreshAllocationData(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supervisor Allocation',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assign students to supervisors.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'fix_loads') {
                          _fixSupervisorLoads(context);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'fix_loads',
                          child: Row(
                            children: [
                              Icon(Icons.sync, size: 18),
                              SizedBox(width: 12),
                              Text('Recalculate Loads'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _refreshAllocationData(ref),
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lastResult != null) ...[
              _ResultCard(
                message: lastResult,
                onClear: () {
                  ref.read(lastAssignmentResultProvider.notifier).state = null;
                },
              ),
              const SizedBox(height: 16),
            ],
            _SectionCard(
              title: 'Allocation Summary',
              subtitle: 'Current student counts and supervisor capacity.',
              child: studentsAsync.when(
                data: (students) => supervisorsAsync.when(
                  data: (supervisors) {
                    final unassignedCount =
                        students.where((student) => !student.isAssigned).length;
                    final assignedCount = students.length - unassignedCount;
                    final availableSupervisors = supervisors
                        .where((supervisor) => supervisor.hasCapacity)
                        .length;

                    return _MetricTable(
                      rows: [
                        MapEntry('Total Students', students.length.toString()),
                        MapEntry('Assigned Students', assignedCount.toString()),
                        MapEntry(
                          'Unassigned Students',
                          unassignedCount.toString(),
                        ),
                        MapEntry(
                          'Available Supervisors',
                          availableSupervisors.toString(),
                        ),
                      ],
                    );
                  },
                  loading: _buildSectionLoader,
                  error: _buildSectionError,
                ),
                loading: _buildSectionLoader,
                error: _buildSectionError,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionBar(studentsAsync),
            const SizedBox(height: 16),
            _buildSupervisorSection(supervisorsAsync),
            const SizedBox(height: 16),
            _buildManualAssignmentSection(studentsAsync, supervisorsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(
    AsyncValue<List<_AllocationStudentRecord>> studentsAsync,
  ) {
    final unassignedCount = studentsAsync.maybeWhen(
      data: (students) => students.where((student) => !student.isAssigned).length,
      orElse: () => 0,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 250,
          child: FilledButton.icon(
            onPressed: unassignedCount == 0
                ? null
                : () => _runAutoAssignment(unassignedCount),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Run Auto Assignment'),
          ),
        ),
        SizedBox(
          width: 220,
          child: OutlinedButton.icon(
            onPressed: _jumpToManualAssignment,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Manual Assignment'),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorSection(
    AsyncValue<List<_AllocationSupervisorRecord>> supervisorsAsync,
  ) {
    return _SectionCard(
      title: 'Supervisor Capacity',
      subtitle: 'Supervisor availability.',
      child: supervisorsAsync.when(
        data: (supervisors) => _buildTableShell(
          columns: const [
            DataColumn(label: Text('Supervisor')),
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('Specialties')),
            DataColumn(label: Text('Load')),
            DataColumn(label: Text('Available')),
          ],
          rows: supervisors.isEmpty
              ? [_emptyRow('No supervisors found.', 5)]
              : supervisors.map((supervisor) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Text(
                            supervisor.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 170,
                          child: Text(supervisor.departmentLabel),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            supervisor.specialtiesLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(supervisor.loadLabel)),
                      DataCell(Text(supervisor.availabilityLabel)),
                    ],
                  );
                }).toList(),
        ),
        loading: _buildSectionLoader,
        error: _buildSectionError,
      ),
    );
  }

  Widget _buildManualAssignmentSection(
    AsyncValue<List<_AllocationStudentRecord>> studentsAsync,
    AsyncValue<List<_AllocationSupervisorRecord>> supervisorsAsync,
  ) {
    return Container(
      key: _manualAssignmentSectionKey,
      child: _SectionCard(
        title: 'Manual Assignment',
        subtitle: 'Assign or reassign students.',
        child: studentsAsync.when(
          data: (students) => supervisorsAsync.when(
            data: (supervisors) {
              final filteredStudents = _filterStudents(students);
              final hasAssignableSupervisors =
                  supervisors.any((supervisor) => supervisor.hasCapacity);
              final supervisorNames = {
                for (final supervisor in supervisors)
                  supervisor.id: supervisor.fullName,
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Search by student, registration number, or programme...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _studentSearchQuery = value.toLowerCase());
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTableShell(
                    columns: const [
                      DataColumn(label: Text('Student')),
                      DataColumn(label: Text('Reg No.')),
                      DataColumn(label: Text('Programme')),
                      DataColumn(label: Text('Current Supervisor')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: filteredStudents.isEmpty
                        ? [
                            _emptyRow(
                              students.isEmpty
                                  ? 'No students found.'
                                  : 'No students match the current search.',
                              6,
                            ),
                          ]
                        : filteredStudents.map((student) {
                            final currentSupervisorName =
                                student.currentSupervisorId == null
                                    ? 'Not assigned'
                                    : (supervisorNames[student.currentSupervisorId] ??
                                        'Assigned');
                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 190,
                                    child: Text(
                                      student.fullName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(student.registrationNumber)),
                                DataCell(
                                  SizedBox(
                                    width: 210,
                                    child: Text(
                                      student.program,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 190,
                                    child: Text(
                                      currentSupervisorName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    student.isAssigned
                                        ? 'Assigned'
                                        : 'Unassigned',
                                  ),
                                ),
                                DataCell(
                                  hasAssignableSupervisors
                                      ? OutlinedButton.icon(
                                          onPressed: () =>
                                              _openManualAssignmentDialog(
                                            student,
                                            supervisors,
                                          ),
                                          icon:
                                              const Icon(Icons.person_add_alt_1),
                                          label: Text(
                                            student.isAssigned
                                                ? 'Reassign'
                                                : 'Assign',
                                          ),
                                        )
                                      : const Text('No open supervisor'),
                                ),
                              ],
                            );
                          }).toList(),
                  ),
                ],
              );
            },
            loading: _buildSectionLoader,
            error: _buildSectionError,
          ),
          loading: _buildSectionLoader,
          error: _buildSectionError,
        ),
      ),
    );
  }

  Future<void> _jumpToManualAssignment() async {
    final context = _manualAssignmentSectionKey.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  List<_AllocationStudentRecord> _filterStudents(
    List<_AllocationStudentRecord> students,
  ) {
    final query = _studentSearchQuery.trim();
    if (query.isEmpty) return students;

    return students.where((student) {
      return student.fullName.toLowerCase().contains(query) ||
          student.registrationNumber.toLowerCase().contains(query) ||
          student.program.toLowerCase().contains(query);
    }).toList();
  }

  int _manualSupervisorScore(
    _AllocationSupervisorRecord supervisor,
    _AllocationStudentRecord student,
  ) {
    var score = 0;
    if (_matchesProgram(supervisor, student.program)) {
      score += 100;
    }
    score += supervisor.remainingSlots * 3;
    score -= supervisor.currentLoad;
    return score;
  }

  bool _matchesProgram(
    _AllocationSupervisorRecord supervisor,
    String studentProgram,
  ) {
    final normalizedProgram = _normalizeComparable(studentProgram);
    if (normalizedProgram.isEmpty) {
      return false;
    }

    final specialtyMatch = supervisor.programSpecialties.any((specialty) {
      final normalizedSpecialty = _normalizeComparable(specialty);
      return normalizedSpecialty == normalizedProgram ||
          normalizedSpecialty.contains(normalizedProgram) ||
          normalizedProgram.contains(normalizedSpecialty);
    });

    final normalizedDepartment =
        _normalizeComparable(supervisor.departmentLabel);

    return specialtyMatch ||
        normalizedDepartment == normalizedProgram ||
        normalizedDepartment.contains(normalizedProgram) ||
        normalizedProgram.contains(normalizedDepartment);
  }

  Future<void> _runAutoAssignment(int unassignedCount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Auto Assignment?'),
        content: Text(
          'This will assign $unassignedCount unassigned students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Assign Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Assigning students...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result =
          await FirebaseFunctions.instance.httpsCallable('assignSupervisors').call(
        {
          'reAssignAll': false,
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }

      final data = Map<String, dynamic>.from(result.data as Map);
      final message = data['message'] as String? ?? 'Students assigned.';

      ref.read(lastAssignmentResultProvider.notifier).state = message;
      await _refreshAllocationData(ref);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assignment failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openManualAssignmentDialog(
    _AllocationStudentRecord student,
    List<_AllocationSupervisorRecord> supervisors,
  ) async {
    var currentSupervisorName = 'Not assigned';
    if (student.currentSupervisorId != null) {
      final matches = supervisors
          .where((supervisor) => supervisor.id == student.currentSupervisorId)
          .toList();
      currentSupervisorName =
          matches.isEmpty ? 'Assigned' : matches.first.fullName;
    }
    final availableSupervisors = supervisors
        .where((supervisor) => supervisor.hasCapacity)
        .toList()
      ..sort(
        (left, right) => _manualSupervisorScore(right, student)
            .compareTo(_manualSupervisorScore(left, student)),
      );

    if (availableSupervisors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No supervisors have open capacity right now.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String selectedSupervisorId = availableSupervisors.first.id;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(student.isAssigned ? 'Reassign Student' : 'Assign Student'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text('Reg No.: ${student.registrationNumber}'),
                Text('Programme: ${student.program}'),
                Text('Gender: ${student.gender}'),
                Text('Current supervisor: $currentSupervisorName'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSupervisorId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Supervisor',
                    border: OutlineInputBorder(),
                  ),
                  items: availableSupervisors.map((supervisor) {
                    return DropdownMenuItem(
                      value: supervisor.id,
                      child: Text(
                        '${supervisor.fullName} | ${supervisor.loadLabel}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedSupervisorId = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(student.isAssigned ? 'Reassign Student' : 'Assign Student'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final selectedSupervisor = availableSupervisors.firstWhere(
      (supervisor) => supervisor.id == selectedSupervisorId,
    );

    await _runManualAssignment(student, selectedSupervisor);
  }

  Future<void> _runManualAssignment(
    _AllocationStudentRecord student,
    _AllocationSupervisorRecord supervisor,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving manual assignment...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('manualAssignSupervisor')
          .call({
        'studentId': student.id,
        'supervisorId': supervisor.id,
      });

      if (mounted) {
        Navigator.pop(context);
      }

      final data = Map<String, dynamic>.from(result.data as Map);
      final message =
          data['message'] as String? ?? 'Manual assignment completed.';

      ref.read(lastAssignmentResultProvider.notifier).state = message;
      await _refreshAllocationData(ref);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Manual assignment failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTableShell({
    required List<DataColumn> columns,
    required List<DataRow> rows,
  }) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 16,
            headingRowHeight: 50,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            headingRowColor: WidgetStatePropertyAll(
              theme.colorScheme.primaryContainer.withOpacity(0.35),
            ),
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSectionError(Object error, StackTrace stackTrace) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Failed to load this section: $error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  String _normalizeComparable(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricTable extends StatelessWidget {
  const _MetricTable({required this.rows});

  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 16,
            headingRowHeight: 50,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            headingRowColor: WidgetStatePropertyAll(
              theme.colorScheme.primaryContainer.withOpacity(0.35),
            ),
            columns: const [
              DataColumn(label: Text('Metric')),
              DataColumn(label: Text('Count')),
            ],
            rows: rows.map((row) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      row.key,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(Text(row.value)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.message,
    required this.onClear,
  });

  final String message;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.35),
      child: ListTile(
        leading: Icon(
          Icons.check_circle,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _AllocationStudentRecord {
  const _AllocationStudentRecord({
    required this.id,
    required this.fullName,
    required this.registrationNumber,
    required this.program,
    required this.gender,
    required this.currentSupervisorId,
  });

  final String id;
  final String fullName;
  final String registrationNumber;
  final String program;
  final String gender;
  final String? currentSupervisorId;

  bool get isAssigned => currentSupervisorId != null;

  factory _AllocationStudentRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return _AllocationStudentRecord(
      id: snapshot.id,
      fullName:
          _readString(data, ['fullName', 'displayName']) ?? 'Unknown Student',
      registrationNumber: _readString(
            data,
            ['registrationNumber', 'registrationNo'],
          ) ??
          'Not set',
      program: _readString(data, ['program']) ?? 'Not set',
      gender: _readStudentGenderLabel(data),
      currentSupervisorId: _readOptionalString(data['currentSupervisorId']),
    );
  }
}

class _AllocationSupervisorRecord {
  const _AllocationSupervisorRecord({
    required this.id,
    required this.fullName,
    required this.department,
    required this.programSpecialties,
    required this.currentLoad,
    required this.maxStudents,
    required this.isAvailable,
  });

  final String id;
  final String fullName;
  final String department;
  final List<String> programSpecialties;
  final int currentLoad;
  final int maxStudents;
  final bool isAvailable;

  int get remainingSlots =>
      currentLoad >= maxStudents ? 0 : maxStudents - currentLoad;

  bool get hasCapacity => isAvailable && currentLoad < maxStudents;

  String get departmentLabel => department.isEmpty ? 'Not set' : department;

  String get specialtiesLabel =>
      programSpecialties.isEmpty ? 'Not set' : programSpecialties.join(', ');

  String get loadLabel => '$currentLoad / $maxStudents';

  String get availabilityLabel {
    if (!isAvailable) return 'Unavailable';
    if (remainingSlots == 0) return 'Full';
    return '$remainingSlots left';
  }

  factory _AllocationSupervisorRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawMaxStudents = data['maxStudents'];
    final parsedMaxStudents =
        rawMaxStudents is num ? rawMaxStudents.toInt() : _defaultSupervisorCapacity;

    return _AllocationSupervisorRecord(
      id: snapshot.id,
      fullName:
          _readString(data, ['fullName', 'FullName']) ?? 'Unknown Supervisor',
      department: _readString(data, ['department']) ?? '',
      programSpecialties: _readStringList(data['programSpecialties']),
      currentLoad: data['currentLoad'] is num
          ? (data['currentLoad'] as num).toInt()
          : 0,
      maxStudents:
          parsedMaxStudents <= 0 ? _defaultSupervisorCapacity : parsedMaxStudents,
      isAvailable: data['isAvailable'] is bool ? data['isAvailable'] as bool : true,
    );
  }
}
