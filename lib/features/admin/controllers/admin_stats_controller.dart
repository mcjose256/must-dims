// lib/features/admin/controllers/admin_stats_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/placements/data/models/placement_model.dart';

// ============================================================================
// MODELS
// ============================================================================

class AdminStats {
  final int totalStudents;
  final int totalSupervisors;
  final int pendingApprovals;
  final int activeInternships;
  final int totalCompanies;
  final double completionRate;
  final int studentsWithPlacement;

  AdminStats({
    required this.totalStudents,
    required this.totalSupervisors,
    required this.pendingApprovals,
    required this.activeInternships,
    required this.totalCompanies,
    required this.completionRate,
    required this.studentsWithPlacement,
  });

  factory AdminStats.empty() {
    return AdminStats(
      totalStudents: 0,
      totalSupervisors: 0,
      pendingApprovals: 0,
      activeInternships: 0,
      totalCompanies: 0,
      completionRate: 0.0,
      studentsWithPlacement: 0,
    );
  }
}

class StudentPlacementReportRow {
  static const int expectedSupervisorVisits = 2;
  static const String unassignedSupervisorLabel = 'Not assigned';

  final String studentName;
  final String registrationNumber;
  final String program;
  final String internshipStatus;
  final String supervisorName;
  final String companyName;
  final String district;
  final String visitOneStatus;
  final String visitTwoStatus;
  final int visitsCompleted;

  const StudentPlacementReportRow({
    required this.studentName,
    required this.registrationNumber,
    required this.program,
    required this.internshipStatus,
    required this.supervisorName,
    required this.companyName,
    required this.district,
    required this.visitOneStatus,
    required this.visitTwoStatus,
    required this.visitsCompleted,
  });

  bool get hasSupervisor => supervisorName != unassignedSupervisorLabel;

  bool get isVisitTrackable =>
      visitOneStatus != 'N/A' || visitTwoStatus != 'N/A';

  bool get hasVisited => visitsCompleted > 0;

  bool get hasNotVisited =>
      visitOneStatus == 'Not visited' || visitTwoStatus == 'Not visited';

  int get notVisitedCount => [visitOneStatus, visitTwoStatus]
      .where((status) => status == 'Not visited')
      .length;

  String get visitCoverageLabel {
    if (!isVisitTrackable) return 'No visit plan';

    if (hasNotVisited && visitsCompleted > 0) {
      final completedLabel = visitsCompleted == 1
          ? '1 visit completed'
          : '$visitsCompleted visits completed';
      final notVisitedLabel = notVisitedCount == 1
          ? '1 visit marked not visited'
          : '$notVisitedCount visits marked not visited';
      return '$completedLabel, $notVisitedLabel';
    }

    if (hasNotVisited) {
      return notVisitedCount == 1
          ? '1 visit marked not visited'
          : '$notVisitedCount visits marked not visited';
    }

    return '$visitsCompleted of $expectedSupervisorVisits visits recorded';
  }
}

class DistrictAllocationStat {
  final String district;
  final int studentCount;

  const DistrictAllocationStat({
    required this.district,
    required this.studentCount,
  });
}

