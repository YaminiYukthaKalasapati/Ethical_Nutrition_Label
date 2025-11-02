import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Platform App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomeScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/form': (context) => const DataFormScreen(),
        '/metrics': (context) => const MetricsScreen(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Login'),
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Sign In'),
              onPressed: () async {
                final email = emailController.text;
                final password = passwordController.text;
                try {
                  final response = await supabase.auth.signInWithPassword(
                    email: email,
                    password: password,
                  );
                  if (!mounted) return;
                  if (response.user != null) {
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login failed')),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
            TextButton(
              child: const Text("Don't have an account? Register here"),
              onPressed: () => Navigator.pushNamed(context, '/register'),
            ),
            TextButton(
              child: const Text('Forgot password?'),
              onPressed: () => Navigator.pushNamed(context, '/reset-password'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool submitting = false;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 20),
            if (submitting) const CircularProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              child: const Text('Sign Up'),
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() {
                        submitting = true;
                        error = null;
                      });
                      final email = emailController.text.trim();
                      final password = passwordController.text;
                      final fullName = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      if (email.isEmpty ||
                          password.isEmpty ||
                          fullName.isEmpty ||
                          phone.isEmpty) {
                        setState(() {
                          error = "All fields are required";
                          submitting = false;
                        });
                        return;
                      }
                      try {
                        final response = await supabase.auth.signUp(
                          email: email,
                          password: password,
                        );
                        if (!mounted) return;
                        if (response.user != null) {
                          await supabase.from('profiles').insert({
                            'id': response.user!.id,
                            'full name': fullName,
                            'phone': phone,
                            'bio': '',
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Registration successful! Please check your email.',
                              ),
                            ),
                          );
                          Navigator.pushReplacementNamed(context, '/login');
                        } else {
                          setState(() {
                            error = "Registration failed";
                          });
                        }
                      } catch (e) {
                        setState(() {
                          error = "Error: ${e.toString()}";
                        });
                      }
                      setState(() {
                        submitting = false;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = supabase.auth.currentUser;
    if (user == null && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Logout',
            onPressed: () async {
              await supabase.auth.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the multi-platform app!'),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('View Profile'),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
            ElevatedButton(
              child: const Text('Data Collection Form'),
              onPressed: () => Navigator.pushNamed(context, '/form'),
            ),
            ElevatedButton(
              child: const Text('Device Metrics'),
              onPressed: () => Navigator.pushNamed(context, '/metrics'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final emailController = TextEditingController();
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Enter your email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Send Reset Email'),
              onPressed: () async {
                final email = emailController.text;
                try {
                  await supabase.auth.resetPasswordForEmail(email);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent')),
                  );
                  Navigator.pop(context); // Optionally, return to login
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController emailController;
  late TextEditingController nameController;
  late TextEditingController bioController;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    final email = supabase.auth.currentUser?.email ?? '';
    emailController = TextEditingController(text: email);
    nameController = TextEditingController();
    bioController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      nameController.text = profile['full name'] ?? '';
      bioController.text = profile['bio'] ?? '';
    } catch (e) {
      error = 'Failed to load profile or profile does not exist';
    }
    setState(() => loading = false);
  }

  Future<void> _updateProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase
          .from('profiles')
          .update({'full name': nameController.text, 'bio': bioController.text})
          .eq('id', user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _updateEmail() async {
    final newEmail = emailController.text;
    try {
      await supabase.auth.updateUser(UserAttributes(email: newEmail));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email update requested! Please check your email for confirmation.',
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: error != null
                  ? Text(error!)
                  : user == null
                  ? const Text('No user signed in')
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('User ID: ${user.id}'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                          ElevatedButton(
                            child: const Text('Update Email'),
                            onPressed: _updateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: bioController,
                            decoration: const InputDecoration(labelText: 'Bio'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            child: const Text('Update Profile'),
                            onPressed: _updateProfile,
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}

class DataFormScreen extends StatefulWidget {
  const DataFormScreen({super.key});
  @override
  State<DataFormScreen> createState() => _DataFormScreenState();
}

class _DataFormScreenState extends State<DataFormScreen> {
  final feedbackController = TextEditingController();
  bool submitting = false;
  String? error;
  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Collection Form")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(labelText: 'Feedback'),
            ),
            const SizedBox(height: 20),
            if (submitting) const CircularProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() {
                        submitting = true;
                        error = null;
                      });
                      final user = supabase.auth.currentUser;
                      if (user == null) {
                        setState(() {
                          submitting = false;
                          error = "No user logged in";
                        });
                        return;
                      }
                      try {
                        await supabase.from('user_feedback').insert({
                          'user_id': user.id,
                          'feedback': feedbackController.text,
                          'timestamp': DateTime.now().toIso8601String(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feedback submitted')),
                        );
                        feedbackController.clear();
                      } catch (e) {
                        setState(() {
                          error = 'Feedback submit error: ${e.toString()}';
                        });
                      }
                      setState(() {
                        submitting = false;
                      });
                    },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});
  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  String deviceModel = "";
  int batteryLevel = 0;
  bool loading = true;
  String? error;
  late TargetPlatform platform;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    platform = Theme.of(context).platform;
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
      } else if (platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
      } else {
        deviceModel = "Desktop/Other";
      }
      final battery = Battery();
      batteryLevel = await battery.batteryLevel;
    } catch (e) {
      error = "Failed to load device metrics: ${e.toString()}";
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Device Metrics")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          : Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Device Model: $deviceModel"),
                  Text("Battery Level: $batteryLevel%"),
                ],
              ),
            ),
    );
  }
}
