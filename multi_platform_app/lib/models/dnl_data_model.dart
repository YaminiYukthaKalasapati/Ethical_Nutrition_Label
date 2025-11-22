class DNLData {
  final String id;
  final String appName;
  final String version;
  final String? ageRating;
  final DateTime? evaluatedOn;
  final List<String> platform; // ['Android', 'iOS']

  // Average Daily Interruptions
  final int notifications;
  final int popups;
  final int emailsSMS;

  // Privacy - Access to
  final String camera;
  final String microphone;
  final String photos;
  final String location;
  final String contacts;
  final String storage;
  final String biometrics;
  final String healthData;

  // Privacy - Data Handling and Sharing
  final String dataCollection;
  final String dataTransmissionFreq;
  final String thirdPartySharing;
  final String updateAlerts;

  // User Rights
  final String adsOptOut;
  final String accountDeletion;
  final String userDataExport;

  // Monetization
  final String usageCost;
  final String recurringPayments;
  final String inAppPurchases;

  // Device Resources
  final String batteryImpact;
  final String storageFootprint;
  final String internetRequirement;

  // Additional metadata
  final String submittedBy;
  final DateTime submittedAt;
  final String status; // 'pending', 'approved', 'rejected'

  DNLData({
    required this.id,
    required this.appName,
    required this.version,
    this.ageRating,
    this.evaluatedOn,
    required this.platform,
    required this.notifications,
    required this.popups,
    required this.emailsSMS,
    required this.camera,
    required this.microphone,
    required this.photos,
    required this.location,
    required this.contacts,
    required this.storage,
    required this.biometrics,
    required this.healthData,
    required this.dataCollection,
    required this.dataTransmissionFreq,
    required this.thirdPartySharing,
    required this.updateAlerts,
    required this.adsOptOut,
    required this.accountDeletion,
    required this.userDataExport,
    required this.usageCost,
    required this.recurringPayments,
    required this.inAppPurchases,
    required this.batteryImpact,
    required this.storageFootprint,
    required this.internetRequirement,
    required this.submittedBy,
    required this.submittedAt,
    required this.status,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'version': version,
      'ageRating': ageRating,
      'evaluatedOn': evaluatedOn,
      'platform': platform,
      'notifications': notifications,
      'popups': popups,
      'emailsSMS': emailsSMS,
      'camera': camera,
      'microphone': microphone,
      'photos': photos,
      'location': location,
      'contacts': contacts,
      'storage': storage,
      'biometrics': biometrics,
      'healthData': healthData,
      'dataCollection': dataCollection,
      'dataTransmissionFreq': dataTransmissionFreq,
      'thirdPartySharing': thirdPartySharing,
      'updateAlerts': updateAlerts,
      'adsOptOut': adsOptOut,
      'accountDeletion': accountDeletion,
      'userDataExport': userDataExport,
      'usageCost': usageCost,
      'recurringPayments': recurringPayments,
      'inAppPurchases': inAppPurchases,
      'batteryImpact': batteryImpact,
      'storageFootprint': storageFootprint,
      'internetRequirement': internetRequirement,
      'submittedBy': submittedBy,
      'submittedAt': submittedAt,
      'status': status,
    };
  }

  // Create from Firestore document
  factory DNLData.fromMap(Map<String, dynamic> map, String id) {
    return DNLData(
      id: id,
      appName: map['appName'] ?? '',
      version: map['version'] ?? '',
      ageRating: map['ageRating'],
      evaluatedOn: map['evaluatedOn']?.toDate(),
      platform: List<String>.from(map['platform'] ?? []),
      notifications: map['notifications'] ?? 0,
      popups: map['popups'] ?? 0,
      emailsSMS: map['emailsSMS'] ?? 0,
      camera: map['camera'] ?? 'Not Applicable',
      microphone: map['microphone'] ?? 'Not Applicable',
      photos: map['photos'] ?? 'Not Applicable',
      location: map['location'] ?? 'Not Applicable',
      contacts: map['contacts'] ?? 'Not Applicable',
      storage: map['storage'] ?? 'Not Applicable',
      biometrics: map['biometrics'] ?? 'Not Applicable',
      healthData: map['healthData'] ?? 'Not Applicable',
      dataCollection: map['dataCollection'] ?? 'No',
      dataTransmissionFreq: map['dataTransmissionFreq'] ?? 'Never',
      thirdPartySharing: map['thirdPartySharing'] ?? 'No',
      updateAlerts: map['updateAlerts'] ?? 'No',
      adsOptOut: map['adsOptOut'] ?? 'Not Allowed',
      accountDeletion: map['accountDeletion'] ?? 'Allowed',
      userDataExport: map['userDataExport'] ?? 'Allowed',
      usageCost: map['usageCost'] ?? 'Free',
      recurringPayments: map['recurringPayments'] ?? 'No',
      inAppPurchases: map['inAppPurchases'] ?? 'No',
      batteryImpact: map['batteryImpact'] ?? '0',
      storageFootprint: map['storageFootprint'] ?? '0',
      internetRequirement: map['internetRequirement'] ?? 'No',
      submittedBy: map['submittedBy'] ?? '',
      submittedAt: map['submittedAt']?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  // Calculate total interruptions
  int get totalInterruptions => notifications + popups + emailsSMS;

  // Create a copy with updated fields
  DNLData copyWith({
    String? id,
    String? appName,
    String? version,
    String? ageRating,
    DateTime? evaluatedOn,
    List<String>? platform,
    int? notifications,
    int? popups,
    int? emailsSMS,
    String? camera,
    String? microphone,
    String? photos,
    String? location,
    String? contacts,
    String? storage,
    String? biometrics,
    String? healthData,
    String? dataCollection,
    String? dataTransmissionFreq,
    String? thirdPartySharing,
    String? updateAlerts,
    String? adsOptOut,
    String? accountDeletion,
    String? userDataExport,
    String? usageCost,
    String? recurringPayments,
    String? inAppPurchases,
    String? batteryImpact,
    String? storageFootprint,
    String? internetRequirement,
    String? submittedBy,
    DateTime? submittedAt,
    String? status,
  }) {
    return DNLData(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      version: version ?? this.version,
      ageRating: ageRating ?? this.ageRating,
      evaluatedOn: evaluatedOn ?? this.evaluatedOn,
      platform: platform ?? this.platform,
      notifications: notifications ?? this.notifications,
      popups: popups ?? this.popups,
      emailsSMS: emailsSMS ?? this.emailsSMS,
      camera: camera ?? this.camera,
      microphone: microphone ?? this.microphone,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      contacts: contacts ?? this.contacts,
      storage: storage ?? this.storage,
      biometrics: biometrics ?? this.biometrics,
      healthData: healthData ?? this.healthData,
      dataCollection: dataCollection ?? this.dataCollection,
      dataTransmissionFreq: dataTransmissionFreq ?? this.dataTransmissionFreq,
      thirdPartySharing: thirdPartySharing ?? this.thirdPartySharing,
      updateAlerts: updateAlerts ?? this.updateAlerts,
      adsOptOut: adsOptOut ?? this.adsOptOut,
      accountDeletion: accountDeletion ?? this.accountDeletion,
      userDataExport: userDataExport ?? this.userDataExport,
      usageCost: usageCost ?? this.usageCost,
      recurringPayments: recurringPayments ?? this.recurringPayments,
      inAppPurchases: inAppPurchases ?? this.inAppPurchases,
      batteryImpact: batteryImpact ?? this.batteryImpact,
      storageFootprint: storageFootprint ?? this.storageFootprint,
      internetRequirement: internetRequirement ?? this.internetRequirement,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
    );
  }
}
