import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_service.dart';
import 'package:intl/intl.dart';

class AdminAllSubmissionsScreen extends StatefulWidget {
  const AdminAllSubmissionsScreen({super.key});

  @override
  State<AdminAllSubmissionsScreen> createState() =>
      _AdminAllSubmissionsScreenState();
}

class _AdminAllSubmissionsScreenState extends State<AdminAllSubmissionsScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _submissions = [];
  List<String> _apps = ['All Apps'];
  String _selectedApp = 'All Apps';
  String _sortBy = 'created_at';
  bool _ascending = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final submissions = await _dataService.getAllSubmissions(
        searchQuery: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        filterApp: _selectedApp == 'All Apps' ? null : _selectedApp,
        sortBy: _sortBy,
        ascending: _ascending,
      );

      // Get unique apps
      final appSet = <String>{'All Apps'};
      for (var submission in submissions) {
        if (submission['app_name'] != null) {
          appSet.add(submission['app_name'] as String);
        }
      }

      if (mounted) {
        setState(() {
          _submissions = submissions;
          _apps = appSet.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _deleteSubmission(String id, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Submission'),
        content: Text(
          'Are you sure you want to delete this submission by $userName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dataService.deleteSubmissionAsAdmin(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission deleted successfully')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting submission: $e')),
          );
        }
      }
    }
  }

  void _showSubmissionDetails(Map<String, dynamic> submission) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Submission Details',
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
                  _buildDetailRow('Name', submission['name']),
                  _buildDetailRow('Email', submission['email']),
                  _buildDetailRow('App Name', submission['app_name']),
                  _buildDetailRow('Review Score', submission['review_score']),
                  _buildDetailRow('Age Rating', submission['age_rating']),
                  _buildDetailRow('Install Size', submission['install_size']),
                  _buildDetailRow('Device Model', submission['device_model']),
                  _buildDetailRow('Device Make', submission['device_make']),
                  _buildDetailRow('OS Type', submission['os_type']),
                  _buildDetailRow('Battery', submission['battery']),
                  _buildDetailRow('Device State', submission['device_state']),
                  const SizedBox(height: 16),
                  _buildArrayDetail('Data Linked', submission['data_linked']),
                  _buildArrayDetail(
                    'Data Not Linked',
                    submission['data_not_linked'],
                  ),
                  _buildArrayDetail('Data Tracked', submission['data_tracked']),
                  _buildArrayDetail(
                    'Permissions Asked',
                    submission['permissions_asked'],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Observations',
                    submission['observations'] ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Submitted',
                    _formatDate(submission['created_at']),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteSubmission(
                          submission['id'],
                          submission['name'] ?? 'Unknown',
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Submission'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
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
            width: 120,
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

  Widget _buildArrayDetail(String label, dynamic value) {
    final List<dynamic> items = value is List ? value : [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Chip(
                label: Text(item.toString()),
                backgroundColor: Colors.blue.shade50,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Submissions'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search by app name, email, name, observations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadData();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _loadData(),
                ),
                const SizedBox(height: 12),
                // Filters Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedApp,
                        decoration: InputDecoration(
                          labelText: 'Filter by App',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _apps.map((app) {
                          return DropdownMenuItem(value: app, child: Text(app));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedApp = value!);
                          _loadData();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sortBy,
                        decoration: InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'created_at',
                            child: Text('Date'),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('User Name'),
                          ),
                          DropdownMenuItem(
                            value: 'app_name',
                            child: Text('App Name'),
                          ),
                          DropdownMenuItem(
                            value: 'review_score',
                            child: Text('Review Score'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                          _loadData();
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
                        _loadData();
                      },
                      tooltip: _ascending ? 'Ascending' : 'Descending',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results Count
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Showing ${_submissions.length} submission${_submissions.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Submissions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _submissions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No submissions found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _submissions.length,
                      itemBuilder: (context, index) {
                        final submission = _submissions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (submission['name'] ?? 'U')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              submission['app_name'] ?? 'Unknown App',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'By: ${submission['name']} (${submission['email']})',
                                ),
                                Text(
                                  'Device: ${submission['device_model'] ?? 'N/A'}',
                                ),
                                Text(
                                  'Date: ${_formatDate(submission['created_at'])}',
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () =>
                                      _showSubmissionDetails(submission),
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteSubmission(
                                    submission['id'],
                                    submission['name'] ?? 'Unknown',
                                  ),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => _showSubmissionDetails(submission),
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
}
