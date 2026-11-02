import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedPrefsStore implements LocalStore {
  static const key = 'jelajahnusa_snapshot_v1';
  final SharedPreferences preferences;
  SharedPrefsStore(this.preferences);
  static Future<SharedPrefsStore> open() async =>
      SharedPrefsStore(await SharedPreferences.getInstance());
  @override
  Future<String?> read() async => preferences.getString(key);
  @override
  Future<void> write(String value) async {
    if (!await preferences.setString(key, value)) {
      throw StateError('Penyimpanan menolak perubahan.');
    }
  }
}
