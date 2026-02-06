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

// Helper provider to check if student profile exists
final profileCheckProvider = FutureProvider.family<bool, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('students')
      .doc(uid)
      .get();
  return doc.exists;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: RouterNotifier(ref),
    redirect: (BuildContext context, GoRouterState state) async {
      final path = state.uri.path;

      // Read auth state (StreamProvider) → no .notifier needed
      final authState = ref.read(authStateProvider);
      final user = authState.value;

      // Debug logs (keep for now — very helpful!)
      print('--- ROUTER REDIRECT ---');
      print('Current Path: $path');
      print('Auth Loading: ${authState.isLoading}');
      print('User logged in: ${user != null}');
      if (user != null) {
        print('User Role: ${user.role}');
        print('User Approved: ${user.isApproved}');
      }

      // 1. Still loading auth → stay where you are
      if (authState.isLoading) {
        return null;
      }

      // 2. Not logged in → force to login (unless already there)
      if (user == null) {
        final isPublicRoute = ['/', '/login', '/register'].contains(path);
        return isPublicRoute ? null : '/login';
      }

      // 3. Not approved → go to pending approval
      if (!user.isApproved) {
        return path == '/pending-approval' ? null : '/pending-approval';
      }

      // 4. Role-based protected routes
      switch (user.role) {
        case UserRole.student:
          // Check profile existence (only once per redirect)
          final hasProfile = await ref.read(profileCheckProvider(user.uid).future);
          print('Student has profile: $hasProfile');

          // No profile → force to complete-profile
          if (!hasProfile) {
            return path == '/complete-profile' ? null : '/complete-profile';
          }

          // Already completed → allow student routes, redirect only if outside
          if (path.startsWith('/student/')) {
            return null; // ← CRITICAL: prevents redirect loop!
          }

          print('Profile complete → redirecting to student dashboard');
          return '/student/dashboard';

        case UserRole.supervisor:
  // Allow supervisor routes
  if (path == '/supervisor/dashboard' || path.startsWith('/supervisor/')) {
    print('Supervisor already in dashboard area → stay');
    return null;
  }
  print('Supervisor redirecting to dashboard');
  return '/supervisor/dashboard';

        case UserRole.admin:
          if (path.startsWith('/admin/')) {
            return null;
          }
          return '/admin/dashboard';

        default:
          return '/login';
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
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
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfilePage(),
      ),
      // Student protected route
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
     GoRoute(
  path: '/supervisor/dashboard',
  builder: (context, state) => const SupervisorDashboard(),
),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});

/// Listens to auth changes and triggers router refresh
class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}