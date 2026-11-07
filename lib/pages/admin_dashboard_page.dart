import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/product_form_dialog.dart';

import 'admin_orders_page.dart';
import 'admin_users_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openProductForm({ProductModel? product}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ProductFormDialog(product: product),
    );

    if (result == null || !mounted) return;

    setState(() => _isSaving = true);

    try {
      if (product == null) {
        await _productService.addProduct(
          name: result['name'] as String,
          price: result['price'] as double,
          quantity: result['quantity'] as int,
        );
      } else {
        await _productService.updateProduct(
          id: product.id,
          name: result['name'] as String,
          price: result['price'] as double,
          quantity: result['quantity'] as int,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111111),
          content: Text(
            product == null
                ? 'Product added successfully.'
                : 'Product updated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save product: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _productService.deleteProduct(product.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF111111),
          content: Text('Product deleted successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete product: $error')),
      );
    }
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF111111), size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTable(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Color(0xFF999999),
              ),
              SizedBox(height: 12),
              Text(
                'No products found.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Add a product or try another search.',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 36,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF222222),
        ),
        dataTextStyle: const TextStyle(color: Color(0xFF333333), fontSize: 13),
        columns: const [
          DataColumn(label: Text('Product Name')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: products.map((product) {
          final inStock = product.quantity > 0;

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 180,
                  child: Text(
                    product.name.isEmpty ? '(Unnamed product)' : product.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text('₱${product.price.toStringAsFixed(2)}')),
              DataCell(Text('${product.quantity}')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: inStock
                        ? const Color(0xFFF0F0F0)
                        : const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    inStock ? 'In Stock' : 'Out of Stock',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit product',
                      onPressed: _isSaving
                          ? null
                          : () => _openProductForm(product: product),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF222222),
                        size: 20,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete product',
                      onPressed: _isSaving
                          ? null
                          : () => _confirmDelete(product),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFF777777),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront_outlined, color: Color(0xFF111111)),
            SizedBox(width: 10),
            Text(
              'SOLE. Admin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Orders'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AdminUsersPage()));
            },
            icon: const Icon(Icons.people_outline),
            label: const Text('Users'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _productService.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load products.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = snapshot.data ?? <ProductModel>[];

          final filteredProducts = allProducts.where((product) {
            return product.name.toLowerCase().contains(_searchQuery);
          }).toList();

          final totalUnits = allProducts.fold<int>(
            0,
            (total, product) => total + product.quantity,
          );

          final lowStockCount = allProducts
              .where((product) => product.quantity > 0 && product.quantity <= 5)
              .length;

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const Text(
                'Product Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage products, prices, and inventory in real time.',
                style: TextStyle(color: Color(0xFF777777), fontSize: 14),
              ),
              const SizedBox(height: 26),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 900
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth >= 560
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          title: 'Total Products',
                          value: '${allProducts.length}',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          title: 'Total Stock Units',
                          value: '$totalUnits',
                          icon: Icons.warehouse_outlined,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _statCard(
                          title: 'Low Stock Items',
                          value: '$lowStockCount',
                          icon: Icons.warning_amber_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 26),

              Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Products',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111111),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _openProductForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search product name...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isSaving)
                        const LinearProgressIndicator(minHeight: 2),
                      _buildProductTable(filteredProducts),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
