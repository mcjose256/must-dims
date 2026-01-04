import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Feature Imports
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/auth/data/models/user_model.dart';
import 'package:dims/features/splash/splash_page.dart';
import 'package:dims/features/auth/presentation/login_page.dart';
import 'package:dims/features/auth/presentation/register_page.dart';
import 'package:dims/features/auth/presentation/pending_approval_page.dart';
import 'package:dims/features/student/presentation/pages/complete_profile_page.dart';
import 'package:dims/features/student/presentation/student_dashboard.dart';
// import 'package:dims/features/supervisor/presentation/supervisor_dashboard.dart';
import 'package:dims/features/admin/presentation/admin_dashboard.dart';

// Provider for the profile check to keep logic clean
final profileCheckProvider = FutureProvider.family<bool, String>((ref, uid) async {
  final doc = await FirebaseFirestore.instance
      .collection('students')  // Changed from 'student_profiles' to 'students'
      .doc(uid)
      .get();
  return doc.exists;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: RouterNotifier(ref),
    redirect: (BuildContext context, GoRouterState state) async {
      // 1. ALWAYS read the state fresh inside the redirect
      final authState = ref.read(authStateProvider);
      final path = state.uri.path;
      
      final publicRoutes = ['/', '/login', '/register'];
      final isPublicRoute = publicRoutes.contains(path);

      // DEBUG LOGS - Check your terminal/debug console!
      print('--- ROUTER REDIRECT ---');
      print('Current Path: $path');
      print('Auth Loading: ${authState.isLoading}');
      
      if (authState.isLoading) return null;

      final user = authState.value;
      print('User logged in: ${user != null}');
      if (user != null) {
        print('User Role: ${user.role}');
        print('User Approved: ${user.isApproved}');
      }

      // 1. No user logged in
      if (user == null) {
        return isPublicRoute ? null : '/login';
      }

      // 2. User is logged in, handle Approval
      if (!user.isApproved) {
        print('Redirecting to pending approval...');
        return path == '/pending-approval' ? null : '/pending-approval';
      }

      // 3. Role-based Navigation
      switch (user.role) {
        case UserRole.admin:
          if (isPublicRoute || path == '/pending-approval') {
            print('Admin detected, redirecting to dashboard...');
            return '/admin/dashboard';
          }
          return null;

        case UserRole.student:
          final hasProfile = await ref.read(profileCheckProvider(user.uid).future);
          print('Student has profile: $hasProfile');
          if (!hasProfile) {
            print('No profile, redirecting to complete-profile...');
            return path == '/complete-profile' ? null : '/complete-profile';
          }
          if (isPublicRoute || path == '/pending-approval' || path == '/complete-profile') {
            print('Profile complete, redirecting to student dashboard...');
            return '/student/dashboard';
          }
          return null;

        case UserRole.supervisor:
          if (isPublicRoute || path == '/pending-approval') {
            // return '/supervisor/dashboard';
            // Temporarily redirect to a placeholder until supervisor dashboard is ready
            return '/login'; // Remove this line when supervisor dashboard is ready
          }
          return null;
          
        default:
          return null;
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
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      // Uncomment when supervisor dashboard is ready
      // GoRoute(
      //   path: '/supervisor/dashboard',
      //   builder: (context, state) => const SupervisorDashboard(),
      // ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});

/// A cleaner way to handle GoRouter refreshes with Riverpod
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterNotifier(this._ref) {
    // Listen to the auth state. Whenever it changes from Loading to Data, 
    // or from User to Null, notify GoRouter to re-run the redirect logic.
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}