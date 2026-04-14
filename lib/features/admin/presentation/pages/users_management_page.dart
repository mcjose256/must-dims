// lib/features/admin/presentation/pages/users_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/admin/controllers/users_management_controller.dart';
import 'package:dims/features/auth/data/models/user_model.dart';

const List<String> _studentLevelOptions = [
  'Year One',
  'Year Two',
  'Year Three',
  'Year Four',
];

const List<String> _studentProgramOptions = [
  'Bachelor of Information Technology',
  'Bachelor of Computer Science',
  'Bachelor of Software Engineering',
];

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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _UsersTableCard(
                users: filteredUsers,
                role: role,
              ),
            ],
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

class _UsersTableCard extends StatelessWidget {
  const _UsersTableCard({
    required this.users,
    required this.role,
  });

  final List<UserModel> users;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleLabel = role == UserRole.student ? 'Students' : 'Supervisors';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$roleLabel Table',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${users.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowHeight: 50,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 72,
                    headingRowColor: WidgetStatePropertyAll(
                      theme.colorScheme.primaryContainer.withOpacity(0.35),
                    ),
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users
                        .map(
                          (user) => DataRow(
                            cells: [
                              DataCell(_UserIdentityCell(user: user)),
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 220,
                                    maxWidth: 280,
                                  ),
                                  child: Text(
                                    user.email,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    (user.phoneNumber == null ||
                                            user.phoneNumber!.trim().isEmpty)
                                        ? 'Not set'
                                        : user.phoneNumber!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: (user.phoneNumber == null ||
                                              user.phoneNumber!.trim().isEmpty)
                                          ? theme.colorScheme.onSurfaceVariant
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                _UserActionsButton(user: user),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserIdentityCell extends StatelessWidget {
  const _UserIdentityCell({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? Text(
                  user.email[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 180,
            maxWidth: 240,
          ),
          child: Text(
            user.displayName ?? user.email,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserActionsButton extends ConsumerWidget {
  const _UserActionsButton({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'User actions',
      onSelected: (value) async {
        switch (value) {
          case 'view':
            _showUserSummaryDialog(context, user);
            break;
          case 'edit':
            await _showEditUserDialog(context, ref, user);
            break;
          case 'deactivate':
            await _confirmDeactivate(context, ref, user);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'view',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.visibility),
            title: Text('View Profile'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit),
            title: Text('Edit User'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'deactivate',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.block, color: Colors.red),
            title: Text('Deactivate User'),
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.more_vert),
      ),
    );
  }

  void _showUserSummaryDialog(BuildContext context, UserModel user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileLine(label: 'Name', value: user.displayName ?? 'Not set'),
            const SizedBox(height: 10),
            _ProfileLine(label: 'Email', value: user.email),
            const SizedBox(height: 10),
            _ProfileLine(
              label: 'Phone',
              value: (user.phoneNumber == null || user.phoneNumber!.trim().isEmpty)
                  ? 'Not set'
                  : user.phoneNumber!,
            ),
            const SizedBox(height: 10),
            _ProfileLine(
              label: 'Role',
              value: user.role.name[0].toUpperCase() + user.role.name.substring(1),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate user?'),
        content: Text(
          'This will disable ${user.displayName ?? user.email} from active access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(usersManagementControllerProvider)
          .deactivateUser(user.uid);

      ref.invalidate(approvedUsersProvider(user.role));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName ?? user.email} deactivated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deactivate user: $e')),
        );
      }
    }
  }

  Future<void> _showEditUserDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final controller = ref.read(usersManagementControllerProvider);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: controller.getRoleDetails(user),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 96,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Unable to load user'),
                content: Text(snapshot.error.toString()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            return _EditUserDialog(
              user: user,
              roleDetails: snapshot.data ?? const <String, dynamic>{},
            );
          },
        );
      },
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  final UserModel user;
  final Map<String, dynamic> roleDetails;

  const _EditUserDialog({
    required this.user,
    required this.roleDetails,
  });

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _registrationController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _departmentController;

  String? _selectedProgram;
  String? _selectedLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.displayName ?? widget.roleDetails['fullName'] ?? '',
    );
    _phoneController = TextEditingController(
      text:
          widget.user.phoneNumber ?? widget.roleDetails['phoneNumber'] ?? '',
    );
    _registrationController = TextEditingController(
      text: widget.roleDetails['registrationNumber'] ?? '',
    );
    _academicYearController = TextEditingController(
      text: '${widget.roleDetails['academicYear'] ?? ''}',
    );
    _departmentController = TextEditingController(
      text: widget.roleDetails['department'] ?? '',
    );
    final storedProgram = widget.roleDetails['program'] as String?;
    final storedLevel = widget.roleDetails['currentLevel'] as String?;
    _selectedProgram = _studentProgramOptions.contains(storedProgram)
        ? storedProgram
        : null;
    _selectedLevel = _studentLevelOptions.contains(storedLevel)
        ? storedLevel
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _registrationController.dispose();
    _academicYearController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.user.role == UserRole.student;
    final title = 'Edit ${widget.user.role.name}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: widget.user.email,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        if (isStudent) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _registrationController,
                            decoration: const InputDecoration(
                              labelText: 'Registration number',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedProgram,
                            isExpanded: true,
                            menuMaxHeight: 320,
                            decoration: const InputDecoration(
                              labelText: 'Program',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            items: _studentProgramOptions
                                .map(
                                  (program) => DropdownMenuItem<String>(
                                    value: program,
                                    child: Text(
                                      program,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedProgram = value),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _academicYearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Academic year',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedLevel,
                            isExpanded: true,
                            menuMaxHeight: 280,
                            decoration: const InputDecoration(
                              labelText: 'Current level',
                              prefixIcon: Icon(Icons.grade_outlined),
                            ),
                            items: _studentLevelOptions
                                .map(
                                  (level) => DropdownMenuItem<String>(
                                    value: level,
                                    child: Text(level),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedLevel = value),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _departmentController,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              prefixIcon: Icon(Icons.account_tree_outlined),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            child: Text(_isSaving ? 'Saving...' : 'Save changes'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed:
                                _isSaving ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          child: Text(_isSaving ? 'Saving...' : 'Save changes'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(usersManagementControllerProvider).updateManagedUserProfile(
            user: widget.user,
            displayName: _nameController.text,
            phoneNumber: _phoneController.text,
            registrationNumber: _registrationController.text,
            program: _selectedProgram,
            academicYear: int.tryParse(_academicYearController.text.trim()),
            currentLevel: _selectedLevel,
            department: _departmentController.text,
          );

      ref.invalidate(approvedUsersProvider(widget.user.role));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.user.displayName ?? widget.user.email} updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
