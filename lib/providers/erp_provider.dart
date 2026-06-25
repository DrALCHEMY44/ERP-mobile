import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/erp_task.dart';
import '../models/activity_log.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class ErpProvider with ChangeNotifier {
  final List<InventoryItem> _products = [];
  final List<Sale> _sales = [];
  final List<Expense> _expenses = [];
  final List<ErpTask> _tasks = [];
  final List<ActivityLog> _activityLogs = [];
  final List<NotificationModel> _notifications = [];
  
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.light;

  ErpProvider() {
    _seedMockData();
  }

  // Getters
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;

  String get _currentTenantId => AuthService.currentUser?.tenantId ?? '';
  String get _currentUserId => AuthService.currentUser?.id ?? '';
  String get _currentUserName => AuthService.currentUser?.name ?? 'System';
  String get _currentUserRole => AuthService.currentUser?.role.displayName ?? 'System';

  // Tenant Isolated Collections
  List<InventoryItem> get inventory => _products.where((p) => p.tenantId == _currentTenantId).toList();
  List<Sale> get sales => _sales.where((s) => s.tenantId == _currentTenantId).toList();
  List<Expense> get expenses => _expenses.where((e) => e.tenantId == _currentTenantId).toList();
  List<ErpTask> get tasks => _tasks.where((t) => t.tenantId == _currentTenantId).toList();
  List<ActivityLog> get activityLogs => _activityLogs.where((a) => a.tenantId == _currentTenantId).toList();
  List<NotificationModel> get notifications => _notifications.where((n) => n.tenantId == _currentTenantId).toList();
  
  List<NotificationModel> get unreadNotifications => notifications.where((n) => !n.isRead).toList();

  // Theme Toggler
  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Logging & Notification Helpers
  void logActivity(String actionType, String module, String description) {
    _activityLogs.insert(0, ActivityLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      tenantId: _currentTenantId,
      businessId: AuthService.currentUser?.businessId ?? 'biz_general',
      userId: _currentUserId,
      userName: _currentUserName,
      userRole: _currentUserRole,
      actionType: actionType,
      module: module,
      description: description,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void triggerNotification(String title, String message, NotificationType type) {
    _notifications.insert(0, NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      tenantId: _currentTenantId,
      businessId: AuthService.currentUser?.businessId ?? 'biz_general',
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  // CRUD Business Operations

  // 1. Record Sale (enforces role rules and decreases inventory)
  Future<bool> recordSale(String productId, int quantity) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!AuthService.hasPermission('manageSales')) {
        logActivity('FAILED_SALE', 'Sales', 'Unauthorized attempt to record sale.');
        return false;
      }

      final productIndex = _products.indexWhere((p) => p.id == productId && p.tenantId == _currentTenantId);
      if (productIndex == -1) return false;

      final product = _products[productIndex];
      if (product.stockLevel < quantity) {
        logActivity('FAILED_SALE', 'Sales', 'Failed to sell ${product.name}: Insufficient stock.');
        triggerNotification('Insufficient Stock', 'Cannot complete sale of ${product.name}: requested $quantity, available ${product.stockLevel}.', NotificationType.error);
        return false;
      }

      // Decrement stock
      final updatedProduct = product.copyWith(stockLevel: product.stockLevel - quantity);
      _products[productIndex] = updatedProduct;

      final double totalAmount = product.price * quantity;

      // Append sale
      _sales.insert(0, Sale(
        id: 'SALE-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        tenantId: _currentTenantId,
        businessId: AuthService.currentUser?.businessId ?? 'biz_general',
        itemName: product.name,
        quantity: quantity,
        totalAmount: totalAmount,
        date: DateTime.now(),
        recordedBy: _currentUserName,
      ));

      logActivity('RECORD_SALE', 'Sales', 'Recorded sale of $quantity ${product.name} (FCFA ${totalAmount.toInt()})');

      // Check low stock triggers
      if (updatedProduct.stockLevel <= updatedProduct.lowStockLevel) {
        triggerNotification(
          'Low Stock Warning',
          '${product.name} is running low on stock! Only ${updatedProduct.stockLevel} ${updatedProduct.unit} left.',
          NotificationType.warning,
        );
      }

      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Record Expense (enforces role rules)
  Future<bool> recordExpense(String category, String description, double amount) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 400));

      if (!AuthService.hasPermission('manageExpenses')) {
        logActivity('FAILED_EXPENSE', 'Expenses', 'Unauthorized attempt to record expense.');
        return false;
      }

      _expenses.insert(0, Expense(
        id: 'EXP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        tenantId: _currentTenantId,
        businessId: AuthService.currentUser?.businessId ?? 'biz_general',
        category: category,
        description: description,
        amount: amount,
        date: DateTime.now(),
        recordedBy: _currentUserName,
      ));

      logActivity('RECORD_EXPENSE', 'Expenses', 'Recorded expense for $category: $description (FCFA ${amount.toInt()})');
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Add Product (enforces role rules)
  Future<bool> addProduct(String name, String category, int stockLevel, String unit, double costPrice, double price, int lowStockLevel) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!AuthService.hasPermission('manageInventory')) {
        logActivity('FAILED_INVENTORY', 'Inventory', 'Unauthorized attempt to add inventory.');
        return false;
      }

      final newProduct = InventoryItem(
        id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
        tenantId: _currentTenantId,
        businessId: AuthService.currentUser?.businessId ?? 'biz_general',
        name: name,
        category: category,
        stockLevel: stockLevel,
        unit: unit,
        costPrice: costPrice,
        price: price,
        lowStockLevel: lowStockLevel,
      );

      _products.add(newProduct);
      logActivity('ADD_PRODUCT', 'Inventory', 'Added product "$name" to inventory.');

      if (stockLevel <= lowStockLevel) {
        triggerNotification('Low Stock Warning', '$name added with low stock level ($stockLevel $unit remaining).', NotificationType.warning);
      }

      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Assign Task (enforces role rules)
  Future<bool> assignTask(String title, String description, String assignedToId, String assignedToName, TaskPriority priority, DateTime dueDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 400));

      if (!AuthService.hasPermission('manageTasks')) {
        logActivity('FAILED_TASK', 'Tasks', 'Unauthorized attempt to assign task.');
        return false;
      }

      final newTask = ErpTask(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        tenantId: _currentTenantId,
        businessId: AuthService.currentUser?.businessId ?? 'biz_general',
        title: title,
        description: description,
        assignedToId: assignedToId,
        assignedToName: assignedToName,
        assignedBy: _currentUserName,
        priority: priority,
        status: TaskStatus.pending,
        progress: 0,
        dueDate: dueDate,
      );

      _tasks.insert(0, newTask);
      logActivity('ASSIGN_TASK', 'Tasks', 'Assigned task "$title" to $assignedToName');
      
      // Simulating a notification sent to that employee
      triggerNotification(
        'New Task Assigned',
        'You have been assigned the task "$title" by $_currentUserName. Due date: ${dueDate.toString().split(' ')[0]}.',
        NotificationType.info,
      );

      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 5. Update Task Progress (enforces employee assignment rules)
  Future<bool> updateTaskProgress(String taskId, int progress) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final taskIndex = _tasks.indexWhere((t) => t.id == taskId && t.tenantId == _currentTenantId);
      if (taskIndex == -1) return false;

      final task = _tasks[taskIndex];

      // Security rule: Staff can only update progress of tasks assigned to them
      if (AuthService.currentUser?.role == UserRole.staff && task.assignedToId != _currentUserId) {
        logActivity('FAILED_TASK_UPDATE', 'Tasks', 'Unauthorized attempt by Staff to edit task "${task.title}".');
        return false;
      }

      // Check overall task management permission if not the assignee
      if (AuthService.currentUser?.role != UserRole.staff && !AuthService.hasPermission('manageTasks')) {
        logActivity('FAILED_TASK_UPDATE', 'Tasks', 'Unauthorized role attempted task update.');
        return false;
      }

      TaskStatus status = TaskStatus.ongoing;
      if (progress >= 100) {
        status = TaskStatus.completed;
      } else if (progress == 0) {
        status = TaskStatus.pending;
      }

      // If it is past due date, and not completed, set as overdue
      if (task.dueDate.isBefore(DateTime.now()) && status != TaskStatus.completed) {
        status = TaskStatus.overdue;
      }

      _tasks[taskIndex] = task.copyWith(
        progress: progress,
        status: status,
      );

      logActivity('UPDATE_TASK', 'Tasks', 'Updated task "${task.title}" progress to $progress% (${status.displayName})');

      if (status == TaskStatus.completed) {
        triggerNotification('Task Completed', 'Task "${task.title}" has been marked completed by $_currentUserName.', NotificationType.success);
      }

      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 6. Reorder Low-Stock Product
  Future<bool> reorderProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final productIndex = _products.indexWhere((p) => p.id == productId && p.tenantId == _currentTenantId);
      if (productIndex == -1) return false;

      final product = _products[productIndex];
      
      // Add 50 units
      final updatedProduct = product.copyWith(stockLevel: product.stockLevel + 50);
      _products[productIndex] = updatedProduct;

      logActivity('REORDER_PRODUCT', 'Inventory', 'Ordered 50 units of "${product.name}". Stock updated.');
      triggerNotification('Reorder Success', 'Stock for ${product.name} replenished by 50 units.', NotificationType.success);
      
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 7. Mark Notifications as Read
  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].tenantId == _currentTenantId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    logActivity('READ_NOTIFICATIONS', 'Notifications', 'Marked all notifications as read.');
    notifyListeners();
  }

  // 8. Seeding a new business tenant
  void seedNewTenant(String tenantId, String businessName, String sector) {
    // Add default products
    if (sector.toLowerCase() == 'retail') {
      _products.add(InventoryItem(
        id: 'prod_${tenantId}_1',
        tenantId: tenantId,
        businessId: 'biz_${tenantId}',
        name: 'Standard Bread loaf',
        category: 'Food',
        stockLevel: 40,
        unit: 'Loaves',
        costPrice: 350,
        price: 500,
        lowStockLevel: 10,
      ));
      _products.add(InventoryItem(
        id: 'prod_${tenantId}_2',
        tenantId: tenantId,
        businessId: 'biz_${tenantId}',
        name: 'Mineral Water 1.5L',
        category: 'Beverages',
        stockLevel: 6,
        unit: 'Bottles',
        costPrice: 250,
        price: 400,
        lowStockLevel: 12,
      ));
    } else {
      _products.add(InventoryItem(
        id: 'prod_${tenantId}_1',
        tenantId: tenantId,
        businessId: 'biz_${tenantId}',
        name: 'Consulting Service Hour',
        category: 'Services',
        stockLevel: 100,
        unit: 'Hours',
        costPrice: 5000,
        price: 15000,
        lowStockLevel: 5,
      ));
    }

    // Add default tasks
    _tasks.add(ErpTask(
      id: 'task_${tenantId}_1',
      tenantId: tenantId,
      businessId: 'biz_${tenantId}',
      title: 'Complete Business Profile setup',
      description: 'Fill in tax ID, logo, and address details in the settings panel.',
      assignedToId: _currentUserId.isEmpty ? 'user_${tenantId}_owner' : _currentUserId,
      assignedToName: _currentUserName,
      assignedBy: 'System',
      priority: TaskPriority.medium,
      status: TaskStatus.pending,
      progress: 0,
      dueDate: DateTime.now().add(const Duration(days: 7)),
    ));

    // Welcome notification
    _notifications.add(NotificationModel(
      id: 'notif_${tenantId}_welcome',
      tenantId: tenantId,
      businessId: 'biz_${tenantId}',
      title: 'Welcome to SmartERP AI',
      message: 'Business "$businessName" successfully registered in tenant $tenantId. Start by adding inventory or recording sales.',
      type: NotificationType.success,
      createdAt: DateTime.now(),
    ));

    logActivity('REGISTER_BUSINESS', 'Auth', 'Registered business "$businessName" for Tenant "$tenantId".');
    notifyListeners();
  }

  // Cameroon context-aware AI Engine
  Future<String> askAi(String query) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final double totalSales = sales.fold(0.0, (sum, item) => sum + item.totalAmount);
      final double totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.amount);
      final double profit = totalSales - totalExpenses;
      final int lowStockCount = inventory.where((p) => p.stockLevel <= p.lowStockLevel).length;
      final int overdueTasks = tasks.where((t) => t.isOverdue).length;

      final normalizedQuery = query.toLowerCase();
      String reply = '';

      if (normalizedQuery.contains('sales') || normalizedQuery.contains('revenue') || normalizedQuery.contains('sales total')) {
        reply = 'Your total sales revenue is currently **FCFA ${totalSales.toInt()}** from **${sales.length} transactions**.';
        if (sales.isNotEmpty) {
          final topProduct = sales.fold<Map<String, int>>({}, (map, sale) {
            map[sale.itemName] = (map[sale.itemName] ?? 0) + sale.quantity;
            return map;
          }).entries.reduce((a, b) => a.value > b.value ? a : b).key;
          reply += '\nYour top-selling product by quantity is **$topProduct**.';
        }
      } else if (normalizedQuery.contains('expense') || normalizedQuery.contains('spend') || normalizedQuery.contains('cost')) {
        reply = 'Your total logged operational expenses are **FCFA ${totalExpenses.toInt()}** from **${expenses.length} records**.';
        if (expenses.isNotEmpty) {
          final topCategory = expenses.fold<Map<String, double>>({}, (map, exp) {
            map[exp.category] = (map[exp.category] ?? 0.0) + exp.amount;
            return map;
          }).entries.reduce((a, b) => a.value > b.value ? a : b).key;
          reply += '\nYour largest spending category is **$topCategory**.';
        }
      } else if (normalizedQuery.contains('profit') || normalizedQuery.contains('health') || normalizedQuery.contains('financial') || normalizedQuery.contains('performance')) {
        reply = '### 📊 Financial Health Check\n\n'
            '• **Total Revenue**: FCFA ${totalSales.toInt()}\n'
            '• **Total Expenses**: FCFA ${totalExpenses.toInt()}\n'
            '• **Net Profit**: FCFA ${profit.toInt()}\n\n'
            'Your business is operating at a **${profit >= 0 ? "PROFIT" : "LOSS"}**. ';
        if (profit < 0) {
          reply += 'I suggest reviewing your utilities or transport costs to optimize cash flow.';
        } else {
          reply += 'Keep up the good work! Maintain stock levels to support continuing sales.';
        }
      } else if (normalizedQuery.contains('stock') || normalizedQuery.contains('inventory') || normalizedQuery.contains('low stock')) {
        if (lowStockCount > 0) {
          final lowItems = inventory.where((p) => p.stockLevel <= p.lowStockLevel).map((p) => '• ${p.name} (Stock: ${p.stockLevel} ${p.unit}, threshold: ${p.lowStockLevel})').join('\n');
          reply = '⚠️ You have **$lowStockCount product(s)** running below their stock thresholds:\n\n$lowItems\n\nWould you like me to trigger auto-reorders from your registered suppliers?';
        } else {
          reply = '✅ All inventory items are currently healthy. There are no products below low stock levels.';
        }
      } else if (normalizedQuery.contains('task') || normalizedQuery.contains('due') || normalizedQuery.contains('overdue')) {
        if (tasks.isNotEmpty) {
          reply = 'You have **${tasks.length} total tasks** in your list. \n'
              '• Overdue: **$overdueTasks**\n'
              '• Completed: **${tasks.where((t) => t.status == TaskStatus.completed).length}**\n\n';
          final pendingTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();
          if (pendingTasks.isNotEmpty) {
            reply += 'Next upcoming task: **"${pendingTasks.first.title}"** assigned to **${pendingTasks.first.assignedToName}** (Due: ${pendingTasks.first.dueDate.toString().split(' ')[0]}).';
          }
        } else {
          reply = 'There are no active tasks assigned in this business tenant.';
        }
      } else if (normalizedQuery.contains('vat') || normalizedQuery.contains('tax') || normalizedQuery.contains('impot')) {
        reply = '📋 **Cameroon Tax Guidelines (Standard VAT)**:\n\n'
            '• The standard **Value Added Tax (VAT)** rate in Cameroon is **19.25%** (composed of a 17.5% principal tax plus a 10% Additional Council Tax / Centimes Additionnels Communaux).\n'
            '• Businesses registered under the "Régime Réel" or "Régime Simplifié" must charge VAT on taxable supplies and declare it monthly by the 15th day of the subsequent month.';
      } else if (normalizedQuery.contains('ohada') || normalizedQuery.contains('syscohada') || normalizedQuery.contains('accounting standard')) {
        reply = '📚 **OHADA Accounting Compliance**:\n\n'
            '• Cameroon is a member state of **OHADA** and implements the **SYSCOHADA** (Système Comptable OHADA) accounting framework.\n'
            '• SMEs are required to keep standard books: the **Livre-Journal** (General Journal), the **Grand-Livre** (General Ledger), and the **Livre-d\'Inventaire** (Inventory Record).\n'
            '• SmartERP helps you remain compliant by automatically logging sales/expenses into structured registers and isolating transaction logs by Tenant.';
      } else {
        reply = 'Hello! I am your SmartERP AI assistant. Here is a summary of your tenant\'s metrics:\n\n'
            '• **Revenue**: FCFA ${totalSales.toInt()}\n'
            '• **Expenses**: FCFA ${totalExpenses.toInt()}\n'
            '• **Low Stock Items**: $lowStockCount\n'
            '• **Overdue Tasks**: $overdueTasks\n\n'
            'Ask me specific questions like: *"Which items are running low?"*, *"What is my revenue?"*, *"Explain Cameroon VAT"* or *"What is OHADA compliance?"*.';
      }

      // Log AI Query
      logActivity('AI_ASSISTANT', 'AI', 'Asked AI: "$query"');
      return reply;
    } catch (e) {
      return 'Sorry, I encountered an error analyzing your business data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Internal Seeding
  void _seedMockData() {
    // 1. Seed Products for tenant_douala_001
    _products.add(InventoryItem(
      id: 'prod1',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      name: 'Riz Long Grain 5kg',
      category: 'Food',
      stockLevel: 15,
      unit: 'Bags',
      costPrice: 4500,
      price: 5500,
      lowStockLevel: 20,
    ));
    _products.add(InventoryItem(
      id: 'prod2',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      name: 'Savon Azur 400g',
      category: 'Cleaning',
      stockLevel: 120,
      unit: 'Pieces',
      costPrice: 400,
      price: 550,
      lowStockLevel: 50,
    ));
    _products.add(InventoryItem(
      id: 'prod3',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      name: 'Guinness Stout 33cl',
      category: 'Beverages',
      stockLevel: 8,
      unit: 'Bottles',
      costPrice: 650,
      price: 800,
      lowStockLevel: 24,
    ));

    // Seed Products for tenant_yaounde_002
    _products.add(InventoryItem(
      id: 'prod_bastos_1',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      name: 'Café Camerounais 250g',
      category: 'Food',
      stockLevel: 40,
      unit: 'Packets',
      costPrice: 1500,
      price: 2000,
      lowStockLevel: 10,
    ));
    _products.add(InventoryItem(
      id: 'prod_bastos_2',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      name: 'Sucre Semoule 1kg',
      category: 'Food',
      stockLevel: 5,
      unit: 'Packets',
      costPrice: 800,
      price: 1000,
      lowStockLevel: 15,
    ));

    // 2. Seed Sales for tenant_douala_001
    _sales.add(Sale(
      id: 'SALE-1001',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      itemName: 'Riz Long Grain 5kg',
      quantity: 2,
      totalAmount: 11000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      recordedBy: 'Jean Luc',
    ));
    _sales.add(Sale(
      id: 'SALE-1002',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      itemName: 'Savon Azur 400g',
      quantity: 10,
      totalAmount: 5500,
      date: DateTime.now().subtract(const Duration(days: 2)),
      recordedBy: 'Marie Claire',
    ));

    // Seed Sales for tenant_yaounde_002
    _sales.add(Sale(
      id: 'SALE-2001',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      itemName: 'Café Camerounais 250g',
      quantity: 5,
      totalAmount: 10000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      recordedBy: 'Alain Fofe',
    ));

    // 3. Seed Expenses for tenant_douala_001
    _expenses.add(Expense(
      id: 'EXP-2001',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      category: 'Rent',
      description: 'Monthly warehouse rent',
      amount: 150000,
      date: DateTime.now().subtract(const Duration(days: 20)),
      recordedBy: 'Samuel Eto\'o',
    ));
    _expenses.add(Expense(
      id: 'EXP-2002',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      category: 'Utilities',
      description: 'Electricity bill (ENEO)',
      amount: 45000,
      date: DateTime.now().subtract(const Duration(days: 15)),
      recordedBy: 'Samuel Eto\'o',
    ));
    _expenses.add(Expense(
      id: 'EXP-2003',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      category: 'Transport',
      description: 'Fuel for delivery truck',
      amount: 12500,
      date: DateTime.now().subtract(const Duration(days: 10)),
      recordedBy: 'Jean Luc',
    ));

    // Seed Expenses for tenant_yaounde_002
    _expenses.add(Expense(
      id: 'EXP-3001',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      category: 'Utilities',
      description: 'Water Bill (CDE)',
      amount: 20000,
      date: DateTime.now().subtract(const Duration(days: 12)),
      recordedBy: 'Nathalie Koah',
    ));

    // 4. Seed Tasks for tenant_douala_001
    _tasks.add(ErpTask(
      id: 'task1',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      title: 'Re-stock Beverages',
      description: 'Order more sodas and water for the weekend rush.',
      assignedToId: 'user_marie',
      assignedToName: 'Marie Claire',
      assignedBy: 'Samuel Eto\'o',
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      progress: 0,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ));
    _tasks.add(ErpTask(
      id: 'task2',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      title: 'Submit Tax Documents',
      description: 'Prepare and submit documents to the regional tax office.',
      assignedToId: 'user_luc',
      assignedToName: 'Jean Luc',
      assignedBy: 'Samuel Eto\'o',
      priority: TaskPriority.medium,
      status: TaskStatus.overdue,
      progress: 10,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    ));

    // Seed Tasks for tenant_yaounde_002
    _tasks.add(ErpTask(
      id: 'task_bastos_1',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      title: 'Check Expiry Dates',
      description: 'Go through all shelves and check dates of dairy products.',
      assignedToId: 'user_alain',
      assignedToName: 'Alain Fofe',
      assignedBy: 'Nathalie Koah',
      priority: TaskPriority.low,
      status: TaskStatus.ongoing,
      progress: 50,
      dueDate: DateTime.now().add(const Duration(days: 4)),
    ));

    // 5. Seed Notifications for tenant_douala_001
    _notifications.add(NotificationModel(
      id: 'notif1',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      title: 'Low Stock Warning',
      message: 'Guinness Stout 33cl is low in stock (8 remaining).',
      type: NotificationType.warning,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ));
    _notifications.add(NotificationModel(
      id: 'notif2',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      title: 'Task Overdue',
      message: 'Submit Tax Documents was due on ${DateTime.now().subtract(const Duration(days: 1)).toString().split(' ')[0]}.',
      type: NotificationType.error,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ));

    // Seed Notifications for tenant_yaounde_002
    _notifications.add(NotificationModel(
      id: 'notif_b_1',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      title: 'Low Stock Warning',
      message: 'Sucre Semoule 1kg is low in stock (5 remaining).',
      type: NotificationType.warning,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ));

    // 6. Seed Activity Logs
    _activityLogs.add(ActivityLog(
      id: 'log1',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      userId: 'user_etoo',
      userName: 'Samuel Eto\'o',
      userRole: 'Business Owner',
      actionType: 'LOGIN',
      module: 'Auth',
      description: 'Logged in successfully from mobile app.',
      timestamp: DateTime.now().subtract(const Duration(hours: 24)),
    ));
    _activityLogs.add(ActivityLog(
      id: 'log2',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      userId: 'user_nathalie',
      userName: 'Nathalie Koah',
      userRole: 'Business Owner',
      actionType: 'LOGIN',
      module: 'Auth',
      description: 'Logged in successfully from web app.',
      timestamp: DateTime.now().subtract(const Duration(hours: 48)),
    ));
  }
}
