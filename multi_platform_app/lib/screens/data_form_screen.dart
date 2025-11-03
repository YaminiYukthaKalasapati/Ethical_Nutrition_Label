import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

class DataFormScreen extends StatefulWidget {
  const DataFormScreen({Key? key}) : super(key: key);

  @override
  State<DataFormScreen> createState() => _DataFormScreenState();
}

class _DataFormScreenState extends State<DataFormScreen> {
  final deviceMakeController = TextEditingController();
  final reviewScoreController = TextEditingController();
  final ageRatingController = TextEditingController();
  final rankingController = TextEditingController();
  final installSizeController = TextEditingController();
  final observationsController = TextEditingController();

  String? deviceModel;
  String deviceState = "Lab";
  String metricsToolInstalled = "Yes - Metrics are shown";
  String? appName;

  final deviceModelOptions = [
    "iPhone 13",
    "iPhone 14",
    "Pixel 7",
    "Samsung S22",
    "Macbook Pro",
    "Dell XPS",
    "Not Listed",
  ];

  final appOptions = ["Headspace", "Calm", "Woebot", "Moodnotes", "Other"];

  final dataLinkedOptions = [
    "Usage Data",
    "Purchases",
    "Identifiers",
    "Location",
    "Contact Info",
    "User Id",
  ];

  final dataNotLinkedOptions = ["Diagnostics", "Contact Info", "Other"];

  final dataTrackedOptions = ["Purchases", "Identifiers", "Other"];

  final permissionsOptions = [
    "Location",
    "Camera",
    "Microphone",
    "Contacts",
    "Storage",
    "Calendar",
    "Files",
    "Photos",
    "Videos",
    "Notifications",
    "Health",
    "Financial",
    "User Id",
  ];

  Set<String> dataLinked = {};
  Set<String> dataNotLinked = {};
  Set<String> dataTracked = {};
  Set<String> permissionsAsked = {};

  String? email;
  String? fullName;
  String? osType;
  String? batteryLevel;
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _prepareAutoFields();
  }

  Future<void> _prepareAutoFields() async {
    final user = Supabase.instance.client.auth.currentUser;
    email = user?.email ?? '';
    fullName = user?.userMetadata?['full_name'] ?? '';

    Battery battery = Battery();
    batteryLevel = "${await battery.batteryLevel}%";

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        osType = 'Android';
        break;
      case TargetPlatform.iOS:
        osType = 'iOS';
        break;
      case TargetPlatform.macOS:
        osType = 'macOS';
        break;
      case TargetPlatform.windows:
        osType = 'Windows';
        break;
      case TargetPlatform.linux:
        osType = 'Linux';
        break;
      default:
        osType = 'Unknown';
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> _submit() async {
    setState(() {
      submitting = true;
    });

    final data = {
      'email': email,
      'name': fullName,
      'battery': batteryLevel,
      'os_type': osType,
      'device_model': deviceModel,
      'device_make': deviceMakeController.text,
      'device_state': deviceState,
      'metrics_tool_installed': metricsToolInstalled,
      'app_name': appName,
      'review_score': reviewScoreController.text,
      'age_rating': ageRatingController.text,
      'ranking': rankingController.text,
      'install_size': installSizeController.text,
      'data_linked': dataLinked.toList(),
      'data_not_linked': dataNotLinked.toList(),
      'data_tracked': dataTracked.toList(),
      'permissions_asked': permissionsAsked.toList(),
      'observations': observationsController.text,
    };

    try {
      await Supabase.instance.client.from('dnl_experiment_data').insert(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data submitted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit data: $e')));
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    deviceMakeController.dispose();
    reviewScoreController.dispose();
    ageRatingController.dispose();
    rankingController.dispose();
    installSizeController.dispose();
    observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Data Collection Form')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email: $email"),
                Text("Full Name: $fullName"),
                Text("OS Type: $osType"),
                Text("Battery Level: $batteryLevel"),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Device Model'),
                  value: deviceModel,
                  items: deviceModelOptions
                      .map(
                        (model) =>
                            DropdownMenuItem(value: model, child: Text(model)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => deviceModel = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deviceMakeController,
                  decoration: const InputDecoration(labelText: 'Device Make'),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Device State'),
                  value: deviceState,
                  items: ['Lab', 'Personal']
                      .map(
                        (state) =>
                            DropdownMenuItem(value: state, child: Text(state)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => deviceState = value!),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Metrics Tool Installed',
                  ),
                  value: metricsToolInstalled,
                  items:
                      ['Yes - Metrics are shown', 'No - Metrics are not shown']
                          .map(
                            (tool) => DropdownMenuItem(
                              value: tool,
                              child: Text(tool),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setState(() => metricsToolInstalled = value!),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'App Name'),
                  value: appName,
                  items: appOptions
                      .map(
                        (app) => DropdownMenuItem(value: app, child: Text(app)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => appName = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reviewScoreController,
                  decoration: const InputDecoration(labelText: 'Review Score'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageRatingController,
                  decoration: const InputDecoration(labelText: 'Age Rating'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rankingController,
                  decoration: const InputDecoration(labelText: 'Ranking'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: installSizeController,
                  decoration: const InputDecoration(labelText: 'Install Size'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Data Collected Linked',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Wrap(
                  children: dataLinkedOptions.map((option) {
                    final selected = dataLinked.contains(option);
                    return FilterChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (bool selectedValue) {
                        setState(() {
                          if (selectedValue) {
                            dataLinked.add(option);
                          } else {
                            dataLinked.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Data Collected Not Linked',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Wrap(
                  children: dataNotLinkedOptions.map((option) {
                    final selected = dataNotLinked.contains(option);
                    return FilterChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (bool selectedValue) {
                        setState(() {
                          if (selectedValue) {
                            dataNotLinked.add(option);
                          } else {
                            dataNotLinked.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Data Tracked',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Wrap(
                  children: dataTrackedOptions.map((option) {
                    final selected = dataTracked.contains(option);
                    return FilterChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (bool selectedValue) {
                        setState(() {
                          if (selectedValue) {
                            dataTracked.add(option);
                          } else {
                            dataTracked.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Permissions Asked',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Wrap(
                  children: permissionsOptions.map((option) {
                    final selected = permissionsAsked.contains(option);
                    return FilterChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: (bool selectedValue) {
                        setState(() {
                          if (selectedValue) {
                            permissionsAsked.add(option);
                          } else {
                            permissionsAsked.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: observationsController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Observations'),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
