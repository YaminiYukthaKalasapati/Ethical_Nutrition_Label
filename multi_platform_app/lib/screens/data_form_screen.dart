import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/device_info_service.dart';
import '../models/experiment_data.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/multi_select_chips.dart';
import '../widgets/loading_button.dart';

class DataFormScreen extends StatefulWidget {
  const DataFormScreen({super.key});

  @override
  State<DataFormScreen> createState() => _DataFormScreenState();
}

class _DataFormScreenState extends State<DataFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dataService = DataService();
  final _deviceInfoService = DeviceInfoService();

  // Controllers
  final _deviceMakeController = TextEditingController();
  final _reviewScoreController = TextEditingController();
  final _ageRatingController = TextEditingController();
  final _rankingController = TextEditingController();
  final _installSizeController = TextEditingController();
  final _observationsController = TextEditingController();

  // Form values
  String? _deviceModel;
  String _deviceState = "Lab";
  String _metricsToolInstalled = "Yes - Metrics are shown";
  String? _appName;

  // Multi-select values
  final Set<String> _dataLinked = {};
  final Set<String> _dataNotLinked = {};
  final Set<String> _dataTracked = {};
  final Set<String> _permissionsAsked = {};

  // Auto-populated fields
  String? _email;
  String? _fullName;
  String? _osType;
  String? _batteryLevel;

  // State
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _prepareAutoFields();
  }

  Future<void> _prepareAutoFields() async {
    final user = _authService.currentUser;
    _email = user?.email ?? '';
    _fullName = user?.userMetadata?['full_name'] ?? '';
    _batteryLevel = await _deviceInfoService.getBatteryLevel();
    _osType = _deviceInfoService.getOSType();

    setState(() {
      _loading = false;
    });
  }

  void _toggleMultiSelect(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    // Confirm submission
    final confirmed = await _showConfirmDialog();
    if (confirmed != true) return;

    setState(() => _submitting = true);

    try {
      final data = ExperimentData(
        email: _email!,
        name: _fullName!,
        battery: _batteryLevel,
        osType: _osType,
        deviceModel: _deviceModel,
        deviceMake: _deviceMakeController.text.trim(),
        deviceState: _deviceState,
        metricsToolInstalled: _metricsToolInstalled,
        appName: _appName,
        reviewScore: _reviewScoreController.text.trim(),
        ageRating: _ageRatingController.text.trim(),
        ranking: _rankingController.text.trim(),
        installSize: _installSizeController.text.trim(),
        dataLinked: _dataLinked.toList(),
        dataNotLinked: _dataNotLinked.toList(),
        dataTracked: _dataTracked.toList(),
        permissionsAsked: _permissionsAsked.toList(),
        observations: _observationsController.text.trim(),
      );

      await _dataService.submitData(data);

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to submit data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text(
          'Are you sure you want to submit this data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            const SizedBox(width: 12),
            const Text('Success!'),
          ],
        ),
        content: const Text('Your data has been submitted successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('Submit Another'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _deviceMakeController.clear();
      _reviewScoreController.clear();
      _ageRatingController.clear();
      _rankingController.clear();
      _installSizeController.clear();
      _observationsController.clear();
      _deviceModel = null;
      _deviceState = "Lab";
      _metricsToolInstalled = "Yes - Metrics are shown";
      _appName = null;
      _dataLinked.clear();
      _dataNotLinked.clear();
      _dataTracked.clear();
      _permissionsAsked.clear();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Form Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Fill in the form with accurate information about the app you\'re testing.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Device information is auto-populated'),
              Text('• Select the app from the dropdown'),
              Text('• Choose all applicable data types and permissions'),
              Text('• Add observations for additional notes'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deviceMakeController.dispose();
    _reviewScoreController.dispose();
    _ageRatingController.dispose();
    _rankingController.dispose();
    _installSizeController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Collection Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: AppConstants.largePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Auto-Generated Information'),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Device Information'),
                  _buildDeviceSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Application Details'),
                  _buildAppSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Data Collection'),
                  _buildDataCollectionSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Permissions'),
                  _buildPermissionsSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Additional Notes'),
                  _buildNotesSection(),
                  const SizedBox(height: 32),
                  LoadingButton(
                    onPressed: _submit,
                    text: 'Submit Data',
                    isLoading: _submitting,
                    icon: Icons.send,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade900,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.email, 'Email', _email ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, 'Name', _fullName ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone_android, 'OS Type', _osType ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.battery_full,
              'Battery',
              _batteryLevel ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  Widget _buildDeviceSection() {
    return Column(
      children: [
        CustomDropdown(
          labelText: 'Device Model',
          value: _deviceModel,
          items: AppConstants.deviceModels,
          onChanged: (value) => setState(() => _deviceModel = value),
          prefixIcon: Icons.phone_android,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _deviceMakeController,
          labelText: 'Device Make',
          hintText: 'e.g., Apple, Samsung, Google',
          prefixIcon: Icons.phonelink,
        ),
        const SizedBox(height: 16),
        CustomDropdown(
          labelText: 'Device State',
          value: _deviceState,
          items: const ['Lab', 'Personal'],
          onChanged: (value) => setState(() => _deviceState = value!),
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        CustomDropdown(
          labelText: 'Metrics Tool Installed',
          value: _metricsToolInstalled,
          items: const [
            'Yes - Metrics are shown',
            'No - Metrics are not shown',
          ],
          onChanged: (value) => setState(() => _metricsToolInstalled = value!),
          prefixIcon: Icons.analytics_outlined,
        ),
      ],
    );
  }

  Widget _buildAppSection() {
    return Column(
      children: [
        CustomDropdown(
          labelText: 'App Name *',
          value: _appName,
          items: AppConstants.appOptions,
          onChanged: (value) => setState(() => _appName = value),
          prefixIcon: Icons.apps,
          validator: (value) => value == null ? 'Please select an app' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _reviewScoreController,
          labelText: 'Review Score (0-5)',
          hintText: 'e.g., 4.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.star_outline,
          validator: Validators.validateRating,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _ageRatingController,
          labelText: 'Age Rating',
          hintText: 'e.g., 4+, 12+, 17+',
          prefixIcon: Icons.family_restroom,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _rankingController,
          labelText: 'App Ranking',
          hintText: 'e.g., #1 in Health & Fitness',
          prefixIcon: Icons.trending_up,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _installSizeController,
          labelText: 'Install Size',
          hintText: 'e.g., 50 MB',
          prefixIcon: Icons.storage,
        ),
      ],
    );
  }

  Widget _buildDataCollectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MultiSelectChips(
          title: 'Data Collected Linked to You',
          options: AppConstants.dataLinkedOptions,
          selectedValues: _dataLinked,
          onToggle: (value) => _toggleMultiSelect(_dataLinked, value),
        ),
        const SizedBox(height: 20),
        MultiSelectChips(
          title: 'Data Collected Not Linked to You',
          options: AppConstants.dataNotLinkedOptions,
          selectedValues: _dataNotLinked,
          onToggle: (value) => _toggleMultiSelect(_dataNotLinked, value),
        ),
        const SizedBox(height: 20),
        MultiSelectChips(
          title: 'Data Used to Track You',
          options: AppConstants.dataTrackedOptions,
          selectedValues: _dataTracked,
          onToggle: (value) => _toggleMultiSelect(_dataTracked, value),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return MultiSelectChips(
      title: 'Permissions Requested',
      options: AppConstants.permissionsOptions,
      selectedValues: _permissionsAsked,
      onToggle: (value) => _toggleMultiSelect(_permissionsAsked, value),
    );
  }

  Widget _buildNotesSection() {
    return CustomTextField(
      controller: _observationsController,
      labelText: 'Observations',
      hintText: 'Add any additional notes or observations...',
      maxLines: 5,
      prefixIcon: Icons.note_outlined,
    );
  }
}
