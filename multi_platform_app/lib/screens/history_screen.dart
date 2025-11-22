import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../models/experiment_data.dart';
import '../utils/constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _authService = AuthService();
  final _dataService = DataService();

  List<ExperimentData> _submissions = [];
  List<ExperimentData> _filteredSubmissions = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _filterApp;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _authService.currentUserEmail ?? '';
      final data = await _dataService.getUserData();
      setState(() {
        _submissions = data;
        _filteredSubmissions = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filterSubmissions() {
    setState(() {
      _filteredSubmissions = _submissions.where((submission) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            submission.appName?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ==
                true ||
            submission.observations?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ==
                true;

        final matchesFilter =
            _filterApp == null || submission.appName == _filterApp;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _deleteSubmission(String id) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed != true) return;

    try {
      await _dataService.deleteSubmission(id);
      _showSuccessSnackBar('Submission deleted successfully');
      _loadHistory();
    } catch (e) {
      _showErrorSnackBar('Failed to delete submission');
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Submission'),
        content: const Text(
          'Are you sure you want to delete this submission? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDetailsDialog(ExperimentData submission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(submission.appName ?? 'Submission Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Device', submission.deviceModel ?? 'N/A'),
              _buildDetailRow('OS', submission.osType ?? 'N/A'),
              _buildDetailRow('Review Score', submission.reviewScore ?? 'N/A'),
              _buildDetailRow('Age Rating', submission.ageRating ?? 'N/A'),
              if (submission.dataLinked.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Data Linked:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(submission.dataLinked.join(', ')),
              ],
              if (submission.permissionsAsked.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Permissions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(submission.permissionsAsked.join(', ')),
              ],
              if (submission.observations?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const Text(
                  'Observations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(submission.observations!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _submissions.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildSubmissionsList()),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: AppConstants.largePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppConstants.largePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No Submissions Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your submitted data will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/form'),
              icon: const Icon(Icons.add),
              label: const Text('Submit Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    // Get unique apps for filter
    final uniqueApps =
        _submissions
            .map((s) => s.appName)
            .where((name) => name != null)
            .toSet()
            .toList()
          ..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search submissions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                        _filterSubmissions();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterSubmissions();
            },
          ),
          if (uniqueApps.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filter by App',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              initialValue: _filterApp,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Apps'),
                ),
                ...uniqueApps.map(
                  (app) => DropdownMenuItem(value: app, child: Text(app!)),
                ),
              ],
              onChanged: (value) {
                setState(() => _filterApp = value);
                _filterSubmissions();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmissionsList() {
    if (_filteredSubmissions.isEmpty) {
      return Center(
        child: Padding(
          padding: AppConstants.largePadding,
          child: Text(
            'No submissions match your search',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: AppConstants.defaultPadding,
        itemCount: _filteredSubmissions.length,
        itemBuilder: (context, index) {
          final submission = _filteredSubmissions[index];
          return _buildSubmissionCard(submission);
        },
      ),
    );
  }

  Widget _buildSubmissionCard(ExperimentData submission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailsDialog(submission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.apps, color: Colors.teal, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.appName ?? 'Unknown App',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (submission.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Submitted: ${submission.createdAt}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (submission.id != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteSubmission(submission.id!),
                      tooltip: 'Delete',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (submission.deviceModel != null)
                    _buildChip(
                      Icons.phone_android,
                      submission.deviceModel!,
                      Colors.blue,
                    ),
                  if (submission.osType != null)
                    _buildChip(
                      Icons.computer,
                      submission.osType!,
                      Colors.green,
                    ),
                  if (submission.reviewScore != null)
                    _buildChip(
                      Icons.star,
                      '${submission.reviewScore}/5',
                      Colors.amber,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.fromRGBO(color.red, color.green, color.blue, 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
