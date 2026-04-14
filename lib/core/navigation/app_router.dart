// lib/core/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/auth/data/models/user_model.dart';
import 'package:dims/features/splash/splash_page.dart';
import 'package:dims/features/auth/presentation/login_page.dart';
import 'package:dims/features/auth/presentation/register_page.dart';
import 'package:dims/features/auth/presentation/pending_approval_page.dart';
import 'package:dims/features/student/presentation/pages/complete_profile_page.dart';
import 'package:dims/features/student/presentation/student_dashboard.dart';
import 'package:dims/features/supervisor/presentation/screens/supervisor_dashboard.dart';
import 'package:dims/features/admin/presentation/admin_dashboard.dart';
import 'package:dims/features/landing/presentation/landing_page.dart';

// Company Supervisor imports
import 'package:dims/features/companies/presentation/pages/setup_company_supervisor_account_page.dart';
import 'package:dims/features/companies/presentation/pages/company_supervisor_dashboard.dart';
import 'package:dims/features/companies/presentation/pages/student_details_page.dart';
import 'package:dims/features/companies/presentation/pages/logbook_review_page.dart';
import 'package:dims/features/companies/presentation/pages/final_evaluation_form_page.dart';

// Admin imports
import 'package:dims/features/admin/presentation/pages/companies_management_page.dart';
import 'package:dims/features/admin/presentation/pages/pending_placements_page.dart';

// Student imports
import 'package:dims/features/student/presentation/pages/upload_acceptance_letter_page.dart';
import 'package:dims/features/student/presentation/pages/my_placement_status_page.dart';
import 'package:dims/features/student/presentation/pages/start_internship_page.dart';
import 'package:dims/features/student/presentation/pages/enhanced_logbook_form_page.dart';
import 'package:dims/features/logbook/presentation/pages/daily_entry_form_page.dart';
import 'package:dims/features/student/presentation/pages/daily_logbook_list_page.dart';
import 'package:dims/features/student/presentation/pages/final_report_submission_page.dart';
import 'package:dims/features/student/presentation/pages/student_assessment_page.dart';
import 'package:dims/features/student/presentation/pages/weekly_logbook_list_page.dart';

// ── Profile completeness check ────────────────────────────────────────────────
final profileCheckProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('students')
      .doc(uid)
      .get();

  if (!doc.exists || doc.data() == null) {
    return {'exists': false, 'isComplete': false};
  }

  final data = doc.data()!;
  final registrationNumber = data['registrationNumber'] as String?;
  final program = data['program'] as String?;
  final academicYear = data['academicYear'] as int?;

  final isComplete = registrationNumber != null &&
      registrationNumber.isNotEmpty &&
      registrationNumber != 'PENDING' &&
      program != null &&
      program.isNotEmpty &&
      program != 'PENDING' &&
      academicYear != null &&
      academicYear > 0;

  return {'exists': true, 'isComplete': isComplete};
});

