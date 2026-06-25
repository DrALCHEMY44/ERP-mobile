import '../models/app_user.dart';

class AuthService {
  static AppUser? _currentUser;

  // Web app permissions mapping
  static const Map<UserRole, List<String>> rolePermissions = {
    UserRole.platformSuperAdmin: ['managePlatform'],
    UserRole.businessOwner: ['*'], // Full access
    UserRole.manager: [
      'viewInventory', 'manageInventory',
      'viewSales', 'manageSales',
      'viewExpenses', 'manageExpenses',
      'viewTasks', 'manageTasks',
      'viewReports',
      'viewActivityLogs',
      'viewCustomers', 'manageCustomers',
      'viewSuppliers', 'manageSuppliers',
      'viewDocuments', 'manageDocuments'
    ],
    UserRole.accountant: [
      'viewSales', 'manageSales',
      'viewExpenses', 'manageExpenses',
      'viewFinance', 'manageFinance',
      'viewReports',
      'viewDocuments'
    ],
    UserRole.hrOfficer: [
      'viewEmployees', 'manageEmployees',
      'viewAttendance',
      'viewSalaryRecords',
      'viewReports',
      'viewTasks', 'manageTasks',
      'viewDocuments', 'manageDocuments'
    ],
    UserRole.staff: [
      'viewInventory',
      'viewSales',
      'viewTasks', 'manageTasks',
      'viewDocuments'
    ],
    UserRole.viewer: [
      'viewInventory',
      'viewSales',
      'viewTasks',
      'viewReports',
      'viewDocuments'
    ],
  };

  // Predefined demo accounts for easy defense presentation
  static final List<AppUser> demoUsers = [
    AppUser(
      id: 'user_etoo',
      name: 'Samuel Eto\'o',
      email: 'etoo@avenir.cm',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      role: UserRole.businessOwner,
    ),
    AppUser(
      id: 'user_marie',
      name: 'Marie Claire',
      email: 'marie@avenir.cm',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      role: UserRole.staff,
    ),
    AppUser(
      id: 'user_luc',
      name: 'Jean Luc',
      email: 'luc@avenir.cm',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      role: UserRole.accountant,
    ),
    AppUser(
      id: 'user_nathalie',
      name: 'Nathalie Koah',
      email: 'nathalie@bastos.cm',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      role: UserRole.businessOwner,
    ),
    AppUser(
      id: 'user_alain',
      name: 'Alain Fofe',
      email: 'alain@bastos.cm',
      tenantId: 'tenant_yaounde_002',
      businessId: 'biz_bastos_retail',
      role: UserRole.manager,
    ),
    AppUser(
      id: 'user_cathy',
      name: 'Cathy Kamga',
      email: 'cathy@avenir.cm',
      tenantId: 'tenant_douala_001',
      businessId: 'biz_superette_central',
      role: UserRole.viewer,
    ),
  ];

  static void login(String tenantId, UserRole role, {String? name, String? email, String? businessId}) {
    _currentUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'John Doe',
      email: email ?? 'user@example.com',
      tenantId: tenantId,
      businessId: businessId ?? 'biz_general',
      role: role,
    );
  }

  static void loginWithUser(AppUser user) {
    _currentUser = user;
  }

  static AppUser? get currentUser => _currentUser;

  static bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    final permissions = rolePermissions[_currentUser!.role];
    if (permissions == null) return false;
    if (permissions.contains('*')) return true;
    return permissions.contains(permission);
  }

  static void logout() {
    _currentUser = null;
  }
}
