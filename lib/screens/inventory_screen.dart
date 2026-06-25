import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/erp_provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Food');
    final stockCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'Units');
    final costCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final thresholdCtrl = TextEditingController(text: '10');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Add Inventory Product'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: catCtrl.text,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(value: 'Cleaning', child: Text('Cleaning')),
                      DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                      DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                      DropdownMenuItem(value: 'Services', child: Text('Services')),
                      DropdownMenuItem(value: 'General', child: Text('General')),
                    ],
                    onChanged: (v) => catCtrl.text = v ?? 'General',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          decoration: const InputDecoration(labelText: 'Stock Level', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(labelText: 'Unit (e.g. Bags)', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: costCtrl,
                          decoration: const InputDecoration(labelText: 'Cost Price', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          decoration: const InputDecoration(labelText: 'Selling Price', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: thresholdCtrl,
                    decoration: const InputDecoration(labelText: 'Low Stock Threshold', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final erp = Provider.of<ErpProvider>(context, listen: false);
                  final success = await erp.addProduct(
                    nameCtrl.text,
                    catCtrl.text,
                    int.parse(stockCtrl.text),
                    unitCtrl.text,
                    double.parse(costCtrl.text),
                    double.parse(priceCtrl.text),
                    int.parse(thresholdCtrl.text),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Product added successfully!' : 'Unauthorized/Failed to add product.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Product'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final erp = Provider.of<ErpProvider>(context);

    // Categories list for filtering
    final categories = ['All', ...erp.inventory.map((item) => item.category).toSet()];

    // Filter items
    final items = erp.inventory.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery) ||
          item.category.toLowerCase().contains(_searchQuery);
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Registry'),
      ),
      drawer: const AppDrawer(currentRoute: '/inventory'),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Products',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No products matching filters.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isLowStock = item.stockLevel <= item.lowStockLevel;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Status color indicator
                              Container(
                                width: 6,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isLowStock ? Colors.red : Colors.green,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Category: ${item.category} • Cost: FCFA ${item.costPrice.toInt()}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Stock: ${item.stockLevel} ${item.unit}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isLowStock ? Colors.red : Colors.black87,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isLowStock)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.red.shade200),
                                            ),
                                            child: const Text(
                                              'LOW STOCK',
                                              style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Action Panel
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'FCFA ${item.price.toInt()}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      erp.reorderProduct(item.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Supplier Order Placed: Restocked 50 ${item.unit} for ${item.name}'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.refresh, size: 12),
                                    label: const Text('Reorder', style: TextStyle(fontSize: 10)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      minimumSize: const Size(60, 24),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: AuthService.hasPermission('manageInventory')
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
