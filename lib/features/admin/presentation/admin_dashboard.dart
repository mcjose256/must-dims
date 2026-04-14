import 'package:dims/core/theme/must_theme.dart';
import 'package:dims/core/widgets/brand_app_bar_title.dart';
import 'package:dims/features/admin/controllers/admin_stats_controller.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/companies_management_page.dart';
import 'pages/overview_page.dart';
import 'pages/pending_approvals_page.dart';
import 'pages/pending_placements_page.dart';
import 'pages/success_stories_management_page.dart';
import 'pages/supervisor_allocation_page.dart';
import 'pages/users_management_page.dart';

final selectedAdminTabProvider = StateProvider<int>((ref) => 0);

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  late final ProviderSubscription<int> _tabSubscription;

  @override
  void initState() {
    super.initState();

    _tabSubscription = ref.listenManual<int>(selectedAdminTabProvider, (
      previous,
      next,
    ) {
      if (next == 0 && previous != 0) {
        _refreshOverview();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshOverview();
      }
    });
  }

  @override
  void dispose() {
    _tabSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedAdminTabProvider);
    final navItems = _adminNavItems;
    final currentItem = navItems[selectedTab];
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      backgroundColor: MustBrandColors.ivory,
      appBar: AppBar(
        toolbarHeight: isDesktop ? 84 : 76,
        automaticallyImplyLeading: !isDesktop,
        titleSpacing: isDesktop ? 28 : null,
        title: BrandAppBarTitle(
          title: currentItem.title,
          subtitle: currentItem.subtitle,
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: _AdminSidebar(
                selectedTab: selectedTab,
                onSelect: (index) {
                  ref.read(selectedAdminTabProvider.notifier).state = index;
                  Navigator.of(context).pop();
                },
              ),
            ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MustBrandColors.surfaceTint.withOpacity(0.58),
              MustBrandColors.ivory,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1100) {
                return Row(
                  children: [
                    const SizedBox(width: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: _AdminSidebar(
                        selectedTab: selectedTab,
                        onSelect: (index) {
                          ref.read(selectedAdminTabProvider.notifier).state = index;
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: _AdminPageViewport(selectedTab: selectedTab),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: _AdminPageViewport(selectedTab: selectedTab),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authControllerProvider).signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  void _refreshOverview() {
    ref.invalidate(adminStatsProvider);
    ref.invalidate(districtAllocationStatsProvider);
    ref.invalidate(studentPlacementReportProvider);
  }
}

class _AdminPageViewport extends StatelessWidget {
  const _AdminPageViewport({required this.selectedTab});

  final int selectedTab;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedTab,
      children: const [
        OverviewPage(),
        UsersManagementPage(),
        PendingApprovalsPage(),
        SupervisorAllocationPage(),
        CompaniesManagementPage(),
        SuccessStoriesManagementPage(),
        PendingPlacementsPage(),
      ],
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedTab,
    required this.onSelect,
  });

  final int selectedTab;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    return Container(
      width: isDesktop ? 308 : double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 32 : 0),
        border: Border.all(
          color: MustBrandColors.green.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: MustBrandColors.green.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(isDesktop ? 18 : 16, 16, isDesktop ? 18 : 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MustBrandColors.green,
                      MustBrandColors.greenLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MustBrandColors.gold,
                          width: 1.6,
                        ),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/must logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Panel',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MUST DIMS',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.82),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Workspace',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: _adminNavItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _adminNavItems[index];
                    return _SidebarNavTile(
                      item: item,
                      selected: selectedTab == index,
                      onTap: () => onSelect(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? MustBrandColors.green.withOpacity(0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : MustBrandColors.surfaceTint.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: selected
                      ? MustBrandColors.green
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? MustBrandColors.green
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.shortLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.hasAlert)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: MustBrandColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.title,
    required this.subtitle,
    required this.shortLabel,
    required this.icon,
    this.hasAlert = false,
  });

  final String title;
  final String subtitle;
  final String shortLabel;
  final IconData icon;
  final bool hasAlert;
}

const List<_AdminNavItem> _adminNavItems = [
  _AdminNavItem(
    title: 'Admin Dashboard',
    subtitle: 'MUST Administration',
    shortLabel: 'Overview',
    icon: Icons.dashboard_rounded,
  ),
  _AdminNavItem(
    title: 'User Management',
    subtitle: 'MUST Administration',
    shortLabel: 'Accounts',
    icon: Icons.people_alt_rounded,
  ),
  _AdminNavItem(
    title: 'Pending Approvals',
    subtitle: 'MUST Administration',
    shortLabel: 'Approval queue',
    icon: Icons.approval_rounded,
    hasAlert: true,
  ),
  _AdminNavItem(
    title: 'Supervisor Allocation',
    subtitle: 'MUST Administration',
    shortLabel: 'Assignments',
    icon: Icons.assignment_ind_rounded,
  ),
  _AdminNavItem(
    title: 'Companies',
    subtitle: 'MUST Administration',
    shortLabel: 'Partners',
    icon: Icons.business_rounded,
  ),
  _AdminNavItem(
    title: 'Success Stories',
    subtitle: 'MUST Administration',
    shortLabel: 'Landing content',
    icon: Icons.auto_stories_rounded,
  ),
  _AdminNavItem(
    title: 'Pending Placements',
    subtitle: 'MUST Administration',
    shortLabel: 'Placements',
    icon: Icons.pending_actions_rounded,
    hasAlert: true,
  ),
];
