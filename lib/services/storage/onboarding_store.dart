import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingStateStore {
  Future<bool> loadCompleted();
  Future<void> saveCompleted(bool value);
}

class SharedPreferencesOnboardingStateStore implements OnboardingStateStore {
  static const String _storageKey = 'skinsafe.onboarding.completed';
  SharedPreferences? _sharedPreferences;

  Future<SharedPreferences> _instance() async {
    return _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<bool> loadCompleted() async {
    final preferences = await _instance();
    return preferences.getBool(_storageKey) ?? false;
  }

  @override
  Future<void> saveCompleted(bool value) async {
    final preferences = await _instance();
    await preferences.setBool(_storageKey, value);
  }
}

class MemoryOnboardingStateStore implements OnboardingStateStore {
  bool _value;

  MemoryOnboardingStateStore({bool initialValue = false})
    : _value = initialValue;

  @override
  Future<bool> loadCompleted() async {
    return _value;
  }

  @override
  Future<void> saveCompleted(bool value) async {
    _value = value;
  }
}
