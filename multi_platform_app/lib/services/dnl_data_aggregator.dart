import 'package:supabase_flutter/supabase_flutter.dart';

class DNLDataAggregator {
  final _supabase = Supabase.instance.client;

  /// Get list of all apps with submission counts
  Future<List<Map<String, dynamic>>> getAvailableApps() async {
    try {
      // UPDATED: Using your actual table name from Supabase
      final response = await _supabase
          .from('dnl_experiment_data') // ← YOUR ACTUAL TABLE NAME
          .select('app_name, email, review_score')
          .order('created_at', ascending: false);

      // Group by app name and count submissions
      final Map<String, Map<String, dynamic>> appMap = {};

      for (var submission in response) {
        final appName = submission['app_name'] as String?;
        if (appName == null || appName.isEmpty) continue;

        if (!appMap.containsKey(appName)) {
          appMap[appName] = {
            'app_name': appName,
            'total_submissions': 0,
            'unique_testers': <String>{},
            'review_scores': <double>[],
          };
        }

        appMap[appName]!['total_submissions'] =
            (appMap[appName]!['total_submissions'] as int) + 1;

        final email = submission['email'] as String?;
        if (email != null) {
          (appMap[appName]!['unique_testers'] as Set<String>).add(email);
        }

        final reviewScore = submission['review_score'] as String?;
        if (reviewScore != null) {
          try {
            final score = double.parse(reviewScore.split('/')[0]);
            (appMap[appName]!['review_scores'] as List<double>).add(score);
          } catch (e) {
            // Skip invalid scores
          }
        }
      }

      // Calculate averages and convert to list
      final List<Map<String, dynamic>> apps = [];
      for (var entry in appMap.entries) {
        final uniqueTesters = entry.value['unique_testers'] as Set<String>;
        final reviewScores = entry.value['review_scores'] as List<double>;

        apps.add({
          'app_name': entry.key,
          'total_submissions': entry.value['total_submissions'],
          'unique_testers': uniqueTesters.length,
          'avg_review_score': reviewScores.isEmpty
              ? 0.0
              : reviewScores.reduce((a, b) => a + b) / reviewScores.length,
        });
      }

      // Sort by submission count
      apps.sort(
        (a, b) => (b['total_submissions'] as int).compareTo(
          a['total_submissions'] as int,
        ),
      );

      return apps;
    } catch (e) {
      throw Exception('Failed to load apps: $e');
    }
  }

  /// Aggregate all data for a specific app
  Future<Map<String, dynamic>> aggregateAppData(String appName) async {
    try {
      // UPDATED: Using your actual table name from Supabase
      final submissions = await _supabase
          .from('dnl_experiment_data') // ← YOUR ACTUAL TABLE NAME
          .select()
          .eq('app_name', appName)
          .order('created_at', ascending: false);

      if (submissions.isEmpty) {
        throw Exception('No data found for this app');
      }

      return _buildAggregatedData(submissions, appName);
    } catch (e) {
      throw Exception('Failed to aggregate data: $e');
    }
  }

  Map<String, dynamic> _buildAggregatedData(
    List<dynamic> submissions,
    String appName,
  ) {
    final result = <String, dynamic>{};

    // Basic Information
    result['app_name'] = appName;
    result['total_submissions'] = submissions.length;
    result['total_testers'] = _countUniqueUsers(submissions);

    // Version (most recent)
    result['version'] = submissions.first['device_model'] ?? 'Unknown';

    // Evaluation date (most recent submission)
    result['evaluated_date'] =
        submissions.first['created_at'] ?? DateTime.now().toIso8601String();

    // Age Rating (most common)
    result['age_rating'] = _getMostCommon(submissions, 'age_rating') ?? '12+';

    // Average Review Score
    result['avg_review_score'] = _calculateAvgReviewScore(submissions);

    // Install Size (most common)
    result['install_size'] =
        _getMostCommon(submissions, 'install_size') ?? 'N/A';

    // OS Type (most common)
    result['os_type'] = _getMostCommon(submissions, 'os_type') ?? 'Android';

    // Average Daily Interruptions (placeholder - you can add logic based on your data)
    result['avg_interruptions'] = 8;

    // Permissions (aggregated with frequency)
    result['permissions'] = _aggregateListWithFrequency(
      submissions,
      'permissions_asked',
    );

    // Data Linked (aggregated with frequency)
    result['data_linked'] = _aggregateListWithFrequency(
      submissions,
      'data_linked',
    );

    // Data Not Linked (aggregated with frequency)
    result['data_not_linked'] = _aggregateListWithFrequency(
      submissions,
      'data_not_linked',
    );

    // Data Tracked (aggregated with frequency)
    result['data_tracked'] = _aggregateListWithFrequency(
      submissions,
      'data_tracked',
    );

    // Data Collection (Yes if any submission has it)
    result['data_collection'] = _hasAnyValue(submissions, 'data_linked');

    // Third Party Sharing (based on data tracked)
    result['third_party_sharing'] = _hasAnyValue(submissions, 'data_tracked');

    // Device State (most common)
    result['device_state'] =
        _getMostCommon(submissions, 'device_state') ?? 'Lab';

    // Battery Impact (most common)
    result['battery_impact'] = _getMostCommon(submissions, 'battery') ?? 'N/A';

    // Storage (install size)
    result['storage'] = _getMostCommon(submissions, 'install_size') ?? 'N/A';

    return result;
  }

  int _countUniqueUsers(List<dynamic> submissions) {
    final Set<String> uniqueEmails = {};
    for (var sub in submissions) {
      final email = sub['email'];
      if (email != null) {
        uniqueEmails.add(email.toString());
      }
    }
    return uniqueEmails.length;
  }

  String? _getMostCommon(List<dynamic> submissions, String field) {
    final Map<String, int> frequency = {};
    for (var sub in submissions) {
      final value = sub[field];
      if (value != null && value.toString().isNotEmpty) {
        final key = value.toString();
        frequency[key] = (frequency[key] ?? 0) + 1;
      }
    }
    if (frequency.isEmpty) return null;
    return frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double _calculateAvgReviewScore(List<dynamic> submissions) {
    double total = 0;
    int count = 0;
    for (var sub in submissions) {
      final score = sub['review_score'];
      if (score != null) {
        try {
          final numScore = double.parse(score.toString().split('/')[0]);
          total += numScore;
          count++;
        } catch (e) {
          // Skip invalid scores
        }
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  Map<String, Map<String, dynamic>> _aggregateListWithFrequency(
    List<dynamic> submissions,
    String field,
  ) {
    final Map<String, int> frequency = {};

    for (var sub in submissions) {
      final items = sub[field];
      if (items is List) {
        for (var item in items) {
          final key = item.toString();
          if (key.isNotEmpty) {
            frequency[key] = (frequency[key] ?? 0) + 1;
          }
        }
      }
    }

    // Convert to percentage and status
    final result = <String, Map<String, dynamic>>{};
    for (var entry in frequency.entries) {
      final percentage = ((entry.value / submissions.length) * 100).round();
      result[entry.key] = {
        'count': entry.value,
        'percentage': percentage,
        'status': _determinePermissionStatus(entry.value, submissions.length),
      };
    }

    return result;
  }

  String _determinePermissionStatus(int count, int total) {
    final percentage = (count / total) * 100;
    if (percentage >= 80) return 'Mandatory';
    if (percentage >= 40) return 'Optional';
    return 'Not Applicable';
  }

  bool _hasAnyValue(List<dynamic> submissions, String field) {
    for (var sub in submissions) {
      final value = sub[field];
      if (value is List && value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
