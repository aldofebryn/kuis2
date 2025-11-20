import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  // Singleton pattern untuk memastikan hanya ada satu instance PreferenceService
  static final PreferenceService _instance = PreferenceService._internal();

  factory PreferenceService() => _instance;
  
  PreferenceService._internal();

  // Late initialization untuk SharedPreferences
  late SharedPreferences _prefs;

  // Inisialisasi SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Metode untuk menyimpan String
  Future<bool> setString(String key, String value) async =>
      await _prefs.setString(key, value);
      
  // Metode untuk mendapatkan String
  String? getString(String key) => _prefs.getString(key);

  // Metode untuk menyimpan Int
  Future<bool> setInt(String key, int value) async =>
      await _prefs.setInt(key, value);
      
  // Metode untuk mendapatkan Int
  int? getInt(String key) => _prefs.getInt(key);

  // Metode untuk menghapus data berdasarkan key
  Future<bool> remove(String key) async => await _prefs.remove(key);
  
  // Metode untuk membersihkan semua data
  Future<bool> clear() async => await _prefs.clear();
}