import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  static const Color _black = Color(0xFF111111);
  static const Color _gray = Color(0xFF777777);
  static const Color _lightGray = Color(0xFFF3F3F3);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final CollectionReference<Map<String, dynamic>> _usersRef = FirebaseFirestore
      .instance
      .collection('users');

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

  String _getUserName(Map<String, dynamic> data) {
    return (data['name'] ??
            data['fullName'] ??
            data['displayName'] ??
            data['username'] ??
            'No name provided')
        .toString();
  }

  String _getUserEmail(Map<String, dynamic> data) {
    return (data['email'] ?? 'No email provided').toString();
  }

  String _getUserRole(Map<String, dynamic> data) {
    return (data['role'] ?? 'customer').toString();
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
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
                color: _lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _black, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: _gray, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: _black,
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

  Widget _buildUsersTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
  ) {
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Color(0xFF999999)),
              SizedBox(height: 14),
              Text(
                'No users found.',
                style: TextStyle(fontWeight: FontWeight.w600, color: _black),
              ),
              SizedBox(height: 5),
              Text('Try another search.', style: TextStyle(color: _gray)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 30,
        headingRowColor: WidgetStateProperty.all(_lightGray),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: _black,
        ),
        dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('User ID')),
        ],
        rows: users.map((user) {
          final data = user.data();
          final name = _getUserName(data);
          final email = _getUserEmail(data);
          final role = _getUserRole(data);

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 160,
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(email, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _lightGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _black,
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(user.id, overflow: TextOverflow.ellipsis),
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
            Icon(Icons.people_outline, color: _black),
            SizedBox(width: 10),
            Text(
              'User Monitoring',
              style: TextStyle(fontWeight: FontWeight.bold, color: _black),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _usersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load users:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allUsers = snapshot.data?.docs ?? [];

          final filteredUsers = allUsers.where((user) {
            final data = user.data();
            final name = _getUserName(data).toLowerCase();
            final email = _getUserEmail(data).toLowerCase();
            final role = _getUserRole(data).toLowerCase();

            return name.contains(_searchQuery) ||
                email.contains(_searchQuery) ||
                role.contains(_searchQuery) ||
                user.id.toLowerCase().contains(_searchQuery);
          }).toList();

          final customerCount = allUsers.where((user) {
            return _getUserRole(user.data()).toLowerCase() == 'customer';
          }).length;

          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const Text(
                'User Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Monitor registered accounts and their account roles.',
                style: TextStyle(color: _gray, fontSize: 14),
              ),
              const SizedBox(height: 26),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 650
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          'Total Registered Users',
                          '${allUsers.length}',
                          Icons.people_outline,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildStatCard(
                          'Customer Accounts',
                          '$customerCount',
                          Icons.person_outline,
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
                      const Text(
                        'Registered Users',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _black,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search name, email, role, or user ID...',
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
                      _buildUsersTable(filteredUsers),
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
