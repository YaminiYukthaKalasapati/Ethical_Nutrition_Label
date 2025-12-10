import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/env_config.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/data_form_screen.dart';
import 'screens/metrics_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_all_submissions_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/dnl_generator_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Nutrition Label',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/data-form': (context) => const DataFormScreen(),
        '/metrics': (context) => const MetricsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => const HistoryScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/admin/submissions': (context) => const AdminAllSubmissionsScreen(),
        '/admin/users': (context) => const AdminUsersScreen(),
        '/admin/analytics': (context) => const AdminAnalyticsScreen(),
        '/admin/dnl': (context) => const DNLGeneratorScreen(), // ADD THIS LINE
      },
    );
  }
}
