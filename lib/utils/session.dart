import 'package:shared_preferences/shared_preferences.dart';
import './Logger.dart';

//设置session
Future<void> setSession(String key, String value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  } catch (e) {
    Log.e('Error setting session: $e');
    rethrow;
  }
}

//获取session
Future<String?> getSession(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  } catch (e) {
    Log.e('Error getting session: $e');
    return null;
  }
}

//删除session
Future<void> deleteSession(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  } catch (e) {
    Log.e('Error deleting session: $e');
    rethrow;
  }
}