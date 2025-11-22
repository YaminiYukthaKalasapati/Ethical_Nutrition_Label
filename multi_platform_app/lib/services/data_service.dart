import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/experiment_data.dart';

class DataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================================================
  // USER DATA SUBMISSION
  // ================================================

  Future<void> submitData(ExperimentData data) async {
    try {
      await _supabase.from('dnl_experiment_data').insert(data.toJson());
    } catch (e) {
      throw Exception('Failed to submit data: $e');
    }
  }

  // ================================================
  // USER DATA RETRIEVAL
  // ================================================

  Future<List<ExperimentData>> getUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('dnl_experiment_data')
          .select()
          .match({'email': user.email!})
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ExperimentData.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<List<ExperimentData>> getUserDataFiltered({
    String? searchQuery,
    String? filterApp,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Start with base query
      final response = await _supabase
          .from('dnl_experiment_data')
          .select()
          .match({'email': user.email!})
          .order('created_at', ascending: false);

      // Filter in-memory (simpler than complex queries)
      List<ExperimentData> results = (response as List)
          .map((item) => ExperimentData.fromJson(item))
          .toList();

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        results = results.where((data) {
          final appNameMatch =
              data.appName?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false;
          final obsMatch =
              data.observations?.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false;
          return appNameMatch || obsMatch;
        }).toList();
      }

      // Apply app filter
      if (filterApp != null &&
          filterApp.isNotEmpty &&
          filterApp != 'All Apps') {
        results = results.where((data) => data.appName == filterApp).toList();
      }

      return results;
    } catch (e) {
      throw Exception('Failed to fetch filtered data: $e');
    }
  }

  Future<List<String>> getUserApps() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('dnl_experiment_data')
          .select('app_name')
          .match({'email': user.email!});

      final apps = (response as List)
          .where((item) => item['app_name'] != null)
          .map((item) => item['app_name'] as String)
          .toSet()
          .toList();

      apps.sort();
      return apps;
    } catch (e) {
      throw Exception('Failed to fetch user apps: $e');
    }
  }

  Future<void> deleteSubmission(String id) async {
    try {
      await _supabase.from('dnl_experiment_data').delete().match({'id': id});
    } catch (e) {
      throw Exception('Failed to delete submission: $e');
    }
  }

  // ================================================
  // METRICS CALCULATION
  // ================================================

  Future<MetricsData> calculateMetrics() async {
    try {
      final userData = await getUserData();

      if (userData.isEmpty) {
        return MetricsData(
          totalSubmissions: 0,
          averageReviewScore: 0.0,
          appDistribution: {},
          deviceDistribution: {},
          osDistribution: {},
          permissionFrequency: {},
          dataCollectionPatterns: {},
        );
      }

      final totalSubmissions = userData.length;

      double totalScore = 0;
      int scoreCount = 0;
      for (var data in userData) {
        if (data.reviewScore != null && data.reviewScore!.isNotEmpty) {
          try {
            final score = double.parse(data.reviewScore!.split('/')[0]);
            totalScore += score;
            scoreCount++;
          } catch (e) {
            // Skip invalid scores
          }
        }
      }
      final averageReviewScore = scoreCount > 0
          ? (totalScore / scoreCount)
          : 0.0;

      final Map<String, int> appDistribution = {};
      for (var data in userData) {
        if (data.appName != null) {
          appDistribution[data.appName!] =
              (appDistribution[data.appName!] ?? 0) + 1;
        }
      }

      final Map<String, int> deviceDistribution = {};
      for (var data in userData) {
        if (data.deviceModel != null) {
          deviceDistribution[data.deviceModel!] =
              (deviceDistribution[data.deviceModel!] ?? 0) + 1;
        }
      }

      final Map<String, int> osDistribution = {};
      for (var data in userData) {
        if (data.osType != null) {
          osDistribution[data.osType!] =
              (osDistribution[data.osType!] ?? 0) + 1;
        }
      }

      final Map<String, int> permissionFrequency = {};
      for (var data in userData) {
        for (var permission in data.permissionsAsked) {
          permissionFrequency[permission] =
              (permissionFrequency[permission] ?? 0) + 1;
        }
      }

      final Map<String, int> dataCollectionPatterns = {};
      for (var data in userData) {
        for (var dataType in data.dataLinked) {
          dataCollectionPatterns[dataType] =
              (dataCollectionPatterns[dataType] ?? 0) + 1;
        }
      }

      return MetricsData(
        totalSubmissions: totalSubmissions,
        averageReviewScore: averageReviewScore,
        appDistribution: appDistribution,
        deviceDistribution: deviceDistribution,
        osDistribution: osDistribution,
        permissionFrequency: permissionFrequency,
        dataCollectionPatterns: dataCollectionPatterns,
      );
    } catch (e) {
      throw Exception('Failed to calculate metrics: $e');
    }
  }

  // ================================================
  // ADMIN METHODS
  // ================================================

  Future<Map<String, dynamic>> getAdminSystemStats() async {
    try {
      final response = await _supabase
          .from('admin_system_stats')
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch system stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllSubmissions({
    String? searchQuery,
    String? filterApp,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      final response = await _supabase
          .from('dnl_experiment_data')
          .select()
          .order(sortBy, ascending: ascending);

      List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(
        response,
      );

      // Apply search filter in-memory
      if (searchQuery != null && searchQuery.isNotEmpty) {
        results = results.where((item) {
          final appName = (item['app_name'] as String?)?.toLowerCase() ?? '';
          final email = (item['email'] as String?)?.toLowerCase() ?? '';
          final name = (item['name'] as String?)?.toLowerCase() ?? '';
          final obs = (item['observations'] as String?)?.toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();
          return appName.contains(query) ||
              email.contains(query) ||
              name.contains(query) ||
              obs.contains(query);
        }).toList();
      }

      // Apply app filter
      if (filterApp != null &&
          filterApp.isNotEmpty &&
          filterApp != 'All Apps') {
        results = results
            .where((item) => item['app_name'] == filterApp)
            .toList();
      }

      return results;
    } catch (e) {
      throw Exception('Failed to fetch all submissions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase.from('admin_user_stats').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAppStats() async {
    try {
      final response = await _supabase.from('admin_app_stats').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch app stats: $e');
    }
  }

  Future<void> deleteSubmissionAsAdmin(String id) async {
    try {
      await _supabase.from('dnl_experiment_data').delete().match({'id': id});
    } catch (e) {
      throw Exception('Failed to delete submission: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSubmissionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('dnl_experiment_data')
          .select()
          .order('created_at', ascending: false);

      // Filter by date in-memory
      List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(
        response,
      );
      results = results.where((item) {
        final createdAt = DateTime.parse(item['created_at'] as String);
        return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
      }).toList();

      return results;
    } catch (e) {
      throw Exception('Failed to fetch submissions by date: $e');
    }
  }

  Future<List<Map<String, dynamic>>> exportAllData() async {
    try {
      final response = await _supabase
          .from('dnl_experiment_data')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<bool> isAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final role = user.userMetadata?['role'];
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }
}

// MetricsData class
class MetricsData {
  final int totalSubmissions;
  final double averageReviewScore;
  final Map<String, int> appDistribution;
  final Map<String, int> deviceDistribution;
  final Map<String, int> osDistribution;
  final Map<String, int> permissionFrequency;
  final Map<String, int> dataCollectionPatterns;

  MetricsData({
    required this.totalSubmissions,
    required this.averageReviewScore,
    required this.appDistribution,
    required this.deviceDistribution,
    required this.osDistribution,
    required this.permissionFrequency,
    required this.dataCollectionPatterns,
  });
}