// ── Router ────────────────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // ── Start on splash; splash decides where to go next ─────────────────
    initialLocation: '/',
    refreshListenable: RouterNotifier(ref),
    redirect: (BuildContext context, GoRouterState state) async {
      final path = state.uri.path;
      final authState = ref.read(authStateProvider);
      final user = authState.value;

      // Wait for Firebase Auth to initialise
      if (authState.isLoading) return null;

      // ── Unauthenticated ───────────────────────────────────────────────
      if (user == null) {
        // These routes are always accessible without login
        const publicRoutes = [
          '/',
          '/landing',
          '/login',
          '/register',
          '/setup-company-supervisor',
        ];

        final isPublic = publicRoutes.contains(path) ||
            path.startsWith('/setup-company-supervisor');

        if (isPublic) return null;

        // Everything else → send to landing screen
        return '/landing';
      }

      // ── Awaiting approval ─────────────────────────────────────────────
      if (!user.isApproved && user.role != UserRole.companySupervisor) {
        if (path == '/pending-approval') return null;
        return '/pending-approval';
      }

      // ── Role-based redirects ──────────────────────────────────────────
      switch (user.role) {
        case UserRole.student:
          final profileStatus =
              await ref.read(profileCheckProvider(user.uid).future);
          final profileExists = profileStatus['exists'] as bool;
          final profileIsComplete = profileStatus['isComplete'] as bool;

          if (!profileExists || !profileIsComplete) {
            if (path == '/complete-profile') return null;
            return '/complete-profile';
          }

          // Don't redirect away if already in student area
          if (path.startsWith('/student/') ||
              path == '/complete-profile') {
            return null;
          }

          // Landing/login/splash → send to dashboard once logged in
          if (path == '/landing' ||
              path == '/login' ||
              path == '/register' ||
              path == '/') {
            return '/student/dashboard';
          }

          return '/student/dashboard';

        case UserRole.supervisor:
          if (path.startsWith('/supervisor/')) return null;
          return '/supervisor/dashboard';

        case UserRole.companySupervisor:
          if (path.startsWith('/company-supervisor/')) return null;
          return '/company-supervisor/dashboard';

        case UserRole.admin:
          if (path.startsWith('/admin/')) return null;
          return '/admin/dashboard';

        default:
          return '/login';
      }
    },

    routes: [
      // ════════════════════════════════════════════════════════════════════
      // PUBLIC ROUTES
      // ════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),

      // ── Public landing screen (unauthenticated home) ──────────────────
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingPage(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalPage(),
      ),
      GoRoute(
        path: '/setup-company-supervisor',
        builder: (context, state) {
          final email =
              state.uri.queryParameters['email'] ?? '';
          final companyId =
              state.uri.queryParameters['companyId'] ?? '';
          final companyName =
              state.uri.queryParameters['companyName'] ?? '';
          final supervisorName =
              state.uri.queryParameters['name'];
          return SetupCompanySupervisorAccountPage(
            email: email,
            companyId: companyId,
            companyName: companyName,
            supervisorName: supervisorName,
          );
        },
      ),

      // ════════════════════════════════════════════════════════════════════
      // STUDENT ROUTES
      // ════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/student/upload-letter',
        builder: (context, state) => const UploadAcceptanceLetterPage(),
      ),
      GoRoute(
        path: '/student/placement-status',
        builder: (context, state) => const MyPlacementStatusPage(),
      ),
      GoRoute(
        path: '/student/start-internship',
        builder: (context, state) => const StartInternshipPage(),
      ),
      GoRoute(
        path: '/student/submit-logbook',
        builder: (context, state) => const EnhancedLogbookFormPage(),
      ),
      GoRoute(
        path: '/student/submit-daily-logbook',
        builder: (context, state) => const DailyEntryFormPage(),
      ),
      GoRoute(
        path: '/student/logbook/daily',
        builder: (context, state) => const DailyLogbookListPage(),
      ),
      GoRoute(
        path: '/student/logbook/weekly',
        builder: (context, state) => const WeeklyLogbookListPage(),
      ),
      GoRoute(
        path: '/student/final-report',
        builder: (context, state) => const FinalReportSubmissionPage(),
      ),
      GoRoute(
        path: '/student/assessment',
        builder: (context, state) => const StudentAssessmentPage(),
      ),

      // ════════════════════════════════════════════════════════════════════
      // UNIVERSITY SUPERVISOR ROUTES
      // ════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/supervisor/dashboard',
        builder: (context, state) => const SupervisorDashboard(),
      ),

      // ════════════════════════════════════════════════════════════════════
      // COMPANY SUPERVISOR ROUTES
      // ════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/company-supervisor/dashboard',
        builder: (context, state) =>
            const CompanySupervisorDashboard(),
      ),
      GoRoute(
        path: '/company-supervisor/student/:studentId',
        builder: (context, state) {
          final studentId = state.pathParameters['studentId']!;
          return StudentDetailsPage(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/company-supervisor/review-logbook/:logbookId',
        builder: (context, state) {
          final logbookId = state.pathParameters['logbookId']!;
          return LogbookReviewPage(logbookId: logbookId);
        },
      ),
      GoRoute(
        path: '/company-supervisor/evaluate/:placementId/:studentId',
        builder: (context, state) {
          final placementId = state.pathParameters['placementId']!;
          final studentId = state.pathParameters['studentId']!;
          return FinalEvaluationFormPage(
            placementId: placementId,
            studentId: studentId,
          );
        },
      ),

      // ════════════════════════════════════════════════════════════════════
      // ADMIN ROUTES
      // ════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/companies',
        builder: (context, state) => const CompaniesManagementPage(),
      ),
      GoRoute(
        path: '/admin/placements/pending',
        builder: (context, state) => const PendingPlacementsPage(),
      ),
    ],
  );
});

/// Listens to auth state changes and triggers router refresh
class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