int _countApprovedOrImportedProfiles({
  required QuerySnapshot<Map<String, dynamic>> profilesSnapshot,
  required QuerySnapshot<Map<String, dynamic>> usersSnapshot,
}) {
  final usersById = {
    for (final doc in usersSnapshot.docs) doc.id: doc.data(),
  };

  return profilesSnapshot.docs.where((profileDoc) {
    final userData = usersById[profileDoc.id];
    if (userData == null) return true;

    final isApproved = userData['isApproved'];
    return isApproved is bool ? isApproved : true;
  }).length;
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider that fetches all admin statistics
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  try {
    // Align overview counts with the operational profile collections while
    // still respecting approval state when a matching user account exists.
    final results = await Future.wait([
      firestore.collection('students').get(),
      firestore.collection('users').where('role', isEqualTo: 'student').get(),
      firestore.collection('supervisorProfiles').get(),
      firestore
          .collection('users')
          .where('role', isEqualTo: 'supervisor')
          .get(),
      firestore
          .collection('users')
          .where('isApproved', isEqualTo: false)
          .count()
          .get(),
    ]);

    final totalStudents = _countApprovedOrImportedProfiles(
      profilesSnapshot: results[0] as QuerySnapshot<Map<String, dynamic>>,
      usersSnapshot: results[1] as QuerySnapshot<Map<String, dynamic>>,
    );
    final totalSupervisors = _countApprovedOrImportedProfiles(
      profilesSnapshot: results[2] as QuerySnapshot<Map<String, dynamic>>,
      usersSnapshot: results[3] as QuerySnapshot<Map<String, dynamic>>,
    );
    final pendingApprovals = (results[4] as AggregateQuerySnapshot).count ?? 0;

    final placementsSnapshot = await firestore.collection('placements').get();
    final companiesSnapshot =
        await firestore.collection('companies').count().get();

    final placementDocs = placementsSnapshot.docs;
    final activeInternships = placementDocs.where((doc) {
      final status = doc.data()['status'] as String? ?? '';
      return status == 'approved' || status == 'active' || status == 'extended';
    }).length;
    final completedCount = placementDocs.where((doc) {
      final status = doc.data()['status'] as String? ?? '';
      return status == 'completed';
    }).length;
    final totalPlacements = placementDocs.length;
    final completionRate =
        totalPlacements == 0 ? 0.0 : (completedCount / totalPlacements) * 100;
    final studentsWithPlacement = placementDocs
        .map((doc) => doc.data()['studentId'] as String?)
        .whereType<String>()
        .toSet()
        .length;
    final totalCompanies = companiesSnapshot.count ?? 0;

    return AdminStats(
      totalStudents: totalStudents,
      totalSupervisors: totalSupervisors,
      pendingApprovals: pendingApprovals,
      activeInternships: activeInternships,
      totalCompanies: totalCompanies,
      completionRate: completionRate,
      studentsWithPlacement: studentsWithPlacement,
    );
  } catch (e) {
    throw Exception('Failed to load admin stats: $e');
  }
});

String _normalizeDistrict(Map<String, dynamic>? company) {
  if (company == null) return 'Unassigned';

  final city = (company['city'] as String?)?.trim();
  if (city != null && city.isNotEmpty) return _titleCase(city);

  final location = (company['location'] as String?)?.trim();
  if (location != null && location.isNotEmpty) {
    final normalized = location.split(',').first.trim();
    return _titleCase(normalized);
  }

  final address = (company['address'] as String?)?.trim();
  if (address != null && address.isNotEmpty) {
    final normalized = address.split(',').first.trim();
    return _titleCase(normalized);
  }

  return 'Unassigned';
}

