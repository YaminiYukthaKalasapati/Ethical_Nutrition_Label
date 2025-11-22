import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_service.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;

  Map<String, int> _appDistribution = {};
  Map<String, int> _deviceDistribution = {};
  Map<String, int> _osDistribution = {};
  Map<String, int> _permissionFrequency = {};
  Map<String, int> _dataCollectionPatterns = {};
  Map<String, int> _submissionsByDate = {};

  int _totalSubmissions = 0;
  int _totalUsers = 0;
  int _totalApps = 0;
  double _avgReviewScore = 0.0;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadAnalytics();
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

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      // Get all submissions
      final submissions = await _dataService.getAllSubmissions();

      // Calculate distributions
      final Map<String, int> appDist = {};
      final Map<String, int> deviceDist = {};
      final Map<String, int> osDist = {};
      final Map<String, int> permDist = {};
      final Map<String, int> dataDist = {};
      final Map<String, int> dateMap = {};
      final Set<String> uniqueUsers = {};

      double totalScore = 0;
      int scoreCount = 0;

      for (var submission in submissions) {
        // App distribution
        final appName = submission['app_name'];
        if (appName != null) {
          appDist[appName] = (appDist[appName] ?? 0) + 1;
        }

        // Device distribution
        final deviceModel = submission['device_model'];
        if (deviceModel != null) {
          deviceDist[deviceModel] = (deviceDist[deviceModel] ?? 0) + 1;
        }

        // OS distribution
        final osType = submission['os_type'];
        if (osType != null) {
          osDist[osType] = (osDist[osType] ?? 0) + 1;
        }

        // Permission frequency
        final permissions = submission['permissions_asked'];
        if (permissions is List) {
          for (var perm in permissions) {
            permDist[perm.toString()] = (permDist[perm.toString()] ?? 0) + 1;
          }
        }

        // Data collection patterns
        final dataLinked = submission['data_linked'];
        if (dataLinked is List) {
          for (var data in dataLinked) {
            dataDist[data.toString()] = (dataDist[data.toString()] ?? 0) + 1;
          }
        }

        // Users
        final email = submission['email'];
        if (email != null) {
          uniqueUsers.add(email.toString());
        }

        // Review scores
        final reviewScore = submission['review_score'];
        if (reviewScore != null) {
          try {
            final score = double.parse(reviewScore.toString().split('/')[0]);
            totalScore += score;
            scoreCount++;
          } catch (e) {
            // Skip invalid scores
          }
        }

        // Submissions by date
        final createdAt = submission['created_at'];
        if (createdAt != null) {
          try {
            final date = DateTime.parse(createdAt.toString());
            final dateKey = DateFormat('MMM dd').format(date);
            dateMap[dateKey] = (dateMap[dateKey] ?? 0) + 1;
          } catch (e) {
            // Skip invalid dates
          }
        }
      }

      if (mounted) {
        setState(() {
          _appDistribution = appDist;
          _deviceDistribution = deviceDist;
          _osDistribution = osDist;
          _permissionFrequency = permDist;
          _dataCollectionPatterns = dataDist;
          _submissionsByDate = dateMap;
          _totalSubmissions = submissions.length;
          _totalUsers = uniqueUsers.length;
          _totalApps = appDist.length;
          _avgReviewScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildOverviewCards(),
                    const SizedBox(height: 24),

                    // App Distribution Chart
                    _buildChartSection(
                      'App Distribution',
                      'Number of submissions per app',
                      _buildAppDistributionChart(),
                    ),
                    const SizedBox(height: 24),

                    // OS Distribution Pie Chart
                    _buildChartSection(
                      'Operating System Distribution',
                      'Breakdown by OS type',
                      _buildOSPieChart(),
                    ),
                    const SizedBox(height: 24),

                    // Permission Frequency
                    _buildChartSection(
                      'Top Permissions Requested',
                      'Most frequently requested permissions',
                      _buildPermissionChart(),
                    ),
                    const SizedBox(height: 24),

                    // Data Collection Patterns
                    _buildChartSection(
                      'Data Collection Patterns',
                      'Types of data collected by apps',
                      _buildDataCollectionChart(),
                    ),
                    const SizedBox(height: 24),

                    // Device Distribution
                    _buildChartSection(
                      'Device Distribution',
                      'Devices used for testing',
                      _buildDeviceChart(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Submissions',
          _totalSubmissions.toString(),
          Icons.file_copy,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Users',
          _totalUsers.toString(),
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Apps Tested',
          _totalApps.toString(),
          Icons.apps,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg Review Score',
          _avgReviewScore.toStringAsFixed(1),
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title, String subtitle, Widget chart) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _buildAppDistributionChart() {
    if (_appDistribution.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    // Sort and take top 10
    final sortedApps = _appDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sortedApps.take(10).toList();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: top10.first.value.toDouble() * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= top10.length) return const Text('');
                  final appName = top10[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      appName.length > 15
                          ? '${appName.substring(0, 15)}...'
                          : appName,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            top10.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: top10[index].value.toDouble(),
                  color: Colors.blue,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOSPieChart() {
    if (_osDistribution.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final total = _osDistribution.values.reduce((a, b) => a + b);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _osDistribution.entries.toList().asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final data = entry.value;
                  final percentage = (data.value / total * 100);

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: data.value.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _osDistribution.entries.toList().asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                final data = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${data.key} (${data.value})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionChart() {
    if (_permissionFrequency.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final sortedPerms = _permissionFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sortedPerms.take(10).toList();

    return Column(
      children: top10.map((entry) {
        final percentage = (entry.value / _totalSubmissions * 100);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataCollectionChart() {
    if (_dataCollectionPatterns.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final sortedData = _dataCollectionPatterns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sortedData.take(10).toList();

    return Column(
      children: top10.map((entry) {
        final percentage = (entry.value / _totalSubmissions * 100);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.purple,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeviceChart() {
    if (_deviceDistribution.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final sortedDevices = _deviceDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top8 = sortedDevices.take(8).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: top8.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.key,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
