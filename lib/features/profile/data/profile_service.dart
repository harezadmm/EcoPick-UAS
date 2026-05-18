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

  Future<void> updatePassword(String newPassword) async {
    if (!SupabaseConfig.isConfigured) return;
    await SupabaseConfig.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
