import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/erp_provider.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erp = Provider.of<ErpProvider>(context);
    final user = AuthService.currentUser;

    // Financial calculations
    final double totalSales = erp.sales.fold(0.0, (sum, item) => sum + item.totalAmount);
    final double totalExpenses = erp.expenses.fold(0.0, (sum, item) => sum + item.amount);
    final double netProfit = totalSales - totalExpenses;

    // Low stock warnings
    final lowStockItems = erp.inventory.where((item) => item.stockLevel <= item.lowStockLevel).toList();

    // Overdue tasks
    final overdueTasks = erp.tasks.where((task) => task.isOverdue).toList();

    // Quick Actions grid based on permissions
    final List<_QuickActionData> quickActions = [];
    if (AuthService.hasPermission('manageSales')) {
      quickActions.add(_QuickActionData('Record Sale', Icons.add_shopping_cart, Colors.green, '/sales'));
    }
    if (AuthService.hasPermission('manageExpenses')) {
      quickActions.add(_QuickActionData('Record Expense', Icons.remove_circle_outline, Colors.red, '/expenses'));
    }
    if (AuthService.hasPermission('manageTasks')) {
      quickActions.add(_QuickActionData('New Task', Icons.add_task, Colors.orange, '/assign-task'));
    }
    // AI Assistant always accessible
    quickActions.add(_QuickActionData('Ask AI Assistant', Icons.psychology, Colors.purple, '/ai-assistant'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartERP AI', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none),
                if (erp.unreadNotifications.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '${erp.unreadNotifications.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.pushNamed(context, '/ai-assistant'),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: RefreshIndicator(
        onRefresh: () async {
          // Fake refresh delay
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Molo, ${user?.name ?? "User"} 👋',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${user?.role.displayName} at ${user?.tenantId == "tenant_douala_001" ? "Superette de l\'Avenir" : user?.tenantId == "tenant_yaounde_002" ? "Boutique Bastos" : "Your Business"}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Financial Stats Cards Carousel/Horizontal List
              SizedBox(
                height: 124,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _statCard(
                      'Revenue',
                      'FCFA ${totalSales.toInt()}',
                      Icons.trending_up,
                      Colors.green,
                      theme,
                    ),
                    _statCard(
                      'Expenses',
                      'FCFA ${totalExpenses.toInt()}',
                      Icons.trending_down,
                      Colors.red,
                      theme,
                    ),
                    _statCard(
                      'Net Profit',
                      'FCFA ${netProfit.toInt()}',
                      netProfit >= 0 ? Icons.account_balance_wallet : Icons.money_off,
                      netProfit >= 0 ? Colors.blue : Colors.deepOrange,
                      theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Visual Chart (Sales vs Expenses)
              if (AuthService.hasPermission('viewReports')) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Financial Performance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: erp.sales.isEmpty && erp.expenses.isEmpty
                      ? const Center(child: Text('No transaction data to display in chart.'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (totalSales > totalExpenses ? totalSales : totalExpenses) * 1.2,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 11);
                                    Widget text;
                                    switch (value.toInt()) {
                                      case 0:
                                        text = const Text('Sales', style: style);
                                        break;
                                      case 1:
                                        text = const Text('Expenses', style: style);
                                        break;
                                      default:
                                        text = const Text('', style: style);
                                        break;
                                    }
                                    return SideTitleWidget(meta: meta, child: text);
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: totalSales,
                                    color: Colors.green,
                                    width: 32,
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: totalExpenses,
                                    color: Colors.red,
                                    width: 32,
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],

              // Warning Widget: Low Stock and Overdue Tasks
              if (lowStockItems.isNotEmpty || overdueTasks.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Operational Alerts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                ),
                const SizedBox(height: 8),
                
                // Render Low Stock alerts
                for (var item in lowStockItems.take(2))
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Running low: Only ${item.stockLevel} ${item.unit} left (threshold: ${item.lowStockLevel})'),
                      trailing: TextButton(
                        onPressed: () {
                          erp.reorderProduct(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Reordered 50 units of ${item.name}'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        child: const Text('Reorder'),
                      ),
                    ),
                  ),

                // Render Overdue Tasks alert
                for (var task in overdueTasks.take(1))
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: const Color(0xFFFEF3C7).withValues(alpha: 0.2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber.shade300),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.alarm, color: Colors.amber),
                      title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('OVERDUE - Assigned to: ${task.assignedToName}'),
                      trailing: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/tasks'),
                        child: const Text('View'),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // Quick Actions Grid
              if (quickActions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: quickActions.length,
                  itemBuilder: (context, index) {
                    final action = quickActions[index];
                    return InkWell(
                      onTap: () => Navigator.pushNamed(context, action.route),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              action.color.withValues(alpha: 0.15),
                              action.color.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: action.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: action.color.withValues(alpha: 0.2),
                              child: Icon(action.icon, color: action.color, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                action.label,
                                style: TextStyle(
                                  color: action.color.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final MaterialColor color;
  final String route;

  _QuickActionData(this.label, this.icon, this.color, this.route);
}

// Extension to safely support container colors on different versions
extension ColorContainerExt on Color {
  static Color? tryContainer(BuildContext context) {
    return Theme.of(context).colorScheme.primaryContainer;
  }
}

extension ColorExt on Colors {
  static Color get amberContainer => const Color(0xFFFEF3C7);
}
