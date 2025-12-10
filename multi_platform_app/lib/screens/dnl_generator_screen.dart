import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/dnl_data_aggregator.dart';
import 'dnl_label_display_screen.dart';

class DNLGeneratorScreen extends StatefulWidget {
  const DNLGeneratorScreen({super.key});

  @override
  State<DNLGeneratorScreen> createState() => _DNLGeneratorScreenState();
}

class _DNLGeneratorScreenState extends State<DNLGeneratorScreen>
    with TickerProviderStateMixin {
  final DNLDataAggregator _aggregator = DNLDataAggregator();
  late AnimationController _animationController;
  late AnimationController _pulseController;
  List<Map<String, dynamic>> _apps = [];
  String? _selectedApp;
  bool _isLoading = true;
  Map<String, dynamic> _appStats = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _checkAdminAccess();
    _loadApps();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    final isAdmin = user?.userMetadata?['role'] == 'admin';

    if (!isAdmin && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Access denied: Admin privileges required'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final apps = await _aggregator.getAvailableApps();

      if (mounted) {
        setState(() {
          _apps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Error loading apps: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateLabel() async {
    if (_selectedApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select an app first'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Add loading animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
              ),
              SizedBox(height: 16),
              Text('Generating DNL Label...'),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(Duration(milliseconds: 500));
    Navigator.pop(context);

    // Navigate to label display
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DNLLabelDisplayScreen(appName: _selectedApp!),
        transitionDuration: Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: Offset(0.1, 0), end: Offset.zero)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00796B), Color(0xFF00BFA5), Color(0xFF4DD0E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Loading available apps...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          SizedBox(height: 24),

                          // Header Card with gradient
                          _buildHeaderCard()
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .slideY(begin: 0.2, end: 0),

                          SizedBox(height: 24),

                          // App Selection Section
                          _buildAppSelection()
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 800.ms)
                              .slideX(begin: -0.2, end: 0),

                          SizedBox(height: 24),

                          // Generate Button
                          if (_selectedApp != null)
                            _buildGenerateButton()
                                .animate()
                                .fadeIn(delay: 500.ms, duration: 600.ms)
                                .scale(
                                  begin: Offset(0.9, 0.9),
                                  end: Offset(1, 1),
                                ),

                          SizedBox(height: 24),

                          // Available Apps List
                          _buildAppsGrid().animate().fadeIn(
                            delay: 700.ms,
                            duration: 800.ms,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DNL Generator',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Digital Nutrition Labels',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.refresh, color: Colors.white),
              ),
              onPressed: _loadApps,
            ),
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF00796B)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.label, size: 40, color: Colors.white),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            'Digital Nutrition Label Generator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00796B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Generate privacy nutrition labels for apps based on user submissions',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSelection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF00BFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.apps, color: Color(0xFF00BFA5)),
              ),
              SizedBox(width: 12),
              Text(
                'Step 1: Select an App',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedApp,
            decoration: InputDecoration(
              labelText: 'Select App',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.apps, color: Color(0xFF00796B)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: _apps.map((app) {
              final appName = app['app_name'] as String;
              final submissionCount = app['total_submissions'] ?? 0;
              return DropdownMenuItem(
                value: appName,
                child: Text('$appName ($submissionCount submissions)'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedApp = value;
                _appStats = _apps.firstWhere(
                  (app) => app['app_name'] == value,
                  orElse: () => {},
                );
              });
            },
          ),
          if (_selectedApp != null) ...[
            SizedBox(height: 16),
            _buildAppPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00BFA5).withOpacity(0.1),
            Color(0xFF00796B).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF00BFA5).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Color(0xFF00796B), size: 20),
              SizedBox(width: 8),
              Text(
                'Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPreviewStat(
                Icons.file_copy,
                _appStats['total_submissions']?.toString() ?? '0',
                'Submissions',
              ),
              _buildPreviewStat(
                Icons.people,
                _appStats['unique_testers']?.toString() ?? '0',
                'Testers',
              ),
              _buildPreviewStat(
                Icons.star,
                _appStats['avg_review_score']?.toString() ?? 'N/A',
                'Avg Score',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPreviewStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF00BFA5), size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00796B),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00796B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00BFA5).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _generateLabel,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Generate DNL Label',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppsGrid() {
    if (_apps.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 60, color: Colors.grey.shade300),
              SizedBox(height: 16),
              Text(
                'No apps found',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              Text(
                'Submit some data first!',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Color(0xFF00796B)),
              SizedBox(width: 12),
              Text(
                'Available Apps',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF00BFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_apps.length} Apps',
                  style: TextStyle(
                    color: Color(0xFF00BFA5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._apps.asMap().entries.map(
            (entry) => _buildAppCard(entry.value, entry.key),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(Map<String, dynamic> app, int index) {
    final appName = app['app_name'] as String;
    final submissionCount = app['total_submissions'] ?? 0;
    final uniqueTesters = app['unique_testers'] ?? 0;
    final isSelected = _selectedApp == appName;

    return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      Color(0xFF00BFA5).withOpacity(0.1),
                      Color(0xFF00796B).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade50,
            border: Border.all(
              color: isSelected ? Color(0xFF00BFA5) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedApp = appName;
                  _appStats = app;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00BFA5), Color(0xFF00796B)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          appName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.file_copy,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '$submissionCount submissions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(
                                Icons.people,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '$uniqueTesters testers',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: Color(0xFF00BFA5))
                    else
                      Icon(Icons.circle_outlined, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 * index),
          duration: 400.ms,
        )
        .slideX(begin: 0.1, end: 0);
  }
}