String _titleCase(String value) {
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _visitStatusLabel(SupervisorVisitStatus status) {
  switch (status) {
    case SupervisorVisitStatus.visited:
      return 'Visited';
    case SupervisorVisitStatus.notVisited:
      return 'Not visited';
    case SupervisorVisitStatus.pending:
      return 'Pending';
  }
}

final studentPlacementReportProvider =
    FutureProvider<List<StudentPlacementReportRow>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final studentsSnapshot = await firestore.collection('students').get();
  final placementsSnapshot = await firestore.collection('placements').get();
  final supervisorsSnapshot =
      await firestore.collection('supervisorProfiles').get();
  final companiesSnapshot = await firestore.collection('companies').get();

  final placementsById = {
    for (final doc in placementsSnapshot.docs)
      doc.id: PlacementModel.fromFirestore(doc, null),
  };
  final placementsByStudentId = {
    for (final doc in placementsSnapshot.docs)
      if ((doc.data()['studentId'] as String?) != null)
        doc.data()['studentId'] as String:
            PlacementModel.fromFirestore(doc, null),
  };
  final supervisorsById = {
    for (final doc in supervisorsSnapshot.docs) doc.id: doc.data(),
  };
  final companiesById = {
    for (final doc in companiesSnapshot.docs) doc.id: doc.data(),
  };

  final rows = studentsSnapshot.docs.map((doc) {
    final data = doc.data();
    final currentPlacementId = data['currentPlacementId'] as String?;
    final placement = currentPlacementId != null
        ? placementsById[currentPlacementId]
        : placementsByStudentId[doc.id];
    final companyId = placement?.companyId;
    final company = companyId != null ? companiesById[companyId] : null;
    final supervisorId = data['currentSupervisorId'] as String?;
    final supervisor =
        supervisorId != null ? supervisorsById[supervisorId] : null;
    final visitSlots =
        placement?.supervisorVisitSlots ?? const <SupervisorVisitRecord>[];
    final visitOneStatus =
        visitSlots.isEmpty ? 'N/A' : _visitStatusLabel(visitSlots[0].status);
    final visitTwoStatus =
        visitSlots.length < 2 ? 'N/A' : _visitStatusLabel(visitSlots[1].status);
    final visitsCompleted = visitSlots
        .where((visit) => visit.status == SupervisorVisitStatus.visited)
        .length;

    return StudentPlacementReportRow(
      studentName: (data['fullName'] as String?) ?? 'Unknown student',
      registrationNumber: (data['registrationNumber'] as String?) ?? 'N/A',
      program: (data['program'] as String?) ?? 'N/A',
      internshipStatus: (data['internshipStatus'] as String?) ?? 'notStarted',
      supervisorName: (supervisor?['fullName'] as String?) ?? 'Not assigned',
      companyName: (company?['name'] as String?) ?? 'Not yet allocated',
      district: _normalizeDistrict(company),
      visitOneStatus: visitOneStatus,
      visitTwoStatus: visitTwoStatus,
      visitsCompleted: visitsCompleted,
    );
  }).toList()
    ..sort((a, b) => a.studentName.compareTo(b.studentName));

  return rows;
});

final districtAllocationStatsProvider =
    FutureProvider<List<DistrictAllocationStat>>((ref) async {
  final rows = await ref.watch(studentPlacementReportProvider.future);
  final counts = <String, int>{};

  for (final row in rows) {
    if (row.companyName == 'Not yet allocated') continue;
    counts[row.district] = (counts[row.district] ?? 0) + 1;
  }

  final stats = counts.entries
      .map(
        (entry) => DistrictAllocationStat(
          district: entry.key,
          studentCount: entry.value,
        ),
      )
      .toList()
    ..sort((a, b) => b.studentCount.compareTo(a.studentCount));

  return stats;
});

// ============================================================================
// ADDITIONAL STAT PROVIDERS
// ============================================================================

/// Get total users count (all roles, approved only)
final totalUsersProvider = FutureProvider<int>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  try {
    final snapshot = await firestore
        .collection('users')
        .where('isApproved', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
  } catch (e) {
    return 0;
  }
});

/// Get supervisor load distribution
/// Returns a map of supervisor ID to number of assigned students
final supervisorLoadProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    // TODO: Implement based on your assignments collection structure
    // Example:
    // final assignments = await firestore
    //     .collection('supervisor_assignments')
    //     .get();
    //
    // final loadMap = <String, int>{};
    // for (final doc in assignments.docs) {
    //   final supervisorId = doc.data()['supervisorId'] as String;
    //   loadMap[supervisorId] = (loadMap[supervisorId] ?? 0) + 1;
    // }
    // return loadMap;

    return {};
  } catch (e) {
    return {};
  }
});

/// Get recent activity/registrations
final recentActivityProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  try {
    final snapshot = await firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => {
              'type': 'registration',
              'user': doc.data(),
              'timestamp': doc.data()['createdAt'],
            })
        .toList();
  } catch (e) {
    return [];
  }
});
