import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  SupabaseClient? client;
  String? error;
  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('Adres Supabase musi używać HTTPS.');
      }
      await Supabase.initialize(url: url, publishableKey: key);
      client = Supabase.instance.client;
    } catch (_) {
      error =
          'Nie udało się uruchomić połączenia. Sprawdź konfigurację Supabase w projekcie.';
    }
  }
  runApp(
    BliskoApp(
      controller: AppController(client: client, bootError: error),
    ),
  );
}
