class ExperimentData {
  final String? id;
  final String email;
  final String name;
  final String? battery;
  final String? osType;
  final String? deviceModel;
  final String? deviceMake;
  final String deviceState;
  final String metricsToolInstalled;
  final String? appName;
  final String? reviewScore;
  final String? ageRating;
  final String? ranking;
  final String? installSize;
  final List<String> dataLinked;
  final List<String> dataNotLinked;
  final List<String> dataTracked;
  final List<String> permissionsAsked;
  final String? observations;
  final DateTime? createdAt;

  ExperimentData({
    this.id,
    required this.email,
    required this.name,
    this.battery,
    this.osType,
    this.deviceModel,
    this.deviceMake,
    required this.deviceState,
    required this.metricsToolInstalled,
    this.appName,
    this.reviewScore,
    this.ageRating,
    this.ranking,
    this.installSize,
    this.dataLinked = const [],
    this.dataNotLinked = const [],
    this.dataTracked = const [],
    this.permissionsAsked = const [],
    this.observations,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'battery': battery,
      'os_type': osType,
      'device_model': deviceModel,
      'device_make': deviceMake,
      'device_state': deviceState,
      'metrics_tool_installed': metricsToolInstalled,
      'app_name': appName,
      'review_score': reviewScore,
      'age_rating': ageRating,
      'ranking': ranking,
      'install_size': installSize,
      'data_linked': dataLinked,
      'data_not_linked': dataNotLinked,
      'data_tracked': dataTracked,
      'permissions_asked': permissionsAsked,
      'observations': observations,
    };
  }

  factory ExperimentData.fromJson(Map<String, dynamic> json) {
    return ExperimentData(
      id: json['id']?.toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      battery: json['battery'],
      osType: json['os_type'],
      deviceModel: json['device_model'],
      deviceMake: json['device_make'],
      deviceState: json['device_state'] ?? 'Lab',
      metricsToolInstalled:
          json['metrics_tool_installed'] ?? 'Yes - Metrics are shown',
      appName: json['app_name'],
      reviewScore: json['review_score'],
      ageRating: json['age_rating'],
      ranking: json['ranking'],
      installSize: json['install_size'],
      dataLinked: List<String>.from(json['data_linked'] ?? []),
      dataNotLinked: List<String>.from(json['data_not_linked'] ?? []),
      dataTracked: List<String>.from(json['data_tracked'] ?? []),
      permissionsAsked: List<String>.from(json['permissions_asked'] ?? []),
      observations: json['observations'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  ExperimentData copyWith({
    String? id,
    String? email,
    String? name,
    String? battery,
    String? osType,
    String? deviceModel,
    String? deviceMake,
    String? deviceState,
    String? metricsToolInstalled,
    String? appName,
    String? reviewScore,
    String? ageRating,
    String? ranking,
    String? installSize,
    List<String>? dataLinked,
    List<String>? dataNotLinked,
    List<String>? dataTracked,
    List<String>? permissionsAsked,
    String? observations,
    DateTime? createdAt,
  }) {
    return ExperimentData(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      battery: battery ?? this.battery,
      osType: osType ?? this.osType,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceMake: deviceMake ?? this.deviceMake,
      deviceState: deviceState ?? this.deviceState,
      metricsToolInstalled: metricsToolInstalled ?? this.metricsToolInstalled,
      appName: appName ?? this.appName,
      reviewScore: reviewScore ?? this.reviewScore,
      ageRating: ageRating ?? this.ageRating,
      ranking: ranking ?? this.ranking,
      installSize: installSize ?? this.installSize,
      dataLinked: dataLinked ?? this.dataLinked,
      dataNotLinked: dataNotLinked ?? this.dataNotLinked,
      dataTracked: dataTracked ?? this.dataTracked,
      permissionsAsked: permissionsAsked ?? this.permissionsAsked,
      observations: observations ?? this.observations,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MetricsData {
  final int totalSubmissions;
  final Map<String, int> appDistribution;
  final Map<String, int> deviceDistribution;
  final Map<String, int> osDistribution;
  final double averageReviewScore;
  final Map<String, int> permissionsFrequency;
  final Map<String, int> dataLinkedFrequency;

  MetricsData({
    required this.totalSubmissions,
    required this.appDistribution,
    required this.deviceDistribution,
    required this.osDistribution,
    required this.averageReviewScore,
    required this.permissionsFrequency,
    required this.dataLinkedFrequency,
  });
}
