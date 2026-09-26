import 'package:supabase_flutter/supabase_flutter.dart';
class SupabaseConfig { const SupabaseConfig._(); static const url=String.fromEnvironment('SUPABASE_URL'); static const anonKey=String.fromEnvironment('SUPABASE_ANON_KEY'); }
Future<void> initializeSupabase() async { if(SupabaseConfig.url.isEmpty||SupabaseConfig.anonKey.isEmpty) throw StateError('SUPABASE_URL and SUPABASE_ANON_KEY must be provided with --dart-define.'); await Supabase.initialize(url:SupabaseConfig.url,publishableKey:SupabaseConfig.anonKey); }
SupabaseClient get supabaseClient=>Supabase.instance.client;
