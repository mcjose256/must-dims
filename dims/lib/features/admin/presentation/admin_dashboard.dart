// lib/features/admin/presentation/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/admin/presentation/pages/overview_page.dart';
import 'package:dims/features/admin/presentation/pages/pending_approvals_page.dart';
import 'package:dims/features/admin/presentation/pages/users_management_page.dart';
import 'package:dims/features/admin/presentation/pages/supervisor_allocation_page.dart';

// Selected tab state provider
final selectedAdminTabProvider = StateProvider<int>((ref) => 0);

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedAdminTabProvider);
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    
    // Get admin user info
    final adminUser = authState.value;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // MUST Logo placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'DWMBIMS Admin',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Admin name (hide on small screens)
          if (MediaQuery.of(context).size.width > 600)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  adminUser?.displayName ?? adminUser?.email ?? 'Admin',
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation Rail (Desktop/Tablet)
          if (MediaQuery.of(context).size.width >= 640)
            NavigationRail(
              selectedIndex: selectedTab,
              onDestinationSelected: (index) {
                ref.read(selectedAdminTabProvider.notifier).state = index;
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.pending_actions_outlined),
                  selectedIcon: Icon(Icons.pending_actions),
                  label: Text('Approvals'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: Text('Allocation'),
                ),
              ],
            ),
          
          // Vertical divider
          if (MediaQuery.of(context).size.width >= 640)
            const VerticalDivider(thickness: 1, width: 1),
          
          // Main content area
          Expanded(
            child: _getSelectedPage(selectedTab),
          ),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: MediaQuery.of(context).size.width < 640
          ? NavigationBar(
              selectedIndex: selectedTab,
              onDestinationSelected: (index) {
                ref.read(selectedAdminTabProvider.notifier).state = index;
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pending_actions_outlined),
                  selectedIcon: Icon(Icons.pending_actions),
                  label: 'Approvals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Users',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Allocation',
                ),
              ],
            )
          : null,
    );
  }

  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return const OverviewPage();
      case 1:
        return const PendingApprovalsPage();
      case 2:
        return const UsersManagementPage();
      case 3:
        return const SupervisorAllocationPage();
      default:
        return const OverviewPage();
    }
  }
}