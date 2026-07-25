import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final theme = Theme.of(context);

    // Dynamic destination items based on role-based security rules
    final List<_DrawerItemData> items = [];

    // Dashboard always visible
    items.add(_DrawerItemData(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ));

    if (AuthService.hasPermission('viewInventory')) {
      items.add(_DrawerItemData(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Inventory',
        route: '/inventory',
      ));
    }

    if (AuthService.hasPermission('viewSales')) {
      items.add(_DrawerItemData(
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
        label: 'Sales Log',
        route: '/sales',
      ));
    }

    if (AuthService.hasPermission('viewExpenses')) {
      items.add(_DrawerItemData(
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
        label: 'Expenses',
        route: '/expenses',
      ));
    }

    if (AuthService.hasPermission('viewTasks')) {
      items.add(_DrawerItemData(
        icon: Icons.task_alt,
        selectedIcon: Icons.task,
        label: 'Tasks',
        route: '/tasks',
      ));
    }

    if (AuthService.hasPermission('viewReports')) {
      items.add(_DrawerItemData(
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
        label: 'Business Reports',
        route: '/reports',
      ));
    }

    // AI Assistant always visible
    items.add(_DrawerItemData(
      icon: Icons.psychology_outlined,
      selectedIcon: Icons.psychology,
      label: 'SmartERP AI',
      route: '/ai-assistant',
    ));

    // Divider
    final int dividerIndex = items.length;

    // Activity Logs (Manager/Owner only)
    if (AuthService.hasPermission('viewActivityLogs')) {
      items.add(_DrawerItemData(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: 'Activity Logs',
        route: '/activity-logs',
      ));
    }

    // Notifications & Profile always visible
    items.add(_DrawerItemData(
      icon: Icons.notifications_none,
      selectedIcon: Icons.notifications,
      label: 'Notifications',
      route: '/notifications',
    ));

    items.add(_DrawerItemData(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'My Profile',
      route: '/profile',
    ));

    int selectedIdx = items.indexWhere((item) => item.route == currentRoute);
    if (selectedIdx == -1) selectedIdx = 0; // Default to Dashboard

    return NavigationDrawer(
      selectedIndex: selectedIdx,
      onDestinationSelected: (index) {
        final item = items[index];
        if (item.route != currentRoute) {
          Navigator.pushReplacementNamed(context, item.route);
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.person, size: 30, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Guest User',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.role.displayName ?? 'Employee',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.secondaryContainer),
                ),
                child: Row(
                  children: [
                    Icon(Icons.domain, size: 16, color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Business Code: ${user?.businessCode ?? user?.tenantId ?? "N/A"}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Render drawer items
        for (int i = 0; i < items.length; i++) ...[
          if (i == dividerIndex)
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, 8),
              child: Divider(),
            ),
          NavigationDrawerDestination(
            icon: Icon(items[i].icon),
            selectedIcon: Icon(items[i].selectedIcon),
            label: Text(items[i].label),
          ),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: OutlinedButton.icon(
            onPressed: () {
              AuthService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  _DrawerItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
