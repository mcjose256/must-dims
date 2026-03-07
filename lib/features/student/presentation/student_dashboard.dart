// lib/features/student/presentation/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/student_controllers.dart';
import '../../placements/data/models/placement_model.dart';
import 'pages/student_overview_page.dart';
import 'pages/logbook_page.dart';
import 'pages/my_internship_page.dart';
import 'pages/student_profile_page.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final selectedStudentTabProvider = StateProvider<int>((ref) => 0);

/// Derives the correct status banner based on the student's current placement.
///
/// Priority order (top = most urgent):
///   1. No placement yet           → prompt to upload letter
///   2. pendingSupervisorReview    → waiting on supervisor
///   3. rejected                   → supervisor rejected, must resubmit
///   4. approved (not started)     → approved, prompt to begin
///   5. active / completed / etc.  → no banner needed
final placementStatusBannerProvider = Provider<_BannerData?>((ref) {
  final placementAsync = ref.watch(currentPlacementProvider);
  final profileAsync = ref.watch(studentProfileProvider);

  return placementAsync.when(
    data: (placement) {
      // ── No placement document yet ────────────────────────────────────────
      // Student is brand new or hasn't uploaded a letter yet.
      if (placement == null) {
        final profile = profileAsync.value;
        if (profile == null ||
            profile.internshipStatus.name == 'notStarted') {
          return _BannerData(
            status: 'no_placement',
            title: 'Start Your Internship',
            subtitle: 'Upload your company acceptance letter to begin',
            color: Colors.blue,
            icon: Icons.upload_file_rounded,
            route: '/student/upload-letter',
          );
        }
        return null;
      }

      switch (placement.status) {
        // ── Awaiting university supervisor review ──────────────────────────
        case PlacementStatus.pendingSupervisorReview:
          return _BannerData(
            status: 'pendingSupervisorReview',
            title: 'Awaiting Supervisor Review',
            subtitle: 'Your acceptance letter has been sent to your '
                'university supervisor for approval',
            color: Colors.orange,
            icon: Icons.hourglass_top_rounded,
            route: '/student/placement-status',
          );

        // ── Supervisor rejected the letter ─────────────────────────────────
        // Show their exact feedback as the subtitle so the student knows
        // what to fix without having to navigate anywhere.
        case PlacementStatus.rejected:
          final feedback = placement.supervisorFeedback;
          return _BannerData(
            status: 'rejected',
            title: 'Letter Needs Revision',
            subtitle: (feedback != null && feedback.isNotEmpty)
                ? 'Feedback: $feedback'
                : 'Your letter was not approved — tap to resubmit',
            color: Colors.red,
            icon: Icons.cancel_rounded,
            route: '/student/upload-letter',
          );

        // ── Supervisor approved — student can begin ────────────────────────
        case PlacementStatus.approved:
          return _BannerData(
            status: 'approved',
            title: 'Placement Approved! 🎉',
            subtitle: 'Your supervisor approved your placement — '
                'tap to start your internship',
            color: Colors.green,
            icon: Icons.check_circle_rounded,
            route: '/student/start-internship',
          );

        default:
          // active, completed, extended, etc. — no banner needed
          return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ============================================================================
// DATA CLASS
// ============================================================================

class _BannerData {
  final String status;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String route;

  const _BannerData({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.route,
  });
}

// ============================================================================
// STUDENT DASHBOARD
// ============================================================================

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedStudentTabProvider);
    final user = ref.watch(authStateProvider).value;
    final banner = ref.watch(placementStatusBannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIMS Student'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ref.read(selectedStudentTabProvider.notifier).state = 3;
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'S',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status Banner ──────────────────────────────────────────────
          // Only shown when the student needs to take action or is waiting.
          // Disappears automatically once internship is active.
          if (banner != null) _PlacementStatusBanner(data: banner),

          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: const [
                StudentOverviewPage(),
                LogbookPage(),
                MyInternshipPage(),
                StudentProfilePage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          ref.read(selectedStudentTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Logbook',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Internship',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PLACEMENT STATUS BANNER
// ============================================================================

class _PlacementStatusBanner extends StatelessWidget {
  final _BannerData data;

  const _PlacementStatusBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(data.route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: data.color.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // ── Status icon ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(width: 14),

            // ── Title + subtitle ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: data.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Chevron — signals tappability ────────────────────────────
            // Hidden for 'pending' since there's nothing to act on yet.
            if (data.status != 'pendingSupervisorReview')
              Icon(Icons.arrow_forward_ios_rounded,
                  color: data.color, size: 14),

            // ── Pulsing dot for pending — shows it's in progress ─────────
            if (data.status == 'pendingSupervisorReview')
              _PulsingDot(color: data.color),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PULSING DOT — visual cue that something is actively being processed
// ============================================================================

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}