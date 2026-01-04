// lib/features/admin/controllers/admin_stats_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';

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

  AdminStats({
    required this.totalStudents,
    required this.totalSupervisors,
    required this.pendingApprovals,
    required this.activeInternships,
    required this.totalCompanies,
    required this.completionRate,
  });

  factory AdminStats.empty() {
    return AdminStats(
      totalStudents: 0,
      totalSupervisors: 0,
      pendingApprovals: 0,
      activeInternships: 0,
      totalCompanies: 0,
      completionRate: 0.0,
    );
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider that fetches all admin statistics
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  
  try {
    // Fetch all counts in parallel for better performance
    final results = await Future.wait([
      // Total approved students
      firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('isApproved', isEqualTo: true)
          .count()
          .get(),
      
      // Total approved supervisors
      firestore
          .collection('users')
          .where('role', isEqualTo: 'supervisor')
          .where('isApproved', isEqualTo: true)
          .count()
          .get(),
      
      // Pending approvals (all roles)
      firestore
          .collection('users')
          .where('isApproved', isEqualTo: false)
          .count()
          .get(),
    ]);

    final totalStudents = results[0].count ?? 0;
    final totalSupervisors = results[1].count ?? 0;
    final pendingApprovals = results[2].count ?? 0;

    // TODO: Add these queries when collections are ready
    // Query internships collection for active internships
    int activeInternships = 0;
    try {
      final internshipsSnapshot = await firestore
          .collection('internships')
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      activeInternships = internshipsSnapshot.count ?? 0;
    } catch (e) {
      // Collection doesn't exist yet
      activeInternships = 0;
    }

    // Query companies collection
    int totalCompanies = 0;
    try {
      final companiesSnapshot = await firestore
          .collection('companies')
          .count()
          .get();
      totalCompanies = companiesSnapshot.count ?? 0;
    } catch (e) {
      // Collection doesn't exist yet
      totalCompanies = 0;
    }

    // Calculate completion rate
    double completionRate = 0.0;
    try {
      if (activeInternships > 0) {
        final completedSnapshot = await firestore
            .collection('internships')
            .where('status', isEqualTo: 'completed')
            .count()
            .get();
        final completed = completedSnapshot.count ?? 0;
        final total = activeInternships + completed;
        completionRate = total > 0 ? (completed / total) * 100 : 0.0;
      }
    } catch (e) {
      completionRate = 0.0;
    }

    return AdminStats(
      totalStudents: totalStudents,
      totalSupervisors: totalSupervisors,
      pendingApprovals: pendingApprovals,
      activeInternships: activeInternships,
      totalCompanies: totalCompanies,
      completionRate: completionRate,
    );
  } catch (e) {
    throw Exception('Failed to load admin stats: $e');
  }
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
  final firestore = ref.watch(firestoreProvider);
  
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
final recentActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  
  try {
    final snapshot = await firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    
    return snapshot.docs.map((doc) => {
      'type': 'registration',
      'user': doc.data(),
      'timestamp': doc.data()['createdAt'],
    }).toList();
  } catch (e) {
    return [];
  }
});