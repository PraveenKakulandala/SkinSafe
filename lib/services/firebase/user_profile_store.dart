import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/app_user_profile.dart';

abstract interface class UserProfileStore {
  Future<AppUserProfile?> fetchProfile(String uid);
  Future<void> upsertProfile(AppUserProfile profile);
}

class FirestoreUserProfileStore implements UserProfileStore {
  final FirebaseFirestore _firestore;

  FirestoreUserProfileStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AppUserProfile?> fetchProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return AppUserProfile(
      uid: uid,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      age: (data['age'] as String?) ?? '',
      contact: (data['contact'] as String?) ?? '',
      skinReaction: (data['skinReaction'] as String?) ?? 'Not specified',
      manyMolesReported: (data['manyMolesReported'] as bool?) ?? false,
      sunburnOrTanningHistoryReported:
          (data['sunburnOrTanningHistoryReported'] as bool?) ?? false,
      familySkinCancerHistoryReported:
          (data['familySkinCancerHistoryReported'] as bool?) ?? false,
      previousSkinCancerHistoryReported:
          (data['previousSkinCancerHistoryReported'] as bool?) ?? false,
    );
  }

  @override
  Future<void> upsertProfile(AppUserProfile profile) async {
    final reference = _firestore.collection('users').doc(profile.uid);

    await reference.set({
      'uid': profile.uid,
      'name': profile.name,
      'email': profile.email,
      'age': profile.age,
      'contact': profile.contact,
      'skinReaction': profile.skinReaction,
      'manyMolesReported': profile.manyMolesReported,
      'sunburnOrTanningHistoryReported':
          profile.sunburnOrTanningHistoryReported,
      'familySkinCancerHistoryReported':
          profile.familySkinCancerHistoryReported,
      'previousSkinCancerHistoryReported':
          profile.previousSkinCancerHistoryReported,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class CachedUserProfileStore implements UserProfileStore {
  final UserProfileStore _remoteStore;
  final Future<SharedPreferences> Function() _loadPreferences;

  const CachedUserProfileStore({
    required UserProfileStore remoteStore,
    Future<SharedPreferences> Function()? loadPreferences,
  }) : _remoteStore = remoteStore,
       _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  @override
  Future<AppUserProfile?> fetchProfile(String uid) async {
    final cachedProfile = await _fetchCachedProfile(uid);

    try {
      final remoteProfile = await _remoteStore.fetchProfile(uid);
      if (remoteProfile != null) {
        final mergedProfile = _mergeProfiles(remoteProfile, cachedProfile);
        await _cacheProfile(mergedProfile);
        return mergedProfile;
      }
    } catch (error) {
      debugPrint(
        'Using cached profile after remote profile load failed: $error',
      );
    }

    return cachedProfile;
  }

  @override
  Future<void> upsertProfile(AppUserProfile profile) async {
    await _cacheProfile(profile);

    try {
      await _remoteStore.upsertProfile(profile);
    } catch (error) {
      debugPrint(
        'Saved profile locally after remote profile sync failed: $error',
      );
    }
  }

  Future<AppUserProfile?> _fetchCachedProfile(String uid) async {
    try {
      final preferences = await _loadPreferences();
      final encodedProfile = preferences.getString(_profileKey(uid));
      if (encodedProfile == null || encodedProfile.trim().isEmpty) {
        return null;
      }

      final decodedProfile = jsonDecode(encodedProfile);
      if (decodedProfile is! Map) {
        return null;
      }
      final profileJson = Map<String, Object?>.from(decodedProfile);

      final profile = AppUserProfile.fromJson(profileJson);
      return profile.uid.trim().isEmpty
          ? AppUserProfile.fromJson(<String, Object?>{
              ...profileJson,
              'uid': uid,
            })
          : profile;
    } catch (error) {
      debugPrint('Failed to read cached profile: $error');
      return null;
    }
  }

  Future<void> _cacheProfile(AppUserProfile profile) async {
    try {
      final preferences = await _loadPreferences();
      await preferences.setString(
        _profileKey(profile.uid),
        jsonEncode(profile.toJson()),
      );
    } catch (error) {
      debugPrint('Failed to cache profile locally: $error');
    }
  }

  AppUserProfile _mergeProfiles(
    AppUserProfile primary,
    AppUserProfile? fallback,
  ) {
    if (fallback == null) {
      return primary;
    }

    String pickText(String value, String fallbackValue) {
      return value.trim().isNotEmpty ? value : fallbackValue;
    }

    String pickSkinReaction(String value, String fallbackValue) {
      final normalizedValue = value.trim();
      final normalizedFallback = fallbackValue.trim();
      if (normalizedValue.isNotEmpty && normalizedValue != 'Not specified') {
        return value;
      }
      if (normalizedFallback.isNotEmpty) {
        return fallbackValue;
      }
      return value;
    }

    return AppUserProfile(
      uid: pickText(primary.uid, fallback.uid),
      name: pickText(primary.name, fallback.name),
      email: pickText(primary.email, fallback.email),
      age: pickText(primary.age, fallback.age),
      contact: pickText(primary.contact, fallback.contact),
      skinReaction: pickSkinReaction(
        primary.skinReaction,
        fallback.skinReaction,
      ),
      manyMolesReported:
          primary.manyMolesReported || fallback.manyMolesReported,
      sunburnOrTanningHistoryReported:
          primary.sunburnOrTanningHistoryReported ||
          fallback.sunburnOrTanningHistoryReported,
      familySkinCancerHistoryReported:
          primary.familySkinCancerHistoryReported ||
          fallback.familySkinCancerHistoryReported,
      previousSkinCancerHistoryReported:
          primary.previousSkinCancerHistoryReported ||
          fallback.previousSkinCancerHistoryReported,
    );
  }

  static String _profileKey(String uid) => 'skinsafe.user_profile.$uid';
}

class MemoryUserProfileStore implements UserProfileStore {
  final Map<String, AppUserProfile> _profiles = <String, AppUserProfile>{};

  @override
  Future<AppUserProfile?> fetchProfile(String uid) async {
    return _profiles[uid];
  }

  @override
  Future<void> upsertProfile(AppUserProfile profile) async {
    _profiles[profile.uid] = profile;
  }
}
