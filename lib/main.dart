import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/erp_provider.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/tasks_list_screen.dart';
import 'screens/task_assignment_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/activity_logs_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ErpProvider()),
      ],
      child: const SmartERPApp(),
    ),
  );
}

class SmartERPApp extends StatelessWidget {
  const SmartERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Read theme mode from the ErpProvider
    final themeMode = Provider.of<ErpProvider>(context).themeMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartERP Mobile',
      
      themeMode: themeMode,
      
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A), // Premium Dark Slate Seed
          brightness: Brightness.light,
          primary: const Color(0xFF1E40AF), // Deep Blue Accent
          secondary: const Color(0xFF0D9488), // Teal Accent
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          brightness: Brightness.dark,
          primary: const Color(0xFF3B82F6), // Vibrant Blue Accent
          secondary: const Color(0xFF14B8A6), // Vibrant Teal Accent
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      
      initialRoute: '/login',
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/sales': (context) => const SalesScreen(),
        '/expenses': (context) => const ExpensesScreen(),
        '/tasks': (context) => const TasksListScreen(),
        '/assign-task': (context) => const TaskAssignmentScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/ai-assistant': (context) => const AiAssistantScreen(),
        '/activity-logs': (context) => const ActivityLogsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
