// lib/features/student/presentation/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/student/presentation/pages/student_overview_page.dart';
import 'package:dims/features/student/presentation/pages/logbook_page.dart';
import 'package:dims/features/student/presentation/pages/my_internship_page.dart';
import 'package:dims/features/student/presentation/pages/student_profile_page.dart';

// Selected tab state
final selectedStudentTabProvider = StateProvider<int>((ref) => 0);

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedStudentTabProvider);
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    // Get student from async value
    final student = authState.whenOrNull(
      data: (user) => user,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'DIMS Student',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Notifications icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
            tooltip: 'Notifications',
          ),
          // Profile menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                (student?.email ?? 'S')[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  ref.read(selectedStudentTabProvider.notifier).state = 3;
                  break;
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  ref.read(authControllerProvider).signOut();
                  break;
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedTab,
                  onDestinationSelected: (index) {
                    ref.read(selectedStudentTabProvider.notifier).state = index;
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.book_outlined),
                      selectedIcon: Icon(Icons.book),
                      label: Text('Logbook'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.business_outlined),
                      selectedIcon: Icon(Icons.business),
                      label: Text('Internship'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _getSelectedPage(selectedTab)),
              ],
            )
          : _getSelectedPage(selectedTab),
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
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
            )
          : null,
    );
  }

  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return const StudentOverviewPage();
      case 1:
        return const LogbookPage();
      case 2:
        return const MyInternshipPage();
      case 3:
        return const StudentProfilePage();
      default:
        return const StudentOverviewPage();
    }
  }
}