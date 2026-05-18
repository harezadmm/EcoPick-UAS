import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not present in dev → demo mode
  }
  await initializeDateFormatting('id_ID', null);
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: EcoPoinApp()));
}
