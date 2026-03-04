import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'URL',
    anonKey: 'SUPABASE_ANON_KEY',
  );

  runApp(const ProviderScope(child: HabitStreakApp()));
}
