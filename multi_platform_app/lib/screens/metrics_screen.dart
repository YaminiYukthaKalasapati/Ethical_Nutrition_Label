import 'package:flutter/material.dart';
import '../services/data_service.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  MetricsData? _metricsData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final metrics = await _dataService.calculateMetrics();
      if (mounted) {
        setState(() {
          _metricsData = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrics Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMetrics),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load metrics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadMetrics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCard(),
                        const SizedBox(height: 24),
                        _buildDistributionSection(
                          'App Distribution',
                          _metricsData!.appDistribution,
                          Icons.apps,
                          Colors.blue,
                        ),
                        const SizedBox(height: 24),
                        _buildDistributionSection(
                          'Device Distribution',
                          _metricsData!.deviceDistribution,
                          Icons.devices,
                          Colors.green,
                        ),
                        const SizedBox(height: 24),
                        _buildDistributionSection(
                          'OS Distribution',
                          _metricsData!.osDistribution,
                          Icons.settings,
                          Colors.orange,
                        ),
                        const SizedBox(height: 24),
                        _buildDistributionSection(
                          'Permission Frequency',
                          _metricsData!.permissionFrequency,
                          Icons.security,
                          Colors.red,
                        ),
                        const SizedBox(height: 24),
                        _buildDistributionSection(
                          'Data Collection Patterns',
                          _metricsData!.dataCollectionPatterns,
                          Icons.data_usage,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 150, 136, 0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewStat(
                'Total Submissions',
                '${_metricsData!.totalSubmissions}',
                Icons.file_copy,
              ),
              _buildOverviewStat(
                'Avg Review Score',
                _metricsData!.averageReviewScore.toStringAsFixed(1),
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionSection(
    String title,
    Map<String, int> data,
    IconData icon,
    Color color,
  ) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by frequency
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final percentage = (_metricsData!.totalSubmissions > 0)
                  ? (entry.value / _metricsData!.totalSubmissions * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
