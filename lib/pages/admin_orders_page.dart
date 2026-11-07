import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  static const List<String> _statuses = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  static const Color _black = Color(0xFF111111);
  static const Color _gray = Color(0xFF777777);
  static const Color _lightGray = Color(0xFFF3F3F3);

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _getItems(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (value is Map) {
      return value.values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return 'Date unavailable';

    final local = date.toLocal();

    return '${local.month}/${local.day}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    String status,
  ) async {
    try {
      await reference.update({'status': status});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _black,
          content: Text('Order status updated to $status.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update order: $error')));
    }
  }

  void _showOrderDetails(
    BuildContext context,
    String orderId,
    Map<String, dynamic> order,
  ) {
    final items = _getItems(order['items']);
    final total = _toDouble(order['totalAmount'] ?? order['total']);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: _black),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Order ID', orderId),
                _detailRow('Customer', '${order['customerName'] ?? 'N/A'}'),
                _detailRow('Address', '${order['address'] ?? 'N/A'}'),
                _detailRow('Payment', '${order['paymentMethod'] ?? 'N/A'}'),
                _detailRow('Status', '${order['status'] ?? 'Pending'}'),
                _detailRow('Date', _formatDate(order['createdAt'])),
                const Divider(height: 28),
                const Text(
                  'Ordered Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _black,
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const Text(
                    'No item details available.',
                    style: TextStyle(color: _gray),
                  )
                else
                  ...items.map((item) {
                    final name = item['name'] ?? 'Unnamed product';
                    final quantity = item['quantity'] ?? 0;
                    final price = _toDouble(item['price']);
                    final subtotal = _toDouble(
                      item['subtotal'] ?? (price * _toDouble(quantity)),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: $quantity'
                                  '${item['size'] != null ? ' • Size: ${item['size']}' : ''}',
                                  style: const TextStyle(
                                    color: _gray,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₱${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _black,
                      ),
                    ),
                    Text(
                      '₱${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(color: _gray, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _black,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusLabel(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: _black,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _orderCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final order = document.data();
    final orderId = (order['orderId'] ?? document.id).toString();
    final displayId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    final customer = (order['customerName'] ?? 'Unknown Customer').toString();
    final payment = (order['paymentMethod'] ?? 'N/A').toString();

    final status = _statuses.contains(order['status'])
        ? order['status'] as String
        : 'Pending';

    final total = _toDouble(order['totalAmount'] ?? order['total']);
    final items = _getItems(order['items']);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Order #$displayId',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _black,
                  ),
                ),
                _statusLabel(status),
              ],
            ),
            const SizedBox(height: 18),
            _detailRow('Customer', customer),
            _detailRow('Payment', payment),
            _detailRow('Items', '${items.length}'),
            _detailRow('Date', _formatDate(order['createdAt'])),
            const SizedBox(height: 8),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(color: _gray, fontSize: 13),
                ),
                Text(
                  '₱${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Update Order Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _black,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: status,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: _statuses.map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) {
                      if (value == null || value == status) return;

                      _updateStatus(context, document.reference, value);
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _showOrderDetails(context, orderId, order);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersQuery = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orders Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: _black),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ordersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load orders:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const Text(
                'Orders Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'View customer orders and manage order statuses.',
                style: TextStyle(color: _gray, fontSize: 14),
              ),
              const SizedBox(height: 26),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          color: _black,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Total Orders',
                          style: TextStyle(color: _gray, fontSize: 14),
                        ),
                      ),
                      Text(
                        '${documents.length}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (documents.isEmpty)
                const Card(
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Color(0xFF999999),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'No orders found.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _black,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Customer orders will appear here.',
                          style: TextStyle(color: _gray),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...documents.map((document) => _orderCard(context, document)),
            ],
          );
        },
      ),
    );
  }
}
