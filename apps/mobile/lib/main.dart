import 'package:flutter/material.dart';
import 'app.dart';
import 'supabase_client.dart';
Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); await initializeSupabase(); runApp(const EduOSApp()); }
