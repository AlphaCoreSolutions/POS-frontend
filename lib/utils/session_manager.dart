import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _kOrgId = 'organizationId';

  static Future<int?> getOrganizationId() async {
    final prefs = await SharedPreferences.getInstance();

    // Try int first
    final asInt = prefs.getInt(_kOrgId);
    if (asInt != null) return asInt;

    // Fallback: maybe it was stored as string (web / older code)
    final asString = prefs.getString(_kOrgId);
    final parsed = int.tryParse(asString ?? '');
    return parsed; // null if not parseable
  }

  static Future<void> setOrganizationId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kOrgId, id);
  }
}
