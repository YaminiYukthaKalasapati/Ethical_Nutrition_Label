import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/dnl_data_aggregator.dart';
import 'dnl_label_display_screen.dart';

class DNLGeneratorScreen extends StatefulWidget {
  const DNLGeneratorScreen({super.key});

  @override
  State<DNLGeneratorScreen> createState() => _DNLGeneratorScreenState();
}

class _DNLGeneratorScreenState extends State<DNLGeneratorScreen> {
  final DNLDataAggregator _aggregator = DNLDataAggregator();
  List<Map<String, dynamic>> _apps = [];
  String? _selectedApp;
  bool _isLoading = true;
  Map<String, dynamic> _appStats = {};

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadApps();
  }

  Future<void> _checkAdminAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    final isAdmin = user?.userMetadata?['role'] == 'admin';

    if (!isAdmin && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied: Admin privileges required'),
        ),
      );
    }
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final apps = await _aggregator.getAvailableApps();

      if (mounted) {
        setState(() {
          _apps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading apps: $e')));
      }
    }
  }

  Future<void> _generateLabel() async {
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an app first')),
      );
      return;
    }

    // Navigate to label display
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DNLLabelDisplayScreen(appName: _selectedApp!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DNL Label Generator'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadApps),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.label,
                                size: 64,
                                color: Colors.teal.shade700,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Digital Nutrition Label Generator',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Generate privacy nutrition labels for apps',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App Selection
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Step 1: Select an App',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedApp,
                                decoration: InputDecoration(
                                  labelText: 'Select App',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.apps),
                                ),
                                items: _apps.map((app) {
                                  final appName = app['app_name'] as String;
                                  final submissionCount =
                                      app['total_submissions'] ?? 0;
                                  return DropdownMenuItem(
                                    value: appName,
                                    child: Text(
                                      '$appName ($submissionCount submissions)',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedApp = value;
                                    _appStats = _apps.firstWhere(
                                      (app) => app['app_name'] == value,
                                      orElse: () => {},
                                    );
                                  });
                                },
                              ),
                              if (_selectedApp != null) ...[
                                const SizedBox(height: 16),
                                _buildAppPreview(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Generate Button
                      if (_selectedApp != null)
                        ElevatedButton.icon(
                          onPressed: _generateLabel,
                          icon: const Icon(Icons.auto_awesome, size: 28),
                          label: const Text(
                            'Generate DNL Label',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Available Apps List
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Apps',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_apps.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No apps found. Submit some data first!',
                                    ),
                                  ),
                                )
                              else
                                ..._apps.map((app) => _buildAppListItem(app)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAppPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            'Total Submissions',
            _appStats['total_submissions']?.toString() ?? '0',
          ),
          _buildPreviewRow(
            'Unique Testers',
            _appStats['unique_testers']?.toString() ?? '0',
          ),
          _buildPreviewRow(
            'Avg Review Score',
            _appStats['avg_review_score']?.toString() ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAppListItem(Map<String, dynamic> app) {
    final appName = app['app_name'] as String;
    final submissionCount = app['total_submissions'] ?? 0;
    final uniqueTesters = app['unique_testers'] ?? 0;
    final isSelected = _selectedApp == appName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : null,
        border: Border.all(
          color: isSelected ? Colors.teal : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Icon(Icons.apps, color: Colors.teal.shade700),
        ),
        title: Text(
          appName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '$submissionCount submissions from $uniqueTesters testers',
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.teal)
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          setState(() {
            _selectedApp = appName;
            _appStats = app;
          });
        },
      ),
    );
  }
}
