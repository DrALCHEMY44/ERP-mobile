import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantController = TextEditingController(text: 'tenant_douala_001');
  final _emailController = TextEditingController(text: 'etoo@avenir.cm');
  final _passwordController = TextEditingController(text: 'password123');
  UserRole _selectedRole = UserRole.businessOwner;
  bool _obscurePassword = true;

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      AuthService.login(
        _tenantController.text, 
        _selectedRole,
        name: _selectedRole == UserRole.businessOwner ? 'Samuel Eto\'o' : 'Employee Demo',
        email: _emailController.text,
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _handleDemoLogin(AppUser user) {
    AuthService.loginWithUser(user);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged in as ${user.name} (${user.role.displayName})'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _showDemoAccountsPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Demo Accounts',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.flash_on, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a pre-seeded account to test tenant-isolation and role-based views instantly.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AuthService.demoUsers.length,
                  itemBuilder: (context, index) {
                    final user = AuthService.demoUsers[index];
                    final isDouala = user.tenantId == 'tenant_douala_001';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDouala ? Colors.blue.shade100 : Colors.teal.shade100,
                          child: Icon(
                            user.role == UserRole.businessOwner ? Icons.workspace_premium : Icons.person,
                            color: isDouala ? Colors.blue.shade900 : Colors.teal.shade900,
                          ),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${user.role.displayName}\nTenant: ${isDouala ? "Superette de l'Avenir (Douala)" : "Boutique Bastos (Yaoundé)"}', style: const TextStyle(fontSize: 11)),
                        isThreeLine: true,
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.primary),
                        onTap: () {
                          Navigator.pop(context);
                          _handleDemoLogin(user);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Brand Header
                      Icon(
                        Icons.business_center_rounded,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'martERP AI',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'AI-Powered SME Operations Platform',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Cameroon Flag Decorative Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 24, height: 4, color: Colors.green),
                          Container(width: 24, height: 4, color: Colors.red),
                          Container(width: 24, height: 4, color: Colors.yellow),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // Demo Quick Access Card
                      Card(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                        elevation: 0,
                        borderOnForeground: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: InkWell(
                          onTap: _showDemoAccountsPanel,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.flash_on, color: theme.colorScheme.primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quick-Login for Evaluation',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tap to pick role & tenant instantly',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_right, color: theme.colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('OR LOG IN MANUALLY', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tenant ID
                      TextFormField(
                        controller: _tenantController,
                        decoration: InputDecoration(
                          labelText: 'Tenant ID / Company Code',
                          prefixIcon: const Icon(Icons.domain),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter Tenant ID' : null,
                      ),
                      const SizedBox(height: 16),

                      // Role Selection (For Demo)
                      DropdownButtonFormField<UserRole>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role Profile',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        items: UserRole.values.map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.displayName),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedRole = val!),
                      ),
                      const SizedBox(height: 16),
                      
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@') ? 'Invalid email' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      FilledButton(
                        onPressed: _handleLogin,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Sign In to Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 16),
                      
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text('Don\'t have an account? Register your Business'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
