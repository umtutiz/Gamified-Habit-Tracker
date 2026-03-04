import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ddslkpifyuihnujzahzz.supabase.co',
    anonKey: 'sb_publishable_vsyTbsAObbq7IzZc70EyYA_JCkgAdrT',
  );

  runApp(const ProviderScope(child: HabitStreakApp()));
}