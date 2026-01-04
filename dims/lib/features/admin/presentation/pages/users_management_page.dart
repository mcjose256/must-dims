// lib/features/admin/presentation/pages/users_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/admin/controllers/users_management_controller.dart';
import 'package:dims/features/auth/data/models/user_model.dart';

class UsersManagementPage extends ConsumerStatefulWidget {
  const UsersManagementPage({super.key});

  @override
  ConsumerState<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends ConsumerState<UsersManagementPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Users Management',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View and manage all system users',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ],
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Students'),
              Tab(text: 'Supervisors'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UsersListView(
                  role: UserRole.student,
                  searchQuery: _searchQuery,
                ),
                _UsersListView(
                  role: UserRole.supervisor,
                  searchQuery: _searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersListView extends ConsumerWidget {
  final UserRole role;
  final String searchQuery;

  const _UsersListView({
    required this.role,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(approvedUsersProvider(role));
    final theme = Theme.of(context);

    return usersAsync.when(
      data: (users) {
        // Filter by search query
        final filteredUsers = searchQuery.isEmpty
            ? users
            : users.where((user) {
                final email = user.email.toLowerCase();
                final name = (user.displayName ?? '').toLowerCase();
                return email.contains(searchQuery) || name.contains(searchQuery);
              }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isEmpty
                      ? 'No ${role.name}s found'
                      : 'No results for "$searchQuery"',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(approvedUsersProvider(role));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _UserCard(user: filteredUsers[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(approvedUsersProvider(role)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: user.photoUrl != null 
              ? NetworkImage(user.photoUrl!) 
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.email[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        title: Text(
          user.displayName ?? user.email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email),
            if (user.phoneNumber != null) ...[
              const SizedBox(height: 2),
              Text(user.phoneNumber!),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Show options menu
            _showUserOptions(context, user);
          },
        ),
      ),
    );
  }

  void _showUserOptions(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to user profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit User'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit user
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Deactivate User'),
              onTap: () {
                Navigator.pop(context);
                // Show confirmation dialog
              },
            ),
          ],
        ),
      ),
    );
  }
}