import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/controllers/auth_controller.dart';
import 'supervisor_overview_content.dart';
import 'supervisor_profile_screen.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SupervisorOverviewContent(),
    const SupervisorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Move the AppBar here so it's always present
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Supervisor Dashboard' : 'My Profile'),
        actions: [
          // Emergency Logout Button - This ensures you never get stuck!
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authControllerProvider).signOut(),
                tooltip: 'Logout',
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}