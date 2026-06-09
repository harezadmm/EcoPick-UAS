import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../auth/models/app_user.dart';

class ProfileService {
  Future<AppUser?> fetchCurrentProfile() async {
    if (!SupabaseConfig.isConfigured) return null;
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return null;
    final row = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return AppUser.fromMap(row);
  }

  /// Updates the editable profile fields. Email change also updates the auth
  /// record (which may trigger a confirmation email depending on project
  /// settings). Returns the refreshed [AppUser].
  Future<AppUser?> updateProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    if (!SupabaseConfig.isConfigured) return null;
    final client = SupabaseConfig.client;

    final current = client.auth.currentUser;
    // If the email changed, update the auth user too.
    if (current != null && current.email != email && email.isNotEmpty) {
      await client.auth.updateUser(UserAttributes(email: email));
    }

    await client.from('profiles').update({
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);

    return fetchCurrentProfile();
  }

  /// Uploads [file] to the public `avatars` bucket under `<userId>/avatar.<ext>`,
  /// saves the public URL on the profile, and returns the URL.
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw Exception('Supabase not configured');
    }
    final client = SupabaseConfig.client;

    final ext = file.path.split('.').last.toLowerCase();
    final path = '$userId/avatar.$ext';

    await client.storage.from('avatars').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    // Add a cache-busting query so the new image shows immediately.
    final publicUrl = client.storage.from('avatars').getPublicUrl(path);
    final bustedUrl =
        '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await client
        .from('profiles')
        .update({'avatar_url': bustedUrl}).eq('id', userId);

    return bustedUrl;
  }

  Future<void> updatePassword(String newPassword) async {
    if (!SupabaseConfig.isConfigured) return;
    await SupabaseConfig.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
