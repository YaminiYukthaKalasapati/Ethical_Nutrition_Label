import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/experiment_data.dart';
import '../models/metrics_data.dart';

class DataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================================================
  // USER DATA SUBMISSION
  // ================================================

  /// Submit experiment data
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

  /// Get all data for current user
  Future<List<ExperimentData>> getUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('dnl_experiment_data')
          .select()
          .eq('email', user.email!)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ExperimentData.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  /// Get user data with search and filter
  Future<List<ExperimentData>> getUserDataFiltered({
    String? searchQuery,
    String? filterApp,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      var query = _supabase
          .from('dnl_experiment_data')
          .select()
          .eq('email', user.email!)
          .order('created_at', ascending: false);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'app_name.ilike.%$searchQuery%,observations.ilike.%$searchQuery%',
        );
      }

      if (filterApp != null &&
          filterApp.isNotEmpty &&
          filterApp != 'All Apps') {
        query = query.eq('app_name', filterApp);
      }

      final response = await query;

      return (response as List)
          .map((item) => ExperimentData.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch filtered data: $e');
    }
  }

  /// Get list of apps user has submitted
  Future<List<String>> getUserApps() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('dnl_experiment_data')
          .select('app_name')
          .eq('email', user.email!)
          .not('app_name', 'is', null);

      final apps = (response as List)
          .map((item) => item['app_name'] as String)
          .toSet()
          .toList();

      apps.sort();
      return apps;
    } catch (e) {
      throw Exception('Failed to fetch user apps: $e');
    }
  }

  /// Delete user submission
  Future<void> deleteSubmission(String id) async {
    try {
      await _supabase.from('dnl_experiment_data').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete submission: $e');
    }
  }

  // ================================================
  // METRICS CALCULATION
  // ================================================

  /// Calculate metrics for current user
  Future<MetricsData> calculateMetrics() async {
    try {
      final userData = await getUserData();

      if (userData.isEmpty) {
        return MetricsData(
          totalSubmissions: 0,
          averageReviewScore: 0,
          appDistribution: {},
          deviceDistribution: {},
          osDistribution: {},
          permissionFrequency: {},
          dataCollectionPatterns: {},
        );
      }

      // Calculate total submissions
      final totalSubmissions = userData.length;

      // Calculate average review score
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
      final averageReviewScore = scoreCount > 0 ? totalScore / scoreCount : 0;

      // Calculate app distribution
      final Map<String, int> appDistribution = {};
      for (var data in userData) {
        if (data.appName != null) {
          appDistribution[data.appName!] =
              (appDistribution[data.appName!] ?? 0) + 1;
        }
      }

      // Calculate device distribution
      final Map<String, int> deviceDistribution = {};
      for (var data in userData) {
        if (data.deviceModel != null) {
          deviceDistribution[data.deviceModel!] =
              (deviceDistribution[data.deviceModel!] ?? 0) + 1;
        }
      }

      // Calculate OS distribution
      final Map<String, int> osDistribution = {};
      for (var data in userData) {
        if (data.osType != null) {
          osDistribution[data.osType!] =
              (osDistribution[data.osType!] ?? 0) + 1;
        }
      }

      // Calculate permission frequency
      final Map<String, int> permissionFrequency = {};
      for (var data in userData) {
        for (var permission in data.permissionsAsked) {
          permissionFrequency[permission] =
              (permissionFrequency[permission] ?? 0) + 1;
        }
      }

      // Calculate data collection patterns
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

  /// Get system-wide statistics (admin only)
  Future<Map<String, dynamic>> getAdminSystemStats() async {
    try {
      final response = await _supabase
          .from('admin_system_stats')
          .select()
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch system stats: $e');
    }
  }

  /// Get all submissions from all users (admin only)
  Future<List<Map<String, dynamic>>> getAllSubmissions({
    String? searchQuery,
    String? filterApp,
    String? sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('dnl_experiment_data')
          .select()
          .order(sortBy, ascending: ascending);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'app_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%,name.ilike.%$searchQuery%,observations.ilike.%$searchQuery%',
        );
      }

      if (filterApp != null &&
          filterApp.isNotEmpty &&
          filterApp != 'All Apps') {
        query = query.eq('app_name', filterApp);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch all submissions: $e');
    }
  }

  /// Get all users statistics (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase.from('admin_user_stats').select();
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  /// Get app statistics for DNL generation (admin only)
  Future<List<Map<String, dynamic>>> getAppStats() async {
    try {
      final response = await _supabase.from('admin_app_stats').select();
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch app stats: $e');
    }
  }

  /// Delete any submission (admin only)
  Future<void> deleteSubmissionAsAdmin(String id) async {
    try {
      await _supabase.from('dnl_experiment_data').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete submission: $e');
    }
  }

  /// Get submission count by date range (admin only)
  Future<List<Map<String, dynamic>>> getSubmissionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('dnl_experiment_data')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch submissions by date: $e');
    }
  }

  /// Export all data as CSV-ready format (admin only)
  Future<List<Map<String, dynamic>>> exportAllData() async {
    try {
      final response = await _supabase
          .from('dnl_experiment_data')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Check if current user is admin
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
