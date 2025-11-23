import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  late AnimationController _animationController;
  int _totalSubmissions = 0;
  bool _isLoading = true;

  // Add more stats for dashboard
  int _appsTestd = 0;
  double _avgReviewScore = 0.0;
  Map<String, dynamic> _recentActivity = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final submissions = await _dataService.getUserData();

      // Calculate additional metrics
      final uniqueApps = submissions.map((s) => s.appName).toSet().length;
      final totalScore = submissions.fold(0.0, (sum, item) {
        final score = double.tryParse(item.reviewScore ?? '0') ?? 0.0;
        return sum + score;
      });
      final avgScore = submissions.isEmpty
          ? 0.0
          : totalScore / submissions.length;

      if (mounted) {
        setState(() {
          _totalSubmissions = submissions.length;
          _appsTestd = uniqueApps;
          _avgReviewScore = avgScore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'User';
    final isAdmin = user?.userMetadata?['role'] == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE0F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with profile and notifications
                      _buildHeader(userName),

                      SizedBox(height: 24),

                      // Welcome Card with gradient
                      _buildWelcomeCard(userName, isAdmin)
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .slideY(begin: 0.2, end: 0),

                      SizedBox(height: 24),

                      // Stats Grid
                      if (!_isLoading)
                        _buildStatsGrid().animate().fadeIn(
                          delay: 300.ms,
                          duration: 800.ms,
                        ),

                      SizedBox(height: 24),

                      // Quick Actions Section
                      Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00796B),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideX(begin: -0.2, end: 0),

                      SizedBox(height: 16),

                      // Action Cards with staggered animations
                      _buildActionCard(
                        'New Data Entry',
                        'Submit new app data',
                        Icons.add_circle,
                        LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                        ),
                        () => Navigator.pushNamed(context, '/data-form'),
                        0,
                      ),

                      SizedBox(height: 16),

                      _buildActionCard(
                        'View Metrics',
                        'See your analytics dashboard',
                        Icons.analytics,
                        LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                        ),
                        () => Navigator.pushNamed(context, '/metrics'),
                        1,
                      ),

                      SizedBox(height: 16),

                      _buildActionCard(
                        'View History',
                        'Browse all your submissions',
                        Icons.history,
                        LinearGradient(
                          colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
                        ),
                        () => Navigator.pushNamed(context, '/history'),
                        2,
                      ),

                      // Admin Section with special styling
                      if (isAdmin) ...[
                        SizedBox(height: 32),
                        Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.withOpacity(0.1),
                                    Colors.purple.withOpacity(0.5),
                                    Colors.purple.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 900.ms, duration: 600.ms)
                            .scaleX(begin: 0, end: 1),

                        SizedBox(height: 24),

                        Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.purple,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(delay: 1000.ms, duration: 600.ms)
                            .slideX(begin: -0.2, end: 0),

                        SizedBox(height: 16),

                        _buildActionCard(
                          'Admin Dashboard',
                          'View system stats & manage users',
                          Icons.dashboard_customize,
                          LinearGradient(
                            colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
                          ),
                          () => Navigator.pushNamed(context, '/admin'),
                          3,
                        ),
                      ],

                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${_getTimeOfDay()}!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              userName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00796B),
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
                  color: Color(0xFF00796B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF00796B),
                ),
              ),
              onPressed: () {},
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF00796B),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String userName, bool isAdmin) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00796B).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getTimeOfDay()}!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  Icons.file_copy,
                  _totalSubmissions.toString(),
                  'Submissions',
                ),
                _buildMiniStat(
                  Icons.apps,
                  _appsTestd.toString(),
                  'Apps Tested',
                ),
                _buildMiniStat(
                  Icons.star,
                  _avgReviewScore.toStringAsFixed(1),
                  'Avg Score',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1, // FIXED: Changed from 1.3 to 1.1 for more height
      children: [
        _buildStatCard(
          'Total Submissions',
          _totalSubmissions.toString(),
          Icons.file_copy,
          Color(0xFF42A5F5),
        ),
        _buildStatCard(
          'Apps Tested',
          _appsTestd.toString(),
          Icons.apps,
          Color(0xFF66BB6A),
        ),
        _buildStatCard(
          'Avg Score',
          _avgReviewScore.toStringAsFixed(1),
          Icons.star,
          Color(0xFFFFA726),
        ),
        _buildStatCard(
          'Active Days',
          '${DateTime.now().day}',
          Icons.calendar_today,
          Color(0xFFAB47BC),
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
      padding: EdgeInsets.all(12), // FIXED: Reduced from 16 to 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8), // FIXED: Reduced from 12 to 8
          FittedBox(
            // FIXED: Added FittedBox to prevent text overflow
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22, // FIXED: Reduced from 24 to 22
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ), // FIXED: Reduced from 12 to 11
            textAlign: TextAlign.center,
            maxLines: 2, // FIXED: Added maxLines to prevent overflow
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
    int index,
  ) {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors[0].withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 700 + (index * 100)),
          duration: 600.ms,
        )
        .slideX(begin: 0.2, end: 0);
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
