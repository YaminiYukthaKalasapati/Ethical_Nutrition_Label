// This is an EXAMPLE of how your profile_screen.dart should look
// Adjust based on your actual implementation

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DataService _dataService = DataService();
  int _totalSubmissions = 0; // ADD THIS
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData(); // CHANGE FROM _loadUserProfile to _loadData
  }

  // RENAME THIS METHOD
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final submissions = await _dataService.getUserData();
      if (mounted) {
        setState(() {
          _totalSubmissions = submissions.length;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData, // CHANGE FROM _loadUserProfile to _loadData
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Account Information',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.person),
                                  title: const Text('Name'),
                                  subtitle: Text(
                                    user?.userMetadata?['full_name'] ?? 'N/A',
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.email),
                                  title: const Text('Email'),
                                  subtitle: Text(user?.email ?? 'N/A'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.assignment),
                                  title: const Text('Total Submissions'),
                                  subtitle: Text('$_totalSubmissions'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
