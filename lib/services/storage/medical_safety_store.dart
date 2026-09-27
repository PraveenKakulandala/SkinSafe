import 'package:shared_preferences/shared_preferences.dart';

abstract interface class MedicalSafetyStore {
  Future<bool> loadAccepted();
  Future<void> saveAccepted(bool value);
}

class SharedPreferencesMedicalSafetyStore implements MedicalSafetyStore {
  static const String _storageKey = 'skinsafe.medical_safety.accepted';
  SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> _instance() async {
    return _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<bool> loadAccepted() async {
    final preferences = await _instance();
    return preferences.getBool(_storageKey) ?? false;
  }

  @override
  Future<void> saveAccepted(bool value) async {
    final preferences = await _instance();
    await preferences.setBool(_storageKey, value);
  }
}

class MemoryMedicalSafetyStore implements MedicalSafetyStore {
  bool _accepted;

  MemoryMedicalSafetyStore({bool initialValue = false})
    : _accepted = initialValue;

  @override
  Future<bool> loadAccepted() async => _accepted;

  @override
  Future<void> saveAccepted(bool value) async {
    _accepted = value;
  }
}
