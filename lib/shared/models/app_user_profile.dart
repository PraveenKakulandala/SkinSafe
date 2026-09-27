class AppUserProfile {
  final String uid;
  final String name;
  final String email;
  final String age;
  final String contact;
  final String skinReaction;
  final bool manyMolesReported;
  final bool sunburnOrTanningHistoryReported;
  final bool familySkinCancerHistoryReported;
  final bool previousSkinCancerHistoryReported;

  const AppUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.age = '',
    this.contact = '',
    this.skinReaction = 'Not specified',
    this.manyMolesReported = false,
    this.sunburnOrTanningHistoryReported = false,
    this.familySkinCancerHistoryReported = false,
    this.previousSkinCancerHistoryReported = false,
  });

  factory AppUserProfile.fromJson(Map<String, Object?> json) {
    return AppUserProfile(
      uid: (json['uid'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      age: (json['age'] as String?) ?? '',
      contact: (json['contact'] as String?) ?? '',
      skinReaction: (json['skinReaction'] as String?) ?? 'Not specified',
      manyMolesReported: (json['manyMolesReported'] as bool?) ?? false,
      sunburnOrTanningHistoryReported:
          (json['sunburnOrTanningHistoryReported'] as bool?) ?? false,
      familySkinCancerHistoryReported:
          (json['familySkinCancerHistoryReported'] as bool?) ?? false,
      previousSkinCancerHistoryReported:
          (json['previousSkinCancerHistoryReported'] as bool?) ?? false,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'uid': uid,
      'name': name,
      'email': email,
      'age': age,
      'contact': contact,
      'skinReaction': skinReaction,
      'manyMolesReported': manyMolesReported,
      'sunburnOrTanningHistoryReported': sunburnOrTanningHistoryReported,
      'familySkinCancerHistoryReported': familySkinCancerHistoryReported,
      'previousSkinCancerHistoryReported': previousSkinCancerHistoryReported,
    };
  }
}
