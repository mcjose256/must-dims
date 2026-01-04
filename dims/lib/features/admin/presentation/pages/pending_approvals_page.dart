// lib/features/admin/presentation/pages/pending_approvals_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/admin/controllers/user_approval_controller.dart';
import 'package:dims/features/auth/data/models/user_model.dart';

class PendingApprovalsPage extends ConsumerStatefulWidget {
  const PendingApprovalsPage({super.key});

  @override
  ConsumerState<PendingApprovalsPage> createState() => _PendingApprovalsPageState();
}

class _PendingApprovalsPageState extends ConsumerState<PendingApprovalsPage> {
  UserRole? _filterRole;

  @override
  Widget build(BuildContext context) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Column(
        children: [
          // Header with filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Pending Approvals',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and approve user registrations',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter buttons
                if (!isSmallScreen)
                  SegmentedButton<UserRole?>(
                    segments: const [
                      ButtonSegment(
                        value: null,
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: UserRole.student,
                        label: Text('Students'),
                      ),
                      ButtonSegment(
                        value: UserRole.supervisor,
                        label: Text('Supervisors'),
                      ),
                    ],
                    selected: {_filterRole},
                    onSelectionChanged: (Set<UserRole?> newSelection) {
                      setState(() {
                        _filterRole = newSelection.first;
                      });
                    },
                  )
                else
                  // Dropdown for small screens
                  DropdownButton<UserRole?>(
                    value: _filterRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: UserRole.student, child: Text('Students')),
                      DropdownMenuItem(value: UserRole.supervisor, child: Text('Supervisors')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterRole = value);
                    },
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Expanded(
            child: pendingUsersAsync.when(
              data: (users) {
                // Apply filter
                final filteredUsers = _filterRole == null
                    ? users
                    : users.where((u) => u.role == _filterRole).toList();
                
                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending approvals',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All user registrations have been processed',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(pendingUsersProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _UserApprovalCard(user: filteredUsers[index]);
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
                      onPressed: () => ref.invalidate(pendingUsersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserApprovalCard extends ConsumerStatefulWidget {
  final UserModel user;

  const _UserApprovalCard({required this.user});

  @override
  ConsumerState<_UserApprovalCard> createState() => _UserApprovalCardState();
}

class _UserApprovalCardState extends ConsumerState<_UserApprovalCard> {
  bool _isProcessing = false;

  Future<void> _handleApproval(bool approve) async {
    setState(() => _isProcessing = true);

    try {
      await ref.read(userApprovalControllerProvider).approveUser(
            widget.user.uid,
            approve,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'User approved successfully'
                  : 'User registration rejected',
            ),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    widget.user.email[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.displayName ?? widget.user.email,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(widget.user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getRoleColor(widget.user.role),
                    ),
                  ),
                  child: Text(
                    widget.user.role.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(widget.user.role),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Registration date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Registered: ${_formatDate(widget.user.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (isSmallScreen)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : () => _handleApproval(true),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _handleApproval(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _handleApproval(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : () => _handleApproval(true),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Colors.blue;
      case UserRole.supervisor:
        return Colors.green;
      case UserRole.admin:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}