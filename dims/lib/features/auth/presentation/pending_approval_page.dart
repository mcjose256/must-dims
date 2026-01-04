import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';

/// Screen shown to users whose accounts are not yet approved by admin
class PendingApprovalPage extends ConsumerWidget {
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pending_outlined,
                    size: 80,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'Account Pending Approval',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Your account has been created successfully and is currently under review by the system administrator.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Info Cards
                _InfoCard(
                  icon: Icons.check_circle_outline,
                  title: 'What happens next?',
                  description: 'An administrator will review your registration details and approve your account.',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                
                _InfoCard(
                  icon: Icons.notifications_outlined,
                  title: 'Stay tuned',
                  description: 'You will receive an email notification once your account is approved.',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                
                _InfoCard(
                  icon: Icons.access_time,
                  title: 'Review time',
                  description: 'Account reviews typically take 24-48 hours during working days.',
                  colorScheme: colorScheme,
                ),
                
                const SizedBox(height: 40),
                
                // Actions
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Need help? Contact support@must.ac.ug',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}