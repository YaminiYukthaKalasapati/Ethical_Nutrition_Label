import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DNLLabelWidget extends StatefulWidget {
  final Map<String, dynamic> data;

  const DNLLabelWidget({super.key, required this.data});

  @override
  State<DNLLabelWidget> createState() => _DNLLabelWidgetState();
}

class _DNLLabelWidgetState extends State<DNLLabelWidget> {
  // Track which sections are expanded
  bool _interruptionsExpanded = false;
  bool _permissionsExpanded = false;
  bool _dataHandlingExpanded = false;
  bool _monetizationExpanded = false;
  bool _deviceResourcesExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildThickDivider(),
          _buildAverageDailyInterruptions(),
          _buildDivider(),
          _buildPrivacySection(),
          _buildUserRightsSection(),
          _buildMonetizationSection(),
          _buildDeviceResourcesSection(),
          _buildFootnotes(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Digital Nutrition Facts',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // App Icon Placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android, size: 24),
              ),
              const SizedBox(width: 12),
              // App Name
              Expanded(
                child: Text(
                  widget.data['app_name'] ?? 'Unknown App',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Platform Icon
              Icon(
                widget.data['os_type']?.toString().toLowerCase() == 'ios'
                    ? Icons.apple
                    : Icons.android,
                size: 20,
                color: widget.data['os_type']?.toString().toLowerCase() == 'ios'
                    ? Colors.black
                    : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version: ${widget.data['version'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'For ages ${widget.data['age_rating'] ?? '12+'}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Text(
            'Evaluated on: ${_formatDate(widget.data['evaluated_date'])}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on ${widget.data['total_submissions']} submissions from ${widget.data['total_testers']} testers',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageDailyInterruptions() {
    final interruptions = widget.data['avg_interruptions'] ?? 0;
    return Column(
      children: [
        _buildSectionHeader(
          'Average Daily Interruptions',
          interruptions.toString(),
          _interruptionsExpanded,
          () {
            setState(() {
              _interruptionsExpanded = !_interruptionsExpanded;
            });
          },
        ),
        if (_interruptionsExpanded) ...[
          _buildSubheader('Based on user reports and app behavior'),
          _buildDataRow('Estimated Total', interruptions.toString()),
        ],
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      children: [
        _buildPlainHeader('Privacy'),
        _buildSectionHeader(
          'Permissions Requested',
          '(${_getPermissionCount()} total)',
          _permissionsExpanded,
          () {
            setState(() {
              _permissionsExpanded = !_permissionsExpanded;
            });
          },
          isSubSection: true,
        ),
        if (_permissionsExpanded) ...[..._buildPermissionsList()],
        _buildSectionHeader(
          'Data Handling and Sharing',
          '',
          _dataHandlingExpanded,
          () {
            setState(() {
              _dataHandlingExpanded = !_dataHandlingExpanded;
            });
          },
          isSubSection: true,
        ),
        if (_dataHandlingExpanded) ...[
          _buildSubheader('Data Linked to You'),
          ..._buildDataList(widget.data['data_linked']),
          const SizedBox(height: 8),
          _buildSubheader('Data Not Linked'),
          ..._buildDataList(widget.data['data_not_linked']),
          const SizedBox(height: 8),
          _buildSubheader('Data Used to Track You'),
          ..._buildDataList(widget.data['data_tracked']),
          const SizedBox(height: 8),
          _buildDataRow(
            'Data Collection',
            widget.data['data_collection'] == true ? 'Yes' : 'No',
          ),
          _buildDataRow(
            'Third Party Sharing',
            widget.data['third_party_sharing'] == true ? 'Yes' : 'No',
          ),
        ],
      ],
    );
  }

  Widget _buildUserRightsSection() {
    return Column(
      children: [
        _buildPlainHeader('User Rights'),
        _buildDataRow('Ads Opt-Out', 'Varies by app'),
        _buildDataRow('Account Deletion', 'Check app settings'),
        _buildDataRow('User Data Export', 'Check app settings'),
      ],
    );
  }

  Widget _buildMonetizationSection() {
    final reviewScore = widget.data['avg_review_score'];
    final scoreText = reviewScore != null && reviewScore > 0
        ? '${reviewScore.toStringAsFixed(1)}/5.0'
        : 'N/A';

    return Column(
      children: [
        _buildSectionHeader('Monetization', '', _monetizationExpanded, () {
          setState(() {
            _monetizationExpanded = !_monetizationExpanded;
          });
        }, showIcons: true),
        if (_monetizationExpanded) ...[
          _buildDataRow('Average User Rating', scoreText),
          _buildDataRow('Install Size', widget.data['install_size'] ?? 'N/A'),
        ],
      ],
    );
  }

  Widget _buildDeviceResourcesSection() {
    return Column(
      children: [
        _buildSectionHeader(
          'Device Resources',
          '',
          _deviceResourcesExpanded,
          () {
            setState(() {
              _deviceResourcesExpanded = !_deviceResourcesExpanded;
            });
          },
          showIcons: true,
        ),
        if (_deviceResourcesExpanded) ...[
          _buildDataRow(
            'Battery Impact',
            widget.data['battery_impact'] ?? 'N/A',
          ),
          _buildDataRow('Storage Required', widget.data['storage'] ?? 'N/A'),
          _buildDataRow(
            'Most Common Device State',
            widget.data['device_state'] ?? 'N/A',
          ),
        ],
      ],
    );
  }

  Widget _buildFootnotes() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFootnote(
            '*',
            'This label is based on aggregated data from real user submissions. '
                'Actual app behavior may vary.',
          ),
          const SizedBox(height: 4),
          _buildFootnote(
            '†',
            'Permission status is determined by the percentage of users who reported being asked for that permission.',
          ),
        ],
      ),
    );
  }

  Widget _buildFootnote(String symbol, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(symbol, style: const TextStyle(fontSize: 11, height: 1.2)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 11, height: 1.2)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String value,
    bool isExpanded,
    VoidCallback onTap, {
    bool isSubSection = false,
    bool showIcons = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
              size: 20,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSubSection
                        ? FontWeight.normal
                        : FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: title),
                    if (value.isNotEmpty)
                      TextSpan(
                        text: ' $value',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (showIcons)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.monetization_on_outlined, size: 16),
                  SizedBox(width: 4),
                  Icon(Icons.battery_charging_full, size: 16),
                  SizedBox(width: 4),
                  Icon(Icons.storage, size: 16),
                ],
              ),
            if (!showIcons && !isSubSection && value.isNotEmpty)
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubheader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(text: label),
                  if (subtitle != null)
                    TextSpan(
                      text: ' $subtitle',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPermissionsList() {
    final List<Widget> widgets = [];
    final permissions = widget.data['permissions'];

    if (permissions is Map<String, dynamic>) {
      final sortedEntries = permissions.entries.toList()
        ..sort(
          (a, b) => (b.value['percentage'] ?? 0).compareTo(
            a.value['percentage'] ?? 0,
          ),
        );

      for (var entry in sortedEntries) {
        final permissionName = entry.key;
        final permissionData = entry.value as Map<String, dynamic>;
        final status = permissionData['status'] ?? 'Unknown';
        final percentage = permissionData['percentage'] ?? 0;

        widgets.add(_buildPermissionRow(permissionName, status, percentage));
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No permission data available',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildDataList(dynamic dataMap) {
    final List<Widget> widgets = [];

    if (dataMap is Map<String, dynamic>) {
      final sortedEntries = dataMap.entries.toList()
        ..sort(
          (a, b) => (b.value['percentage'] ?? 0).compareTo(
            a.value['percentage'] ?? 0,
          ),
        );

      for (var entry in sortedEntries) {
        final dataType = entry.key;
        final dataInfo = entry.value as Map<String, dynamic>;
        final percentage = dataInfo['percentage'] ?? 0;

        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(dataType, style: const TextStyle(fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPercentageColor(percentage),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'None reported',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildPermissionRow(String permission, String status, int percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(permission, style: const TextStyle(fontSize: 14)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(status),
                ),
              ),
              Text(
                '$percentage% of users',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.black);
  }

  Widget _buildThickDivider() {
    return Container(height: 3, color: Colors.black);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'mandatory':
        return Colors.red.shade700;
      case 'optional':
        return Colors.orange.shade700;
      case 'not applicable':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 75) return Colors.red;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 25) return Colors.blue;
    return Colors.green;
  }

  int _getPermissionCount() {
    final permissions = widget.data['permissions'];
    if (permissions is Map) {
      return permissions.length;
    }
    return 0;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is DateTime) {
        return DateFormat('MMMM d, yyyy').format(date);
      }
      if (date is String) {
        final parsed = DateTime.parse(date);
        return DateFormat('MMMM d, yyyy').format(parsed);
      }
    } catch (e) {
      // If parsing fails, return as-is
    }
    return date.toString();
  }
}
