import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://bczovurgxkhphtdzdxos.supabase.co', // <-- Replace this
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJjem92dXJneGtocGh0ZHpkeG9zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NzEwOTQsImV4cCI6MjA3NzM0NzA5NH0.qxZjBBTjUoZDEJJm4qr0tkYzG9IWXVviiG_gsEOFIlk', // <-- Replace this
  );
}

final supabase = Supabase.instance.client;
