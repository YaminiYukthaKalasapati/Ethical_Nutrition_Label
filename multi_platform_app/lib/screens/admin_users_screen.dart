import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'package:intl/intl.dart';
import '../screens/login_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final DataService _dataService = DataService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _sortBy = 'submission_count';
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadUsers();
  }

  Future<void> _checkAdminAccess() async {
    final isAdmin = await _dataService.isAdmin();
    if (!isAdmin && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied: Admin privileges required'),
        ),
      );
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _dataService.getAllUsers();

      // Sort users
      users.sort((a, b) {
        final aValue = a[_sortBy];
        final bValue = b[_sortBy];

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _ascending ? -1 : 1;
        if (bValue == null) return _ascending ? 1 : -1;

        if (_ascending) {
          return Comparable.compare(aValue, bValue);
        } else {
          return Comparable.compare(bValue, aValue);
        }
      });

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'User Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildDetailRow('Name', user['name']),
                _buildDetailRow('Email', user['email']),
                _buildDetailRow(
                  'Total Submissions',
                  user['submission_count']?.toString(),
                ),
                _buildDetailRow(
                  'First Submission',
                  _formatDate(user['first_submission']),
                ),
                _buildDetailRow(
                  'Latest Submission',
                  _formatDate(user['latest_submission']),
                ),
                const SizedBox(height: 24),
                _buildStatCard(
                  'Activity Level',
                  _getActivityLevel(user['submission_count'] ?? 0),
                  _getActivityColor(user['submission_count'] ?? 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(color.red, color.green, color.blue, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getActivityLevel(int submissions) {
    if (submissions == 0) return 'Inactive';
    if (submissions < 5) return 'Low';
    if (submissions < 10) return 'Medium';
    if (submissions < 20) return 'High';
    return 'Very High';
  }

  Color _getActivityColor(int submissions) {
    if (submissions == 0) return Colors.grey;
    if (submissions < 5) return Colors.orange;
    if (submissions < 10) return Colors.blue;
    if (submissions < 20) return Colors.green;
    return Colors.purple;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewStat(
                  'Total Users',
                  _users.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildOverviewStat(
                  'Active Users',
                  _users
                      .where((u) => (u['submission_count'] ?? 0) > 0)
                      .length
                      .toString(),
                  Icons.person_add_alt_1,
                  Colors.green,
                ),
                _buildOverviewStat(
                  'Avg Submissions',
                  _users.isEmpty
                      ? '0'
                      : (_users
                                    .map((u) => u['submission_count'] ?? 0)
                                    .reduce((a, b) => a + b) /
                                _users.length)
                            .toStringAsFixed(1),
                  Icons.bar_chart,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Sort Controls
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'submission_count',
                        child: Text('Submissions'),
                      ),
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'email', child: Text('Email')),
                      DropdownMenuItem(
                        value: 'first_submission',
                        child: Text('First Submission'),
                      ),
                      DropdownMenuItem(
                        value: 'latest_submission',
                        child: Text('Latest Submission'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _sortBy = value!);
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  onPressed: () {
                    setState(() => _ascending = !_ascending);
                    _loadUsers();
                  },
                  tooltip: _ascending ? 'Ascending' : 'Descending',
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final submissionCount = user['submission_count'] ?? 0;
                        final activityColor = _getActivityColor(
                          submissionCount,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color.fromRGBO(
                                activityColor.red,
                                activityColor.green,
                                activityColor.blue,
                                0.2,
                              ),
                              child: Text(
                                (user['name'] ?? 'U')[0].toUpperCase(),
                                style: TextStyle(
                                  color: activityColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(user['email'] ?? 'N/A'),
                                Text(
                                  'First: ${_formatDate(user['first_submission'])}',
                                ),
                                Text(
                                  'Latest: ${_formatDate(user['latest_submission'])}',
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: activityColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$submissionCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'submissions',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => _showUserDetails(user),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
