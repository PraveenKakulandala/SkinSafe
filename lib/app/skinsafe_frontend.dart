import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../services/firebase/scan_image_storage_service.dart';
import '../services/firebase/scan_record_store.dart';
import '../services/scan/follow_up_plan_service.dart';
import '../services/scan/scan_image_picker_service.dart';
import '../services/scan/lesion_tracking_service.dart';
import '../services/scan/scan_prediction_service.dart';
import '../services/firebase/user_profile_store.dart';
import '../services/weather/uv_forecast_service.dart';
import '../services/storage/medical_safety_store.dart';
import '../services/storage/onboarding_store.dart';
import '../shared/models/app_user_profile.dart';
import '../shared/models/scan_prediction_result.dart';
import '../shared/models/scan_record.dart';
import '../shared/models/selected_scan_image.dart';
import '../shared/models/uploaded_scan_image.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SkinSafeApp());
}

class SkinSafeApp extends StatefulWidget {
  final FrontendAuthController? authController;

  const SkinSafeApp({super.key, this.authController});

  @override
  State<SkinSafeApp> createState() => _SkinSafeAppState();
}

class _SkinSafeAppState extends State<SkinSafeApp> {
  static const _darkModePreferenceKey = 'skinsafe_dark_mode_enabled';
  late final FrontendAuthController _authController;
  late final bool _ownsAuthController;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _authController = widget.authController ?? FrontendAuthController();
    _ownsAuthController = widget.authController == null;
    unawaited(_loadThemePreference());
  }

  Future<void> _loadThemePreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _isDarkMode = preferences.getBool(_darkModePreferenceKey) ?? false;
    });
  }

  void _setDarkMode(bool value) {
    setState(() => _isDarkMode = value);
    _applySystemOverlay(value);
    unawaited(_saveThemePreference(value));
  }

  Future<void> _saveThemePreference(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModePreferenceKey, value);
  }

  void _applySystemOverlay(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    if (_ownsAuthController) {
      _authController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _applySystemOverlay(_isDarkMode);

    return SkinSafeThemeScope(
      isDarkMode: _isDarkMode,
      onDarkModeChanged: _setDarkMode,
      child: AuthScope(
        controller: _authController,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SkinSafe',
          themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildSkinSafeTheme(Brightness.light),
          darkTheme: _buildSkinSafeTheme(Brightness.dark),
          home: const AuthEntryScreen(),
        ),
      ),
    );
  }
}

ThemeData _buildSkinSafeTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: isDark ? AppPalette.darkPrimary : AppPalette.primary,
      brightness: brightness,
    ),
  );
  final ink = isDark ? AppPalette.darkInk : AppPalette.ink;
  final muted = isDark ? AppPalette.darkMuted : AppPalette.muted;
  final surface = isDark ? AppPalette.darkSurface : AppPalette.surface;
  final line = isDark ? AppPalette.darkLine : AppPalette.line;
  final primary = isDark ? AppPalette.darkPrimary : AppPalette.primary;
  final primarySoft = isDark
      ? AppPalette.darkPrimarySoft
      : AppPalette.primarySoft;

  return baseTheme.copyWith(
    scaffoldBackgroundColor: isDark ? AppPalette.darkCanvas : AppPalette.canvas,
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: primary,
      secondary: AppPalette.aqua,
      surface: surface,
      onSurface: ink,
    ),
    textTheme: baseTheme.textTheme.copyWith(
      displaySmall: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 0.96,
        letterSpacing: -1.4,
      ),
      headlineLarge: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 0.98,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.02,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: ink,
        height: 1.05,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: muted, height: 1.55),
      bodyMedium: TextStyle(fontSize: 14, color: muted, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: muted, height: 1.4),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      prefixIconColor: muted,
      suffixIconColor: muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: primary, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppPalette.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: AppPalette.danger, width: 1.2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isDark ? AppPalette.darkInk : Colors.white;
        }
        return isDark ? AppPalette.darkMuted : Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return primarySoft;
      }),
    ),
  );
}

class SkinSafeThemeScope extends InheritedWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const SkinSafeThemeScope({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required super.child,
  });

  static SkinSafeThemeScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SkinSafeThemeScope>();
    assert(scope != null, 'SkinSafeThemeScope not found in widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(SkinSafeThemeScope oldWidget) {
    return isDarkMode != oldWidget.isDarkMode ||
        onDarkModeChanged != oldWidget.onDarkModeChanged;
  }
}

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (!auth.isReady) {
      return const LoadingScreen();
    }

    if (auth.isSignedIn) {
      return const AppShellScreen();
    }

    if (!auth.hasCompletedOnboarding) {
      return const OnboardingScreen();
    }

    return const LoginScreen();
  }
}

class AppUser {
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

  const AppUser({
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

  AppUser copyWith({
    String? name,
    String? email,
    String? age,
    String? contact,
    String? skinReaction,
    bool? manyMolesReported,
    bool? sunburnOrTanningHistoryReported,
    bool? familySkinCancerHistoryReported,
    bool? previousSkinCancerHistoryReported,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      contact: contact ?? this.contact,
      skinReaction: skinReaction ?? this.skinReaction,
      manyMolesReported: manyMolesReported ?? this.manyMolesReported,
      sunburnOrTanningHistoryReported:
          sunburnOrTanningHistoryReported ??
          this.sunburnOrTanningHistoryReported,
      familySkinCancerHistoryReported:
          familySkinCancerHistoryReported ??
          this.familySkinCancerHistoryReported,
      previousSkinCancerHistoryReported:
          previousSkinCancerHistoryReported ??
          this.previousSkinCancerHistoryReported,
    );
  }

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'User';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'SS';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  List<String> get baselineRiskFactors {
    final factors = <String>[
      if (skinReaction.toLowerCase().contains('burn'))
        'skin burns or freckles easily',
      if (manyMolesReported) 'many or unusual moles reported',
      if (sunburnOrTanningHistoryReported)
        'sunburn or tanning history reported',
      if (familySkinCancerHistoryReported) 'family history reported',
      if (previousSkinCancerHistoryReported)
        'prior skin cancer concern reported',
    ];

    return factors;
  }
}

class AppAuthException implements Exception {
  final String message;

  const AppAuthException(this.message);
}

class AppFlowException implements Exception {
  final String message;

  const AppFlowException(this.message);
}

bool _isLowRiskNonMelanomaResult(ScanPredictionResult prediction) {
  final status = prediction.status.toLowerCase();
  final predictedClass = prediction.predictedClass.toLowerCase();

  return status.contains('low melanoma risk') ||
      predictedClass.contains('non-melanoma') ||
      predictedClass.contains('non melanoma');
}

bool _isLowRiskNonMelanomaRecord(ScanRecord record) {
  final status = record.status.toLowerCase();
  final predictedClass = record.predictedClass.toLowerCase();

  return status.contains('low melanoma risk') ||
      predictedClass.contains('non-melanoma') ||
      predictedClass.contains('non melanoma');
}

class FrontendAuthController extends ChangeNotifier {
  final FirebaseAuth? _firebaseAuth;
  final OnboardingStateStore _onboardingStateStore;
  final ScanRecordStore _scanRecordStore;
  final ScanImagePickerService _scanImagePickerService;
  final ScanPredictionService _scanPredictionService;
  final ScanImageStorageService _scanImageStorageService;
  final UserProfileStore _userProfileStore;
  StreamSubscription<User?>? _authSubscription;

  AppUser? _currentUser;
  List<ScanRecord> _scanRecords = const <ScanRecord>[];
  bool _isReady;
  bool _hasCompletedOnboarding;
  bool _isDisposed = false;

  FrontendAuthController({
    FirebaseAuth? firebaseAuth,
    OnboardingStateStore? onboardingStateStore,
    ScanRecordStore? scanRecordStore,
    ScanImagePickerService? scanImagePickerService,
    ScanPredictionService? scanPredictionService,
    ScanImageStorageService? scanImageStorageService,
    UserProfileStore? userProfileStore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _onboardingStateStore =
           onboardingStateStore ?? SharedPreferencesOnboardingStateStore(),
       _scanRecordStore = scanRecordStore ?? FirestoreScanRecordStore(),
       _scanImagePickerService =
           scanImagePickerService ?? DeviceScanImagePickerService(),
       _scanPredictionService =
           scanPredictionService ?? OnDeviceTfliteScanPredictionService(),
       _scanImageStorageService =
           scanImageStorageService ?? LocalScanImageStorageService(),
       _userProfileStore =
           userProfileStore ??
           CachedUserProfileStore(remoteStore: FirestoreUserProfileStore()),
       _isReady = false,
       _hasCompletedOnboarding = false {
    unawaited(_initialize());
  }

  FrontendAuthController.preview({
    bool hasCompletedOnboarding = false,
    ScanPredictionService? scanPredictionService,
  }) : _firebaseAuth = null,
       _onboardingStateStore = MemoryOnboardingStateStore(
         initialValue: hasCompletedOnboarding,
       ),
       _scanRecordStore = MemoryScanRecordStore(),
       _scanImagePickerService = MemoryScanImagePickerService(),
       _scanPredictionService =
           scanPredictionService ?? MemoryScanPredictionService(),
       _scanImageStorageService = MemoryScanImageStorageService(),
       _userProfileStore = MemoryUserProfileStore(),
       _isReady = true,
       _hasCompletedOnboarding = hasCompletedOnboarding;

  AppUser? get currentUser => _currentUser;
  List<ScanRecord> get scanRecords =>
      List<ScanRecord>.unmodifiable(_scanRecords);

  bool get isReady => _isReady;

  bool get isSignedIn => _currentUser != null;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  bool get isPreviewMode => _firebaseAuth == null;

  Future<void> _initialize() async {
    _hasCompletedOnboarding = await _loadOnboardingState();

    final auth = _firebaseAuth;
    if (auth != null) {
      _authSubscription = auth.authStateChanges().listen((user) {
        unawaited(_applyFirebaseUser(user, persistProfile: user != null));
      });
      await _applyFirebaseUser(
        auth.currentUser,
        persistProfile: auth.currentUser != null,
      );
    }

    _isReady = true;
    _notify();
  }

  Future<bool> _loadOnboardingState() async {
    try {
      return await _onboardingStateStore.loadCompleted();
    } catch (error) {
      debugPrint('Failed to load onboarding state: $error');
      return false;
    }
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    _notify();

    try {
      await _onboardingStateStore.saveCompleted(true);
    } catch (error) {
      debugPrint('Failed to save onboarding state: $error');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    if (_firebaseAuth == null) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final user = AppUser(
        uid: 'preview-${email.hashCode}',
        name: _nameFromEmail(email.trim()),
        email: email.trim(),
      );
      _currentUser = user;
      await _loadScanRecordsForUser(user.uid);
      _notify();
      return;
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _applyFirebaseUser(credential.user, persistProfile: true);
    } on FirebaseAuthException catch (error) {
      throw AppAuthException(_authMessageFor(error));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String age,
    required String contact,
    required String skinReaction,
    required bool manyMolesReported,
    required bool sunburnOrTanningHistoryReported,
    required bool familySkinCancerHistoryReported,
    required bool previousSkinCancerHistoryReported,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedAge = age.trim();
    final trimmedContact = contact.trim();
    final normalizedSkinReaction = skinReaction.trim().isEmpty
        ? 'Not specified'
        : skinReaction.trim();

    if (_firebaseAuth == null) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return;
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(trimmedName);
        await user.reload();
        final refreshedUser = _firebaseAuth.currentUser ?? user;
        final profileUser =
            _userFromFirebase(
              refreshedUser,
              preferredName: trimmedName,
            ).copyWith(
              age: trimmedAge,
              contact: trimmedContact,
              skinReaction: normalizedSkinReaction,
              manyMolesReported: manyMolesReported,
              sunburnOrTanningHistoryReported: sunburnOrTanningHistoryReported,
              familySkinCancerHistoryReported: familySkinCancerHistoryReported,
              previousSkinCancerHistoryReported:
                  previousSkinCancerHistoryReported,
            );
        _currentUser = profileUser;
        _notify();
        await _safeUpsertProfile(profileUser);
      }
      await _firebaseAuth.signOut();
      _currentUser = null;
      _scanRecords = const <ScanRecord>[];
      _notify();
    } on FirebaseAuthException catch (error) {
      throw AppAuthException(_authMessageFor(error));
    }
  }

  Future<void> sendPasswordReset({required String email}) async {
    if (_firebaseAuth == null) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AppAuthException(_passwordResetMessageFor(error));
    }
  }

  Future<void> signOut() async {
    if (_firebaseAuth == null) {
      _currentUser = null;
      _scanRecords = const <ScanRecord>[];
      _notify();
      return;
    }

    await _firebaseAuth.signOut();
    _currentUser = null;
    _scanRecords = const <ScanRecord>[];
    _notify();
  }

  Future<SelectedScanImage?> pickScanImage(ScanImageSource source) async {
    try {
      return await _scanImagePickerService.pickImage(source);
    } catch (error) {
      debugPrint('Failed to pick scan image: $error');
      throw AppFlowException(
        source == ScanImageSource.camera
            ? 'Unable to open the camera right now.'
            : 'Unable to open the photo gallery right now.',
      );
    }
  }

  Future<ScanPredictionResult> analyzeCapturedScan({
    required SelectedScanImage selectedImage,
  }) async {
    try {
      return await _scanPredictionService.predictScan(image: selectedImage);
    } on ScanPredictionServiceException catch (error) {
      debugPrint('Failed to analyze scan image: $error');
      throw const AppFlowException(
        'Unable to analyze the selected image on this device. Please try another clear photo.',
      );
    } catch (error) {
      debugPrint('Failed to analyze scan image: $error');
      throw const AppFlowException(
        'Unable to analyze the selected image with the on-device model right now.',
      );
    }
  }

  Future<void> saveCapturedScan({
    required String patientName,
    required String patientAge,
    required String patientContact,
    required String bodyArea,
    required String location,
    required String note,
    required bool recentChangeObserved,
    required bool familyHistoryReported,
    required bool priorSkinCancerReported,
    required bool newOrGrowingLesionObserved,
    required bool borderColorChangeObserved,
    required bool lesionSymptomsObserved,
    required String baselineRiskSummary,
    required String combinedRiskSummary,
    required bool followUpReminderEnabled,
    required int followUpReminderDays,
    required DateTime? followUpReminderDate,
    required String followUpReminderReason,
    required SelectedScanImage selectedImage,
    required ScanPredictionResult prediction,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw const AppAuthException('Sign in to save scan results.');
    }

    final now = DateTime.now();
    final recordNumber = _scanRecords.length + 1;
    final trimmedPatientName = patientName.trim();
    final trimmedPatientAge = patientAge.trim();
    final trimmedPatientContact = patientContact.trim();
    final trimmedBodyArea = bodyArea.trim();
    final trimmedLocation = location.trim();
    final trimmedNote = note.trim();
    final shouldSaveIllustration = !_isLowRiskNonMelanomaResult(prediction);
    final savedRawImage = await _uploadScanImage(
      uid: user.uid,
      selectedImage: selectedImage,
      assetFolder: 'raw',
      assetRole: 'raw-source-photo',
      failureLabel: 'raw scan photo',
    );
    final savedIllustration = shouldSaveIllustration
        ? await _uploadScanImage(
            uid: user.uid,
            selectedImage: _buildIllustrationUploadAsset(
              selectedImage: selectedImage,
              prediction: prediction,
            ),
            assetFolder: 'illustrations',
            assetRole: 'generated-lesion-illustration',
            failureLabel: 'generated lesion illustration',
          )
        : const UploadedScanImage(imageUrl: '', storagePath: '');

    final record = ScanRecord(
      id: 'scan-${now.microsecondsSinceEpoch}',
      patientName: trimmedPatientName,
      patientAge: trimmedPatientAge,
      patientContact: trimmedPatientContact,
      title: trimmedLocation.isEmpty
          ? 'Guided scan $recordNumber'
          : '$trimmedLocation scan',
      capturedAt: now,
      bodyArea: trimmedBodyArea,
      location: trimmedLocation,
      captureSource: '${selectedImage.source.label} scan',
      predictedClass: prediction.predictedClass,
      modelVersion: prediction.modelVersion,
      status: prediction.status,
      riskScore: prediction.melanomaProbabilityPercent,
      summary: prediction.summary,
      note: trimmedNote,
      nextStep: prediction.recommendation,
      recentChangeObserved: recentChangeObserved,
      familyHistoryReported: familyHistoryReported,
      priorSkinCancerReported: priorSkinCancerReported,
      newOrGrowingLesionObserved: newOrGrowingLesionObserved,
      borderColorChangeObserved: borderColorChangeObserved,
      lesionSymptomsObserved: lesionSymptomsObserved,
      questionnaireSummary: _buildQuestionnaireSummary(
        recentChangeObserved: recentChangeObserved,
        familyHistoryReported: familyHistoryReported,
        priorSkinCancerReported: priorSkinCancerReported,
        newOrGrowingLesionObserved: newOrGrowingLesionObserved,
        borderColorChangeObserved: borderColorChangeObserved,
        lesionSymptomsObserved: lesionSymptomsObserved,
      ),
      baselineRiskSummary: baselineRiskSummary,
      combinedRiskSummary: combinedRiskSummary,
      savedAssetLabel: shouldSaveIllustration
          ? 'Raw scan photo and generated lesion illustration'
          : 'Raw scan photo',
      lesionCoveragePercent: prediction.lesionCoveragePercent,
      imageQualityScore: prediction.imageQualityScore,
      imageQualityStatus: prediction.imageQualityStatus,
      imageQualitySummary: prediction.imageQualitySummary,
      preprocessingSummary: prediction.preprocessingSummary,
      followUpReminderEnabled: followUpReminderEnabled,
      followUpReminderDate: followUpReminderDate,
      followUpReminderDays: followUpReminderEnabled
          ? followUpReminderDays
          : null,
      followUpReminderReason: followUpReminderEnabled
          ? followUpReminderReason
          : '',
      rawImageUrl: savedRawImage.imageUrl,
      rawStoragePath: savedRawImage.storagePath,
      illustrationImageUrl: savedIllustration.imageUrl,
      illustrationStoragePath: savedIllustration.storagePath,
    );

    _scanRecords = <ScanRecord>[
      record,
      ..._scanRecords.where((existingRecord) => existingRecord.id != record.id),
    ];
    _notify();

    try {
      await _scanRecordStore.saveRecord(uid: user.uid, record: record);
      await _loadScanRecordsForUser(user.uid);
      _notify();
    } catch (error) {
      debugPrint('Failed to sync scan record to Firestore: $error');
    }
  }

  String _buildQuestionnaireSummary({
    required bool recentChangeObserved,
    required bool familyHistoryReported,
    required bool priorSkinCancerReported,
    required bool newOrGrowingLesionObserved,
    required bool borderColorChangeObserved,
    required bool lesionSymptomsObserved,
  }) {
    final factors = <String>[
      if (recentChangeObserved) 'recent visible change',
      if (newOrGrowingLesionObserved) 'new or growing lesion',
      if (borderColorChangeObserved) 'border, shape, or color change',
      if (lesionSymptomsObserved) 'itching, pain, bleeding, or crusting',
      if (familyHistoryReported) 'family history reported',
      if (priorSkinCancerReported) 'prior skin cancer concern reported',
    ];

    if (factors.isEmpty) {
      return 'No additional scan questionnaire risk flags were selected.';
    }

    return 'Scan questionnaire flags: ${factors.join(', ')}.';
  }

  SelectedScanImage _buildIllustrationUploadAsset({
    required SelectedScanImage selectedImage,
    required ScanPredictionResult prediction,
  }) {
    if (!prediction.hasIllustration) {
      throw const AppFlowException(
        'No generated lesion illustration is available to save yet.',
      );
    }

    final originalName = selectedImage.name;
    final dotIndex = originalName.lastIndexOf('.');
    final baseName = dotIndex == -1
        ? originalName
        : originalName.substring(0, dotIndex);
    final generatedName = prediction.illustrationFilename.trim().isEmpty
        ? '${baseName}_lesion_illustration.png'
        : prediction.illustrationFilename.trim();

    return SelectedScanImage(
      id: '${selectedImage.id}-illustration',
      name: generatedName,
      path: null,
      bytes: prediction.illustrationBytes!,
      source: selectedImage.source,
    );
  }

  Future<UploadedScanImage> _uploadScanImage({
    required String uid,
    required SelectedScanImage selectedImage,
    required String assetFolder,
    required String assetRole,
    required String failureLabel,
  }) async {
    try {
      return await _scanImageStorageService.uploadImage(
        uid: uid,
        image: selectedImage,
        assetFolder: assetFolder,
        assetRole: assetRole,
      );
    } catch (error) {
      debugPrint('Failed to save scan image locally: $error');
      throw AppFlowException(
        'Unable to save the $failureLabel on this device.',
      );
    }
  }

  Future<void> _applyFirebaseUser(
    User? firebaseUser, {
    required bool persistProfile,
  }) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _scanRecords = const <ScanRecord>[];
      _notify();
      return;
    }

    final user = _userFromFirebase(firebaseUser);
    _currentUser = user;
    _notify();

    unawaited(
      _refreshSignedInUserData(user: user, persistProfile: persistProfile),
    );
  }

  Future<void> _refreshSignedInUserData({
    required AppUser user,
    required bool persistProfile,
  }) async {
    var activeUser = user;
    final savedProfile = await _safeFetchProfile(user.uid);
    if (savedProfile != null) {
      activeUser = _userFromProfile(user, savedProfile);
    }

    if (_currentUser?.uid == user.uid) {
      _currentUser = activeUser;
      _notify();
    }

    await _loadScanRecordsForUser(activeUser.uid);
    if (_currentUser?.uid == user.uid) {
      _notify();
    }

    if (persistProfile) {
      await _safeUpsertProfile(activeUser);
    }
  }

  AppUser _userFromFirebase(User firebaseUser, {String? preferredName}) {
    final email = firebaseUser.email?.trim() ?? '';
    final displayName = preferredName?.trim().isNotEmpty == true
        ? preferredName!.trim()
        : firebaseUser.displayName?.trim() ?? '';

    return AppUser(
      uid: firebaseUser.uid,
      name: displayName.isEmpty ? _nameFromEmail(email) : displayName,
      email: email,
    );
  }

  AppUser _userFromProfile(AppUser fallback, AppUserProfile profile) {
    return fallback.copyWith(
      name: profile.name.trim().isEmpty ? fallback.name : profile.name.trim(),
      email: profile.email.trim().isEmpty
          ? fallback.email
          : profile.email.trim(),
      age: profile.age,
      contact: profile.contact,
      skinReaction: profile.skinReaction,
      manyMolesReported: profile.manyMolesReported,
      sunburnOrTanningHistoryReported: profile.sunburnOrTanningHistoryReported,
      familySkinCancerHistoryReported: profile.familySkinCancerHistoryReported,
      previousSkinCancerHistoryReported:
          profile.previousSkinCancerHistoryReported,
    );
  }

  Future<AppUserProfile?> _safeFetchProfile(String uid) async {
    try {
      return await _userProfileStore.fetchProfile(uid);
    } catch (error) {
      debugPrint('Failed to load Firestore profile: $error');
      return null;
    }
  }

  Future<void> _safeUpsertProfile(AppUser user) async {
    try {
      await _userProfileStore.upsertProfile(
        AppUserProfile(
          uid: user.uid,
          name: user.name,
          email: user.email,
          age: user.age,
          contact: user.contact,
          skinReaction: user.skinReaction,
          manyMolesReported: user.manyMolesReported,
          sunburnOrTanningHistoryReported: user.sunburnOrTanningHistoryReported,
          familySkinCancerHistoryReported: user.familySkinCancerHistoryReported,
          previousSkinCancerHistoryReported:
              user.previousSkinCancerHistoryReported,
        ),
      );
    } catch (error) {
      debugPrint('Failed to sync Firestore profile: $error');
    }
  }

  Future<void> _loadScanRecordsForUser(String uid) async {
    try {
      _scanRecords = await _scanRecordStore.fetchRecords(uid);
    } catch (error) {
      debugPrint('Failed to load scan records: $error');
      _scanRecords = const <ScanRecord>[];
    }
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<FrontendAuthController> {
  const AuthScope({
    super.key,
    required FrontendAuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static FrontendAuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree.');
    return scope!.notifier!;
  }
}

class AppPalette {
  static const canvas = Color(0xFFF6FCFC);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF082C36);
  static const muted = Color(0xFF62828C);
  static const line = Color(0xFFD8ECEE);
  static const primary = Color(0xFF087E93);
  static const blush = Color(0xFF2F80ED);
  static const blushSoft = Color(0xFFE8F3FF);
  static const peach = Color(0xFF66E0CF);
  static const cream = Color(0xFFF0FBF7);
  static const aqua = Color(0xFF0DB7A6);
  static const primarySoft = Color(0xFFE3F5F7);
  static const success = Color(0xFF129763);
  static const successSoft = Color(0xFFE5F8F0);
  static const danger = Color(0xFFD94E5D);
  static const warning = Color(0xFFE29422);
  static const shadow = Color(0x1714343C);
  static const darkCanvas = Color(0xFF06161B);
  static const darkSurface = Color(0xFF0A2229);
  static const darkSurfaceHigh = Color(0xFF10343E);
  static const darkInk = Color(0xFFEAFBFC);
  static const darkMuted = Color(0xFFA8C2C8);
  static const darkLine = Color(0xFF244E57);
  static const darkPrimary = Color(0xFF45D6CF);
  static const darkPrimarySoft = Color(0xFF123D45);
  static const darkShadow = Color(0x73000000);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color surfaceFor(BuildContext context) {
    return isDark(context) ? darkSurface : surface;
  }

  static Color inkFor(BuildContext context) {
    return isDark(context) ? darkInk : ink;
  }

  static Color mutedFor(BuildContext context) {
    return isDark(context) ? darkMuted : muted;
  }

  static Color lineFor(BuildContext context) {
    return isDark(context) ? darkLine : line;
  }

  static Color primaryFor(BuildContext context) {
    return isDark(context) ? darkPrimary : primary;
  }

  static Color primarySoftFor(BuildContext context) {
    return isDark(context) ? darkPrimarySoft : primarySoft;
  }

  static Color shadowFor(BuildContext context) {
    return isDark(context) ? darkShadow : shadow;
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

const List<OnboardingSlide> kOnboardingSlides = [
  OnboardingSlide(
    title: 'AI Skin Scanning',
    description:
        'SkinSafe introduces a calm AI-supported scan flow that helps users prepare for future checks.',
    icon: Icons.psychology_alt_rounded,
    accent: AppPalette.primary,
  ),
  OnboardingSlide(
    title: 'Guided Capture',
    description:
        'The app teaches users to hold the phone steady and frame skin images clearly before capture.',
    icon: Icons.center_focus_strong_rounded,
    accent: AppPalette.aqua,
  ),
  OnboardingSlide(
    title: 'History Tracking',
    description:
        'Future lesion history can be reviewed over time so changes are easier to compare and discuss.',
    icon: Icons.timeline_rounded,
    accent: AppPalette.blush,
  ),
  OnboardingSlide(
    title: 'Ethical Result Delivery',
    description:
        'Result language stays supportive and action-focused, helping users move forward without panic.',
    icon: Icons.favorite_outline_rounded,
    accent: AppPalette.success,
  ),
];

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppPalette.canvas,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isCompleting) {
      return;
    }

    setState(() => _isCompleting = true);
    await AuthScope.of(context).completeOnboarding();
    if (mounted) {
      setState(() => _isCompleting = false);
    }
  }

  Future<void> _handleNext() async {
    if (_currentPage == kOnboardingSlides.length - 1) {
      await _finishOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleSkip() async {
    await _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppPremiumBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    const CompactBrand(),
                    const Spacer(),
                    TextButton(
                      onPressed: _isCompleting ? null : _handleSkip,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: kOnboardingSlides.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return OnboardingCard(slide: kOnboardingSlides[index]);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    kOnboardingSlides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == _currentPage ? 24 : 8,
                      height: 8,
                      margin: EdgeInsets.only(
                        right: index == kOnboardingSlides.length - 1 ? 0 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? AppPalette.primary
                            : const Color(0xFFD6E3EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _currentPage == kOnboardingSlides.length - 1
                      ? 'Get Started'
                      : 'Next',
                  isLoading: _isCompleting,
                  onPressed: () {
                    unawaited(_handleNext());
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'First-time app tutorial',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email address.';
    }
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Enter your password.';
    }
    if (password.length < 6) {
      return 'Password should be at least 6 characters.';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthScope.of(context).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AppAuthException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context, error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppPremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CompactBrand(),
                  const SizedBox(height: 32),
                  Text('Welcome Back.', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in with your email and password to access your SkinSafe account.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Text('Email Address', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('Password', style: theme.textTheme.labelLarge),
                      const Spacer(),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).push(
                                _buildRoute(
                                  ForgotPasswordScreen(
                                    initialEmail: _emailController.text.trim(),
                                  ),
                                ),
                              ),
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    hint: 'Enter your password',
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppPalette.muted,
                      ),
                    ),
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                    label: 'Sign In',
                    isLoading: _isSubmitting,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Need a new account? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).push(_buildRoute(const SignUpScreen())),
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const List<String> _skinReactionOptions = <String>[
    'Not specified',
    'Burns or freckles easily',
    'Tans gradually',
    'Rarely burns',
    'Unsure',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _skinReaction = _skinReactionOptions.first;
  bool _manyMolesReported = false;
  bool _sunburnOrTanningHistoryReported = false;
  bool _familySkinCancerHistoryReported = false;
  bool _previousSkinCancerHistoryReported = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Enter your full name.';
    }
    if (name.length < 3) {
      return 'Name should be at least 3 characters.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email address.';
    }
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateAge(String? value) {
    final age = value?.trim() ?? '';
    if (age.isEmpty) {
      return 'Enter the patient age.';
    }
    final parsedAge = int.tryParse(age);
    if (parsedAge == null || parsedAge < 1 || parsedAge > 120) {
      return 'Enter a valid age.';
    }
    return null;
  }

  String? _validateContact(String? value) {
    final contact = value?.trim() ?? '';
    if (contact.isEmpty) {
      return 'Enter a contact number or patient ID.';
    }
    if (contact.length < 5) {
      return 'Contact should be at least 5 characters.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Create a password.';
    }
    if (password.length < 6) {
      return 'Password should be at least 6 characters.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthScope.of(context).signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        age: _ageController.text.trim(),
        contact: _contactController.text.trim(),
        skinReaction: _skinReaction,
        manyMolesReported: _manyMolesReported,
        sunburnOrTanningHistoryReported: _sunburnOrTanningHistoryReported,
        familySkinCancerHistoryReported: _familySkinCancerHistoryReported,
        previousSkinCancerHistoryReported: _previousSkinCancerHistoryReported,
      );
      if (!mounted) {
        return;
      }
      _showMessage(context, 'Account created successfully. Please sign in.');
      Navigator.of(context).pop();
    } on AppAuthException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context, error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppPremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTopBar(
                    title: 'Create Account',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Register your SkinSafe account.',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create an account and save the baseline patient details used during future scans.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Text('Full Name', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                    hint: 'Enter your full name',
                    validator: _validateName,
                  ),
                  const SizedBox(height: 18),
                  Text('Email Address', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Patient Baseline Profile',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These details auto-fill the first scan step and help the app explain follow-up context safely.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          controller: _ageController,
                          icon: Icons.cake_outlined,
                          hint: 'Age',
                          keyboardType: TextInputType.number,
                          validator: _validateAge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AuthTextField(
                          controller: _contactController,
                          icon: Icons.badge_outlined,
                          hint: 'Phone or patient ID',
                          keyboardType: TextInputType.phone,
                          validator: _validateContact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _skinReaction,
                    items: _skinReactionOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Skin reaction in sunlight',
                      prefixIcon: Icon(Icons.wb_sunny_outlined),
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _skinReaction = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  QuestionnaireToggleTile(
                    title: 'Many or unusual moles',
                    description:
                        'Select this if the patient has many moles or moles that look unusually shaped.',
                    value: _manyMolesReported,
                    onChanged: (value) {
                      setState(() => _manyMolesReported = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  QuestionnaireToggleTile(
                    title: 'Sunburn or tanning history',
                    description:
                        'Select this if the patient has a history of sunburns, tanning beds, or frequent tanning.',
                    value: _sunburnOrTanningHistoryReported,
                    onChanged: (value) {
                      setState(() => _sunburnOrTanningHistoryReported = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  QuestionnaireToggleTile(
                    title: 'Family skin cancer history',
                    description:
                        'Select this if a close family member has had melanoma or another skin cancer.',
                    value: _familySkinCancerHistoryReported,
                    onChanged: (value) {
                      setState(() => _familySkinCancerHistoryReported = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  QuestionnaireToggleTile(
                    title: 'Previous skin cancer concern',
                    description:
                        'Select this if the patient was previously treated, monitored, or warned about skin cancer.',
                    value: _previousSkinCancerHistoryReported,
                    onChanged: (value) {
                      setState(
                        () => _previousSkinCancerHistoryReported = value,
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('Password', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    hint: 'Create a password',
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppPalette.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Confirm Password', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    icon: Icons.lock_outline_rounded,
                    hint: 'Re-enter your password',
                    obscureText: _obscureConfirmPassword,
                    validator: _validateConfirmPassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppPalette.muted,
                      ),
                    ),
                    onFieldSubmitted: (_) => _handleSignUp(),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                    label: 'Create Account',
                    isLoading: _isSubmitting,
                    onPressed: _handleSignUp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email address.';
    }
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _handleReset() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthScope.of(
        context,
      ).sendPasswordReset(email: _emailController.text.trim());
      if (!mounted) {
        return;
      }
      _showMessage(context, 'Password reset email sent.');
      Navigator.of(context).pop();
    } on AppAuthException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context, error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppPremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTopBar(
                    title: 'Forgot Password',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reset your password.',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your account email and we will send a reset link.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Text('Email Address', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => _handleReset(),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                    label: 'Send Reset Link',
                    isLoading: _isSubmitting,
                    onPressed: _handleReset,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  final MedicalSafetyStore _medicalSafetyStore =
      SharedPreferencesMedicalSafetyStore();
  int _currentIndex = 0;
  String? _draftBodyArea;
  bool _isDisclosureReady = false;
  bool _hasAcceptedMedicalDisclosure = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMedicalDisclosureState());
  }

  Future<void> _loadMedicalDisclosureState() async {
    final accepted = await _medicalSafetyStore.loadAccepted();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasAcceptedMedicalDisclosure = accepted;
      _isDisclosureReady = true;
    });
  }

  Future<void> _acceptMedicalDisclosure() async {
    await _medicalSafetyStore.saveAccepted(true);
    if (!mounted) {
      return;
    }
    setState(() {
      _hasAcceptedMedicalDisclosure = true;
      _isDisclosureReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;

    if (!_isDisclosureReady) {
      return const LoadingScreen();
    }

    if (!_hasAcceptedMedicalDisclosure) {
      return MedicalSafetyDisclosureScreen(onAccept: _acceptMedicalDisclosure);
    }

    final pages = <Widget>[
      HomeDashboardPage(user: user, records: auth.scanRecords),
      ScanWorkspacePage(
        currentUser: user,
        records: auth.scanRecords,
        initialBodyArea: _draftBodyArea,
        onOpenHistory: () {
          setState(() => _currentIndex = 2);
        },
        onConsumeInitialBodyArea: () {
          if (_draftBodyArea != null) {
            setState(() => _draftBodyArea = null);
          }
        },
      ),
      HistoryOverviewPage(
        records: auth.scanRecords,
        onAddBodyArea: (bodyArea) {
          setState(() {
            _draftBodyArea = bodyArea;
            _currentIndex = 1;
          });
        },
      ),
      const LearnOverviewPage(),
      ProfileOverviewPage(user: user),
    ];

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AppPremiumBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(index: _currentIndex, children: pages),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PremiumBottomNav(
                selectedIndex: _currentIndex,
                onSelected: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumBottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PremiumBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<PremiumBottomNav> createState() => _PremiumBottomNavState();
}

class _PremiumBottomNavState extends State<PremiumBottomNav> {
  double? _dragPositionX;

  static const _items = <_PremiumNavItem>[
    _PremiumNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _PremiumNavItem(
      icon: Icons.center_focus_strong_outlined,
      activeIcon: Icons.center_focus_strong_rounded,
      label: 'Scan',
    ),
    _PremiumNavItem(
      icon: Icons.history_rounded,
      activeIcon: Icons.history_toggle_off_rounded,
      label: 'History',
    ),
    _PremiumNavItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Learn',
    ),
    _PremiumNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  int _indexForPosition(double positionX, double width) {
    final itemWidth = width / _items.length;
    return (positionX / itemWidth).floor().clamp(0, _items.length - 1);
  }

  void _updateDragPosition(Offset localPosition, double width) {
    setState(() {
      _dragPositionX = localPosition.dx.clamp(0.0, width);
    });
  }

  void _finishDrag(double width) {
    final targetIndex = _indexForPosition(
      _dragPositionX ?? width * (widget.selectedIndex + 0.5) / _items.length,
      width,
    );
    setState(() => _dragPositionX = null);
    widget.onSelected(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: SizedBox(
        height: 82,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / _items.length;
            final indicatorWidth = math.min(100.0, itemWidth + 24);
            final dragPositionX = _dragPositionX;
            final activeIndex = dragPositionX == null
                ? widget.selectedIndex
                : _indexForPosition(dragPositionX, constraints.maxWidth);
            final indicatorCenter =
                dragPositionX ??
                (itemWidth * widget.selectedIndex) + (itemWidth / 2);
            final rawLeft = indicatorCenter - (indicatorWidth / 2);
            final indicatorLeft = rawLeft.clamp(
              -8.0,
              constraints.maxWidth - indicatorWidth + 8,
            );

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (details) {
                _updateDragPosition(
                  details.localPosition,
                  constraints.maxWidth,
                );
              },
              onHorizontalDragUpdate: (details) {
                _updateDragPosition(
                  details.localPosition,
                  constraints.maxWidth,
                );
              },
              onHorizontalDragEnd: (_) => _finishDrag(constraints.maxWidth),
              onHorizontalDragCancel: () {
                setState(() => _dragPositionX = null);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                        child: Container(
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      const Color(
                                        0xFF06161B,
                                      ).withValues(alpha: 0.62),
                                      const Color(
                                        0xFF0C3B42,
                                      ).withValues(alpha: 0.48),
                                    ]
                                  : [
                                      const Color(
                                        0xFF04343C,
                                      ).withValues(alpha: 0.64),
                                      const Color(
                                        0xFF0D7E86,
                                      ).withValues(alpha: 0.48),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.22 : 0.48,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.primaryFor(
                                  context,
                                ).withValues(alpha: isDark ? 0.30 : 0.22),
                                blurRadius: 34,
                                offset: const Offset(0, 16),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(
                                  alpha: isDark ? 0.03 : 0.18,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: Duration(
                      milliseconds: dragPositionX == null ? 330 : 80,
                    ),
                    curve: Curves.easeOutCubic,
                    left: indicatorLeft,
                    bottom: -5,
                    width: indicatorWidth,
                    height: 82,
                    child: _LiquidNavBubble(
                      item: _items[activeIndex],
                      isDragging: dragPositionX != null,
                    ),
                  ),
                  Positioned.fill(
                    bottom: 0,
                    child: Row(
                      children: [
                        for (var index = 0; index < _items.length; index++)
                          Expanded(
                            child: _PremiumNavButton(
                              item: _items[index],
                              selected: activeIndex == index,
                              onTap: () => widget.onSelected(index),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiquidNavBubble extends StatelessWidget {
  final _PremiumNavItem item;
  final bool isDragging;

  const _LiquidNavBubble({required this.item, required this.isDragging});

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return IgnorePointer(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: isDragging ? 1.09 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(42),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primaryFor(
                        context,
                      ).withValues(alpha: isDark ? 0.40 : 0.30),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.05 : 0.28,
                      ),
                      blurRadius: 12,
                      offset: const Offset(-6, -8),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(42),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 38, sigmaY: 38),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(42),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: isDark ? 0.26 : 0.54),
                          AppPalette.primaryFor(
                            context,
                          ).withValues(alpha: isDark ? 0.18 : 0.16),
                          AppPalette.aqua.withValues(
                            alpha: isDark ? 0.18 : 0.14,
                          ),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.52 : 0.82,
                        ),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 18,
              right: 24,
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.86),
                      AppPalette.aqua.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 14,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.42),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF06323A).withValues(alpha: 0.82),
                            const Color(0xFF0B6C72).withValues(alpha: 0.68),
                          ]
                        : [
                            const Color(0xFF05606C).withValues(alpha: 0.88),
                            const Color(0xFF0EA6A7).withValues(alpha: 0.72),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.aqua.withValues(
                        alpha: isDark ? 0.28 : 0.24,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.activeIcon, color: Colors.white, size: 23),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 11,
              child: Container(
                width: 30,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 18,
              child: Container(
                width: 5,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _PremiumNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _PremiumNavButton extends StatelessWidget {
  final _PremiumNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _PremiumNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: selected ? 0 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: Colors.white.withValues(alpha: 0.70),
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeDashboardPage extends StatelessWidget {
  static const FollowUpPlanService _followUpPlanService = FollowUpPlanService();
  final AppUser? user;
  final List<ScanRecord> records;

  const HomeDashboardPage({
    super.key,
    required this.user,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final scanRecordCount = records.length;
    final followUpPlan = _followUpPlanService.buildFromRecords(records);

    return AppShellPageLayout(
      title: 'Hello, ${user?.firstName ?? 'User'}',
      subtitle:
          'Use the app to start a guided scan, review saved history, and learn what to watch over time.',
      headerTrailing: UserAvatarBadge(initials: user?.initials ?? 'SS'),
      children: [
        if (followUpPlan != null) ...[
          FollowUpPlanCard(plan: followUpPlan),
          const SizedBox(height: 18),
        ],
        HomeHeroCard(
          scanRecordCount: scanRecordCount,
          latestRecord: records.isEmpty ? null : records.first,
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick start',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const StatusLine(
                icon: Icons.center_focus_strong_rounded,
                title: 'Begin a new scan',
                value:
                    'Open the Scan tab to start a guided check step by step.',
                tint: AppPalette.primary,
              ),
              const SizedBox(height: 12),
              StatusLine(
                icon: Icons.history_rounded,
                title: 'Check saved history',
                value: scanRecordCount == 0
                    ? 'No saved scans yet. Your future scan records will appear there.'
                    : '$scanRecordCount saved scan${scanRecordCount == 1 ? '' : 's'} available in History.',
                tint: AppPalette.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What to focus on',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const StatusLine(
                icon: Icons.photo_camera_back_outlined,
                title: 'Take a clear photo',
                value:
                    'Use good lighting and keep the lesion steady before continuing.',
                tint: AppPalette.aqua,
              ),
              const SizedBox(height: 12),
              const StatusLine(
                icon: Icons.timeline_rounded,
                title: 'Track the same spot over time',
                value:
                    'Use the same body area and lesion label so follow-up reviews stay organized.',
                tint: AppPalette.success,
              ),
              const SizedBox(height: 12),
              const StatusLine(
                icon: Icons.menu_book_rounded,
                title: 'Read simple guidance',
                value:
                    'Open Learn to review ABCDE signs and prevention tips in plain language.',
                tint: AppPalette.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FollowUpPlanCard extends StatelessWidget {
  final FollowUpPlan plan;

  const FollowUpPlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final accent = plan.isDueNow ? AppPalette.danger : AppPalette.success;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.event_available_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next follow-up',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.urgencyLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailRow(label: 'Patient', value: plan.patientName),
          const SizedBox(height: 10),
          DetailRow(
            label: 'Focus area',
            value: '${plan.bodyArea} - ${plan.lesionLabel}',
          ),
          const SizedBox(height: 10),
          DetailRow(
            label: 'Based on',
            value: _formatDateLabel(plan.basedOnDate),
          ),
          const SizedBox(height: 10),
          DetailRow(
            label: 'Suggested next check',
            value: _formatDateLabel(plan.nextReviewDate),
          ),
          const SizedBox(height: 12),
          Text(plan.summary, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class HomeHeroCard extends StatelessWidget {
  final int scanRecordCount;
  final ScanRecord? latestRecord;

  const HomeHeroCard({
    super.key,
    required this.scanRecordCount,
    required this.latestRecord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppPalette.isDark(context);
    final latestStatus = latestRecord?.status ?? 'Ready';
    final latestArea = latestRecord?.bodyArea ?? 'New scan';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  AppPalette.darkSurfaceHigh,
                  Color(0xFF103D45),
                  Color(0xFF08191C),
                ]
              : const [AppPalette.blushSoft, AppPalette.cream, Colors.white],
          stops: const [0.0, 0.56, 1.0],
        ),
        border: Border.all(
          color: isDark
              ? AppPalette.darkLine.withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: 0.86),
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.shadowFor(context),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 15,
                      color: AppPalette.primaryFor(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI skin check',
                      style: TextStyle(
                        color: AppPalette.inkFor(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppPalette.primaryFor(context),
                  foregroundColor: isDark
                      ? AppPalette.darkCanvas
                      : Colors.white,
                ),
                onPressed: () {},
                icon: const Icon(Icons.arrow_outward_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Check your skin health',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 36),
          ),
          const SizedBox(height: 18),
          _MiniSkinTrendBars(count: scanRecordCount),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetricTile(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Scans',
                  value: scanRecordCount.toString(),
                  tint: AppPalette.primaryFor(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetricTile(
                  icon: Icons.monitor_heart_outlined,
                  label: latestArea,
                  value: latestStatus,
                  tint: AppPalette.aqua,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSkinTrendBars extends StatelessWidget {
  final int count;

  const _MiniSkinTrendBars({required this.count});

  @override
  Widget build(BuildContext context) {
    final bars = <double>[0.46, 0.64, 0.52, 0.78, 0.42, 0.88, 0.58];
    final activeIndex = count == 0 ? 1 : count.clamp(1, bars.length) - 1;
    final isDark = AppPalette.isDark(context);

    return Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < bars.length; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                height: 72 * bars[index],
                decoration: BoxDecoration(
                  color: index == activeIndex
                      ? AppPalette.primaryFor(context)
                      : AppPalette.inkFor(context).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (index != bars.length - 1) const SizedBox(width: 9),
          ],
        ],
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _HeroMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(height: 18),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 23,
              color: AppPalette.inkFor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.mutedFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class MedicalSafetyDisclosureScreen extends StatelessWidget {
  final Future<void> Function() onAccept;

  const MedicalSafetyDisclosureScreen({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppPremiumBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CompactBrand(),
                const SizedBox(height: 28),
                Text(
                  'Before you continue',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'SkinSafe provides screening support only. It does not replace a doctor, a dermatologist, or emergency medical care.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusLine(
                        icon: Icons.info_outline_rounded,
                        title: 'Use carefully',
                        value:
                            'Results are guidance for follow-up and self-monitoring, not a confirmed diagnosis.',
                        tint: AppPalette.primary,
                      ),
                      SizedBox(height: 12),
                      StatusLine(
                        icon: Icons.local_hospital_outlined,
                        title: 'See a clinician when concerned',
                        value:
                            'If a lesion is bleeding, rapidly changing, painful, or worrying, seek professional care promptly.',
                        tint: AppPalette.danger,
                      ),
                      SizedBox(height: 12),
                      StatusLine(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Your data',
                        value:
                            'Photos and scan history are stored to support follow-up tracking. Review privacy details in Profile.',
                        tint: AppPalette.success,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'I Understand and Continue',
                  isLoading: false,
                  onPressed: onAccept,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ScanFlowStage { prep, analyzing, result }

class ScanWorkspacePage extends StatefulWidget {
  final AppUser? currentUser;
  final List<ScanRecord> records;
  final String? initialBodyArea;
  final VoidCallback onOpenHistory;
  final VoidCallback onConsumeInitialBodyArea;

  const ScanWorkspacePage({
    super.key,
    required this.currentUser,
    required this.records,
    required this.initialBodyArea,
    required this.onOpenHistory,
    required this.onConsumeInitialBodyArea,
  });

  @override
  State<ScanWorkspacePage> createState() => _ScanWorkspacePageState();
}

class _ScanWorkspacePageState extends State<ScanWorkspacePage> {
  static const LesionTrackingService _lesionTrackingService =
      LesionTrackingService();
  static const String _newLesionSpotOption = 'New lesion spot';
  static const List<String> _bodyAreas = <String>[
    'Face',
    'Scalp',
    'Neck',
    'Chest',
    'Back',
    'Abdomen',
    'Left Arm',
    'Right Arm',
    'Left Hand',
    'Right Hand',
    'Left Leg',
    'Right Leg',
    'Left Foot',
    'Right Foot',
    'Other',
  ];
  static const List<String> _analysisSteps = [
    'Checking photo quality',
    'Preparing the lesion image',
    'Running the on-device AI model',
    'Calibrating the patient-safe result',
  ];

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientAgeController = TextEditingController();
  final TextEditingController _patientContactController =
      TextEditingController();
  String _selectedBodyArea = 'Left Arm';
  String _selectedPatientName = 'New patient';
  String _selectedLesionSpot = _newLesionSpotOption;
  ScanFlowStage _stage = ScanFlowStage.prep;
  SelectedScanImage? _selectedImage;
  ScanPredictionResult? _predictionResult;
  String? _analysisErrorMessage;
  bool _autoScanEnabled = true;
  bool _flashEnabled = false;
  bool _ghostOutlineEnabled = true;
  bool _recentChangeObserved = false;
  bool _newOrGrowingLesionObserved = false;
  bool _borderColorChangeObserved = false;
  bool _lesionSymptomsObserved = false;
  bool _familyHistoryReported = false;
  bool _priorSkinCancerReported = false;
  int _analysisStepIndex = 0;
  int _prepStepIndex = 0;
  bool _isPickingImage = false;
  bool _isAnalyzingPrediction = false;
  bool _isSavingResult = false;
  bool _hasSavedCurrentResult = false;
  bool _showVisualBodyAreaPicker = false;
  bool _followUpReminderEnabled = true;
  int _followUpReminderDays = 7;
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    _prefillCurrentUser();
    _applyInitialBodyArea();
  }

  @override
  void didUpdateWidget(covariant ScanWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBodyArea != oldWidget.initialBodyArea) {
      _applyInitialBodyArea();
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _locationController.dispose();
    _noteController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientContactController.dispose();
    super.dispose();
  }

  void _prefillCurrentUser() {
    final currentUser = widget.currentUser;
    if (currentUser == null) {
      return;
    }
    _patientNameController.text = currentUser.name;
    _patientAgeController.text = currentUser.age;
    _patientContactController.text = currentUser.contact;
    _selectedPatientName = currentUser.name;
    _familyHistoryReported = currentUser.familySkinCancerHistoryReported;
    _priorSkinCancerReported = currentUser.previousSkinCancerHistoryReported;
  }

  void _applyInitialBodyArea() {
    final initialBodyArea = widget.initialBodyArea;
    if (initialBodyArea != null && initialBodyArea.trim().isNotEmpty) {
      _selectedBodyArea = initialBodyArea;
      _selectedLesionSpot = _newLesionSpotOption;
      _locationController.clear();
      widget.onConsumeInitialBodyArea();
    }
  }

  List<String> get _patientNames {
    final existingPatients =
        widget.records
            .map((record) => record.patientName.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return <String>[
      'New patient',
      if (_patientNameController.text.trim().isNotEmpty &&
          !existingPatients.contains(_patientNameController.text.trim()))
        _patientNameController.text.trim(),
      ...existingPatients,
    ];
  }

  List<String> get _lesionSpotOptions {
    final patientName = _patientNameController.text.trim();
    final existingSpots =
        widget.records
            .where(
              (record) =>
                  record.patientName.trim() == patientName &&
                  record.bodyArea.trim() == _selectedBodyArea,
            )
            .map((record) => record.location.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return <String>[_newLesionSpotOption, ...existingSpots];
  }

  ScanRecord? get _followUpReferenceRecord {
    final patientName = _patientNameController.text.trim();
    final lesionLabel = _locationController.text.trim();
    if (patientName.isEmpty || lesionLabel.isEmpty || !_ghostOutlineEnabled) {
      return null;
    }

    return _lesionTrackingService.latestFollowUpReference(
      records: widget.records,
      patientName: patientName,
      bodyArea: _selectedBodyArea,
      lesionLabel: lesionLabel,
    );
  }

  void _applyPatientSelection(String patientName) {
    final currentUser = widget.currentUser;
    setState(() {
      _selectedPatientName = patientName;
      _recentChangeObserved = false;
      _newOrGrowingLesionObserved = false;
      _borderColorChangeObserved = false;
      _lesionSymptomsObserved = false;
      _selectedLesionSpot = _newLesionSpotOption;
      _locationController.clear();
    });

    if (patientName == 'New patient') {
      _patientNameController.clear();
      _patientAgeController.clear();
      _patientContactController.clear();
      setState(() {
        _familyHistoryReported = false;
        _priorSkinCancerReported = false;
      });
      return;
    }

    if (currentUser != null && patientName == currentUser.name) {
      _patientNameController.text = currentUser.name;
      _patientAgeController.text = currentUser.age;
      _patientContactController.text = currentUser.contact;
      setState(() {
        _familyHistoryReported = currentUser.familySkinCancerHistoryReported;
        _priorSkinCancerReported =
            currentUser.previousSkinCancerHistoryReported;
      });
      return;
    }

    final matchingRecords =
        widget.records
            .where((record) => record.patientName == patientName)
            .toList()
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    final latestRecord = matchingRecords.isEmpty ? null : matchingRecords.first;

    _patientNameController.text = patientName;
    _patientAgeController.text = latestRecord?.patientAge ?? '';
    _patientContactController.text = latestRecord?.patientContact ?? '';
    setState(() {
      _familyHistoryReported = latestRecord?.familyHistoryReported ?? false;
      _priorSkinCancerReported = latestRecord?.priorSkinCancerReported ?? false;
    });
  }

  void _setSelectedBodyArea(String bodyArea) {
    setState(() {
      _selectedBodyArea = bodyArea;
      _selectedLesionSpot = _newLesionSpotOption;
      _locationController.clear();
    });
  }

  void _applyLesionSpotSelection(String lesionSpot) {
    setState(() {
      _selectedLesionSpot = lesionSpot;
      if (lesionSpot == _newLesionSpotOption) {
        _locationController.clear();
      } else {
        _locationController.text = lesionSpot;
      }
    });
  }

  void _goToPrepStep(int stepIndex) {
    setState(() => _prepStepIndex = stepIndex.clamp(0, 3));
  }

  DateTime get _selectedFollowUpReminderDate {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: _followUpReminderDays));
  }

  void _configureDefaultFollowUpReminder(ScanPredictionResult prediction) {
    final status = prediction.status.toLowerCase();

    if (status.contains('retake') || status.contains('specialist')) {
      _followUpReminderEnabled = false;
      _followUpReminderDays = 7;
      return;
    }

    _followUpReminderEnabled = true;
    if (status.contains('caution')) {
      _followUpReminderDays = 7;
    } else if (status.contains('monitor')) {
      _followUpReminderDays = 14;
    } else {
      _followUpReminderDays = 30;
    }

    if (_riskContextFlagCount >= 3 && _followUpReminderDays > 14) {
      _followUpReminderDays = 14;
    }
  }

  bool _canScheduleFollowUpReminder(ScanPredictionResult prediction) {
    final status = prediction.status.toLowerCase();
    return !status.contains('retake') && !status.contains('specialist');
  }

  bool _shouldShowResultVisual(ScanPredictionResult? prediction) {
    if (prediction == null) {
      return _selectedImage != null;
    }
    if (_isLowRiskNonMelanomaResult(prediction)) {
      return false;
    }
    return prediction.hasIllustration || _selectedImage != null;
  }

  String _buildFollowUpReminderReason() {
    final lesionLabel = _locationController.text.trim().isEmpty
        ? 'this lesion'
        : _locationController.text.trim();
    return 'Re-scan $lesionLabel in $_followUpReminderDays days using the same body area and spot label for visual comparison. This reminder does not replace medical care.';
  }

  AppUser? get _activeAccountProfileForScan {
    final currentUser = widget.currentUser;
    final patientName = _patientNameController.text.trim();
    if (currentUser == null || patientName.isEmpty) {
      return null;
    }
    return patientName == currentUser.name ? currentUser : null;
  }

  List<String> get _scanQuestionnaireRiskFactors {
    return <String>[
      if (_recentChangeObserved) 'recent visible change',
      if (_newOrGrowingLesionObserved) 'new or growing lesion',
      if (_borderColorChangeObserved) 'border, shape, or color change',
      if (_lesionSymptomsObserved) 'itching, pain, bleeding, or crusting',
      if (_familyHistoryReported) 'family history reported',
      if (_priorSkinCancerReported) 'prior skin cancer concern reported',
    ];
  }

  List<String> get _baselineRiskFactors {
    return _activeAccountProfileForScan?.baselineRiskFactors ??
        const <String>[];
  }

  int get _riskContextFlagCount => <String>{
    ..._baselineRiskFactors,
    ..._scanQuestionnaireRiskFactors,
  }.length;

  String get _baselineRiskSummary {
    final accountProfile = _activeAccountProfileForScan;
    if (accountProfile == null) {
      return 'No saved account baseline profile is attached to this patient.';
    }

    final factors = accountProfile.baselineRiskFactors;
    if (factors.isEmpty) {
      return 'No account baseline risk factors were selected.';
    }

    return 'Account baseline flags: ${factors.join(', ')}.';
  }

  String get _scanQuestionnaireRiskSummary {
    final factors = _scanQuestionnaireRiskFactors;
    if (factors.isEmpty) {
      return 'No additional scan questionnaire risk flags were selected.';
    }

    return 'Scan questionnaire flags: ${factors.join(', ')}.';
  }

  String get _combinedRiskContextSummary {
    final flagCount = _riskContextFlagCount;
    if (flagCount == 0) {
      return 'The app found no extra patient-context flags beyond the image review. Continue routine self-monitoring and seek care if the spot changes.';
    }
    if (flagCount >= 4) {
      return 'Multiple patient-context flags are present. Treat the result more cautiously and prioritize professional review if the lesion continues to change.';
    }
    if (flagCount >= 2) {
      return 'Some patient-context flags are present. Use the saved reminder and compare the same lesion again within the suggested follow-up window.';
    }
    return 'One patient-context flag is present. Keep this baseline result saved and watch for any visible change.';
  }

  bool _validateCurrentPrepStep() {
    if (_prepStepIndex == 0) {
      if (_patientNameController.text.trim().isEmpty) {
        _showMessage(
          context,
          'Enter the patient name before continuing.',
          isError: true,
        );
        return false;
      }
      if (_patientAgeController.text.trim().isEmpty) {
        _showMessage(
          context,
          'Enter the patient age before continuing.',
          isError: true,
        );
        return false;
      }
      if (_patientContactController.text.trim().isEmpty) {
        _showMessage(
          context,
          'Enter a contact number or patient ID before continuing.',
          isError: true,
        );
        return false;
      }
    }

    if (_prepStepIndex == 1) {
      if (_locationController.text.trim().isEmpty) {
        _showMessage(
          context,
          'Enter a lesion label before continuing.',
          isError: true,
        );
        return false;
      }
    }

    if (_prepStepIndex == 3) {
      if (_selectedImage == null) {
        _showMessage(
          context,
          'Capture a photo or choose one from the gallery before continuing.',
          isError: true,
        );
        return false;
      }
    }

    return true;
  }

  void _showPrepStepGuide() {
    final (title, message) = switch (_prepStepIndex) {
      0 => (
        'Patient details guide',
        'Select an existing patient or enter a new patient name first. Add age and contact details if available so future scan history stays organized.',
      ),
      1 => (
        'Lesion area guide',
        'Choose the body area, then give the mole or lesion a clear spot label such as "Mole near left wrist" so it can be identified later.',
      ),
      2 => (
        'Questionnaire guide',
        'Answer the screening questions based on lesion changes, symptoms, family history, and any previous skin cancer concerns. The app compares this with the saved patient baseline profile after the image review.',
      ),
      _ => (
        'Photo capture guide',
        'Take a clear photo or choose one from the gallery. In the live camera screen, the visual rings and stability guidance will appear there only.',
      ),
    };

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ScanImageSource source) async {
    if (_isPickingImage) {
      return;
    }

    setState(() => _isPickingImage = true);
    try {
      final auth = AuthScope.of(context);
      final navigator = Navigator.of(context);
      final image = source == ScanImageSource.camera && !auth.isPreviewMode
          ? await navigator.push<SelectedScanImage>(
              MaterialPageRoute(
                builder: (_) => LiveCameraCaptureScreen(
                  bodyArea: _selectedBodyArea,
                  ghostOutlineEnabled: _ghostOutlineEnabled,
                  flashEnabled: _flashEnabled,
                  autoScanEnabled: _autoScanEnabled,
                  followUpReference: _followUpReferenceRecord,
                ),
              ),
            )
          : await auth.pickScanImage(source);
      if (!mounted || image == null) {
        return;
      }

      setState(() {
        _selectedImage = image;
        _predictionResult = null;
        _analysisErrorMessage = null;
        _hasSavedCurrentResult = false;
        _followUpReminderEnabled = true;
      });

      _showMessage(
        context,
        source == ScanImageSource.camera
            ? 'Photo captured successfully.'
            : 'Photo selected successfully.',
      );
    } on AppFlowException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context, error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _beginAnalysisFlow() {
    _analysisTimer?.cancel();
    setState(() {
      _stage = ScanFlowStage.analyzing;
      _analysisStepIndex = 0;
      _predictionResult = null;
      _analysisErrorMessage = null;
      _isAnalyzingPrediction = true;
      _hasSavedCurrentResult = false;
    });

    _analysisTimer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_analysisStepIndex >= _analysisSteps.length - 1) {
        timer.cancel();
        unawaited(_completeScanAnalysis());
        return;
      }

      setState(() {
        _analysisStepIndex += 1;
      });
    });
  }

  void _startScanProcessing() {
    if (_patientNameController.text.trim().isEmpty) {
      _showMessage(
        context,
        'Enter the patient name before starting the scan.',
        isError: true,
      );
      return;
    }

    if (_locationController.text.trim().isEmpty) {
      _showMessage(
        context,
        'Enter a lesion label before starting the scan.',
        isError: true,
      );
      return;
    }

    if (_selectedImage == null) {
      _showMessage(
        context,
        'Capture a photo or choose one from the gallery before continuing.',
        isError: true,
      );
      return;
    }

    _beginAnalysisFlow();
  }

  void _retryAnalysis() {
    if (_selectedImage == null || _isAnalyzingPrediction) {
      return;
    }

    _beginAnalysisFlow();
  }

  void _returnToPrep() {
    _analysisTimer?.cancel();
    setState(() {
      _stage = ScanFlowStage.prep;
      _analysisStepIndex = 0;
      _predictionResult = null;
      _analysisErrorMessage = null;
      _isAnalyzingPrediction = false;
      _isSavingResult = false;
      _hasSavedCurrentResult = false;
      _showVisualBodyAreaPicker = false;
      _followUpReminderEnabled = true;
    });
  }

  void _resetScan() {
    _analysisTimer?.cancel();
    setState(() {
      _stage = ScanFlowStage.prep;
      _prepStepIndex = 0;
      _analysisStepIndex = 0;
      _selectedImage = null;
      _predictionResult = null;
      _analysisErrorMessage = null;
      _isPickingImage = false;
      _isAnalyzingPrediction = false;
      _isSavingResult = false;
      _hasSavedCurrentResult = false;
      _showVisualBodyAreaPicker = false;
      _followUpReminderEnabled = true;
      _followUpReminderDays = 7;
      _selectedLesionSpot = _newLesionSpotOption;
      _locationController.clear();
      _noteController.clear();
      _recentChangeObserved = false;
      _newOrGrowingLesionObserved = false;
      _borderColorChangeObserved = false;
      _lesionSymptomsObserved = false;
      _familyHistoryReported = false;
      _priorSkinCancerReported = false;
      _autoScanEnabled = true;
      _flashEnabled = false;
      _ghostOutlineEnabled = true;
    });
    _prefillCurrentUser();
  }

  Future<void> _completeScanAnalysis() async {
    final selectedImage = _selectedImage;
    if (selectedImage == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = ScanFlowStage.result;
        _isAnalyzingPrediction = false;
        _analysisErrorMessage = 'No scan image is available for analysis.';
      });
      return;
    }

    try {
      final prediction = await AuthScope.of(
        context,
      ).analyzeCapturedScan(selectedImage: selectedImage);
      if (!mounted) {
        return;
      }
      setState(() {
        _configureDefaultFollowUpReminder(prediction);
        _predictionResult = prediction;
        _analysisErrorMessage = null;
        _isAnalyzingPrediction = false;
        _stage = ScanFlowStage.result;
      });
    } on AppFlowException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _predictionResult = null;
        _analysisErrorMessage = error.message;
        _isAnalyzingPrediction = false;
        _stage = ScanFlowStage.result;
      });
    }
  }

  Future<void> _saveResultToHistory() async {
    final selectedImage = _selectedImage;
    final prediction = _predictionResult;
    if (_isSavingResult ||
        _hasSavedCurrentResult ||
        selectedImage == null ||
        prediction == null) {
      return;
    }

    setState(() => _isSavingResult = true);
    try {
      await AuthScope.of(context).saveCapturedScan(
        patientName: _patientNameController.text,
        patientAge: _patientAgeController.text,
        patientContact: _patientContactController.text,
        bodyArea: _selectedBodyArea,
        location: _locationController.text,
        note: _noteController.text,
        recentChangeObserved: _recentChangeObserved,
        familyHistoryReported: _familyHistoryReported,
        priorSkinCancerReported: _priorSkinCancerReported,
        newOrGrowingLesionObserved: _newOrGrowingLesionObserved,
        borderColorChangeObserved: _borderColorChangeObserved,
        lesionSymptomsObserved: _lesionSymptomsObserved,
        baselineRiskSummary: _baselineRiskSummary,
        combinedRiskSummary: _combinedRiskContextSummary,
        followUpReminderEnabled: _followUpReminderEnabled,
        followUpReminderDays: _followUpReminderDays,
        followUpReminderDate: _followUpReminderEnabled
            ? _selectedFollowUpReminderDate
            : null,
        followUpReminderReason: _followUpReminderEnabled
            ? _buildFollowUpReminderReason()
            : '',
        selectedImage: selectedImage,
        prediction: prediction,
      );
      if (!mounted) {
        return;
      }
      setState(() => _hasSavedCurrentResult = true);
      _showMessage(
        context,
        _followUpReminderEnabled
            ? 'Scan saved with follow-up reminder.'
            : 'Scan saved to local history.',
      );
    } on AppAuthException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context, error.message, isError: true);
    } on AppFlowException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context, error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSavingResult = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prediction = _predictionResult;
    final resultStatusColor = _statusColorForValue(
      prediction?.status ?? 'Analysis unavailable',
    );
    final title = switch (_stage) {
      ScanFlowStage.prep => 'Guided Scan',
      ScanFlowStage.analyzing => 'Processing Scan',
      ScanFlowStage.result =>
        prediction == null ? 'Analysis Result' : 'Analysis Complete',
    };
    final subtitle = switch (_stage) {
      ScanFlowStage.prep => 'Complete the steps to prepare your scan.',
      ScanFlowStage.analyzing =>
        'Preparing your photo for a careful scan review.',
      ScanFlowStage.result =>
        _analysisErrorMessage != null
            ? 'The review could not be completed just yet.'
            : 'Your scan review is ready to save for future comparison.',
    };
    Widget resultFactTile({
      required String label,
      required String value,
      required IconData icon,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceFor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.lineFor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppPalette.primaryFor(context), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppShellPageLayout(
      title: title,
      subtitle: subtitle,
      children: [
        if (_stage == ScanFlowStage.prep) ...[
          const PreScanSafetyNoticeCard(),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Step ${_prepStepIndex + 1} of 4',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showPrepStepGuide,
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('Guide'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_prepStepIndex + 1) / 4,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: AppPalette.line,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppPalette.primary,
                  ),
                ),
                const SizedBox(height: 14),
                if (_prepStepIndex == 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step 1: Patient details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _patientNames.contains(_selectedPatientName)
                        ? _selectedPatientName
                        : _patientNames.first,
                    items: _patientNames
                        .map(
                          (patientName) => DropdownMenuItem<String>(
                            value: patientName,
                            child: Text(patientName),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Patient name',
                      prefixIcon: Icon(Icons.person_search_rounded),
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _applyPatientSelection(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ScanInputField(
                    controller: _patientNameController,
                    label: 'Full patient name',
                    hint: 'Enter the patient name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ScanInputField(
                          controller: _patientAgeController,
                          label: 'Age',
                          hint: 'Example: 42',
                          icon: Icons.cake_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ScanInputField(
                          controller: _patientContactController,
                          label: 'Contact',
                          hint: 'Phone or ID',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_prepStepIndex == 1) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step 2: Choose the lesion area',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBodyArea,
                    items: _bodyAreas
                        .map(
                          (bodyArea) => DropdownMenuItem<String>(
                            value: bodyArea,
                            child: Text(bodyArea),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Body area',
                      prefixIcon: Icon(Icons.accessibility_new_rounded),
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _setSelectedBodyArea(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(
                        () => _showVisualBodyAreaPicker =
                            !_showVisualBodyAreaPicker,
                      );
                    },
                    icon: const Icon(Icons.accessibility_new_rounded),
                    label: Text(
                      _showVisualBodyAreaPicker
                          ? 'Hide visual body map'
                          : 'Choose visually',
                    ),
                  ),
                  if (_showVisualBodyAreaPicker) ...[
                    const SizedBox(height: 12),
                    BodyMapView(
                      selectedBodyArea: _selectedBodyArea,
                      markers: _bodyAreas
                          .map((area) => BodyMapMarker(bodyArea: area))
                          .toList(growable: false),
                      showInactiveMarkers: true,
                      showSelectedMarkerLabel: false,
                      onAreaSelected: (bodyArea) {
                        _setSelectedBodyArea(bodyArea);
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Drag the body map to rotate, then tap the matching body area.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final lesionSpotOptions = _lesionSpotOptions;
                      final activeSpot =
                          lesionSpotOptions.contains(_selectedLesionSpot)
                          ? _selectedLesionSpot
                          : _newLesionSpotOption;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: activeSpot,
                            items: lesionSpotOptions
                                .map(
                                  (spot) => DropdownMenuItem<String>(
                                    value: spot,
                                    child: Text(spot),
                                  ),
                                )
                                .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Lesion spot',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              _applyLesionSpotSelection(value);
                            },
                          ),
                          if (activeSpot == _newLesionSpotOption) ...[
                            const SizedBox(height: 12),
                            ScanInputField(
                              controller: _locationController,
                              label: 'New spot label',
                              hint: 'Example: Mole near left wrist',
                              icon: Icons.add_location_alt_outlined,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ScanInputField(
                    controller: _noteController,
                    label: 'Optional note',
                    hint: 'Add anything you want to remember about this photo',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                ],
                if (_prepStepIndex == 2) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step 3: Quick screening questions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'These answers are compared with the saved patient baseline profile after the image review.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  QuestionnaireToggleTile(
                    title: 'Recent visible change',
                    description:
                        'Has this mole or spot changed in size, shape, color, or symptoms recently?',
                    value: _recentChangeObserved,
                    onChanged: (value) {
                      setState(() => _recentChangeObserved = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  QuestionnaireToggleTile(
                    title: 'New or growing spot',
                    description:
                        'Is this a new lesion, or has it become larger compared with earlier checks or photos?',
                    value: _newOrGrowingLesionObserved,
                    onChanged: (value) {
                      setState(() => _newOrGrowingLesionObserved = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  QuestionnaireToggleTile(
                    title: 'Border or color change',
                    description:
                        'Have the edges, shape, or colors become more uneven, patchy, or hard to define?',
                    value: _borderColorChangeObserved,
                    onChanged: (value) {
                      setState(() => _borderColorChangeObserved = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  QuestionnaireToggleTile(
                    title: 'Symptoms now',
                    description:
                        'Is there itching, pain, bleeding, crusting, tenderness, or a sore that does not heal?',
                    value: _lesionSymptomsObserved,
                    onChanged: (value) {
                      setState(() => _lesionSymptomsObserved = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  QuestionnaireToggleTile(
                    title: 'Family history',
                    description:
                        'Has a close family member had melanoma or another skin cancer diagnosis?',
                    value: _familyHistoryReported,
                    onChanged: (value) {
                      setState(() => _familyHistoryReported = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  QuestionnaireToggleTile(
                    title: 'Prior skin cancer concern',
                    description:
                        'Have you previously been treated, monitored, or warned about a skin cancer concern?',
                    value: _priorSkinCancerReported,
                    onChanged: (value) {
                      setState(() => _priorSkinCancerReported = value);
                    },
                  ),
                ],
                if (_prepStepIndex == 3) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step 4: Add a clear photo',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.primarySoftFor(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppPalette.lineFor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedImage == null)
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppPalette.surfaceFor(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppPalette.lineFor(context),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No photo selected yet',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppPalette.mutedFor(context),
                                    ),
                              ),
                            ),
                          )
                        else
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.memory(
                                  _selectedImage!.bytes,
                                  height: 178,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.46),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_selectedImage!.source.label} photo ready',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isPickingImage
                                  ? null
                                  : () => _pickImage(ScanImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(
                                _isPickingImage
                                    ? 'Opening camera...'
                                    : 'Take Photo',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isPickingImage
                                  ? null
                                  : () => _pickImage(ScanImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Choose from Photos'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Use a clear, close, well-lit image with the lesion centered.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_prepStepIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _goToPrepStep(_prepStepIndex - 1),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_prepStepIndex > 0) const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: _prepStepIndex == 3
                            ? 'Continue to Scan'
                            : 'Next Step',
                        isLoading: false,
                        onPressed: () {
                          if (!_validateCurrentPrepStep()) {
                            return;
                          }
                          if (_prepStepIndex == 3) {
                            _startScanProcessing();
                            return;
                          }
                          _goToPrepStep(_prepStepIndex + 1);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (_stage == ScanFlowStage.analyzing) ...[
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScanProcessingHero(
                  progress: (_analysisStepIndex + 1) / _analysisSteps.length,
                ),
                const SizedBox(height: 22),
                Text(
                  'Review in progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'The app is checking photo quality and preparing a patient-safe result.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (_analysisStepIndex + 1) / _analysisSteps.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: AppPalette.primarySoft,
                  color: AppPalette.primary,
                ),
                const SizedBox(height: 14),
                AnalysisStepTile(
                  label: _analysisSteps[_analysisStepIndex],
                  state: AnalysisStepState.active,
                ),
                const SizedBox(height: 12),
                Text(
                  'Keep this screen open. This review is guidance only and is not a medical diagnosis.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: _resetScan,
            child: const Text('Cancel Review'),
          ),
        ],
        if (_stage == ScanFlowStage.result) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: resultStatusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    prediction?.status ?? 'Analysis unavailable',
                    style: TextStyle(
                      color: resultStatusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  prediction == null
                      ? 'Scan analysis could not be completed.'
                      : prediction.predictedClass,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  _analysisErrorMessage ??
                      prediction?.summary ??
                      'No model response is available for this scan yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                if (_shouldShowResultVisual(prediction)) ...[
                  Text(
                    prediction?.hasIllustration == true
                        ? 'Lesion shape view'
                        : 'Selected photo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      prediction?.illustrationBytes ?? _selectedImage!.bytes,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.primarySoftFor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.lineFor(context)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tileWidth = constraints.maxWidth < 340
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 10) / 2;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppPalette.primaryFor(context),
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: tileWidth,
                                child: resultFactTile(
                                  label: 'Patient',
                                  value:
                                      _patientNameController.text.trim().isEmpty
                                      ? 'Not provided'
                                      : _patientNameController.text.trim(),
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
                                child: resultFactTile(
                                  label: 'Body area',
                                  value: _selectedBodyArea,
                                  icon: Icons.accessibility_new_rounded,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
                                child: resultFactTile(
                                  label: 'Spot',
                                  value: _locationController.text.trim().isEmpty
                                      ? 'Not provided'
                                      : _locationController.text.trim(),
                                  icon: Icons.place_outlined,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
                                child: resultFactTile(
                                  label: 'Model score',
                                  value: prediction == null
                                      ? 'Unavailable'
                                      : '${prediction.melanomaProbabilityPercent.toStringAsFixed(1)}%',
                                  icon: Icons.insights_rounded,
                                ),
                              ),
                            ],
                          ),
                          if (prediction != null &&
                              prediction.imageQualityStatus.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Photo quality: ${prediction.imageQualityScore.round()}/100 - ${prediction.imageQualityStatus}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'This is AI-supported guidance only. Use the recommended next step below before making health decisions.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (prediction != null) ...[
            ResultActionGuidanceCard(prediction: prediction),
            const SizedBox(height: 18),
          ],
          if (prediction != null &&
              _canScheduleFollowUpReminder(prediction)) ...[
            FollowUpReminderSettingCard(
              enabled: _followUpReminderEnabled,
              days: _followUpReminderDays,
              nextReviewDate: _selectedFollowUpReminderDate,
              locked: _hasSavedCurrentResult,
              onEnabledChanged: (value) {
                setState(() => _followUpReminderEnabled = value);
              },
              onDaysChanged: (value) {
                setState(() => _followUpReminderDays = value);
              },
            ),
            const SizedBox(height: 18),
          ],
          if (prediction != null) ...[
            PatientRiskContextCard(
              baselineSummary: _baselineRiskSummary,
              scanQuestionnaireSummary: _scanQuestionnaireRiskSummary,
              combinedSummary: _combinedRiskContextSummary,
              flagCount: _riskContextFlagCount,
            ),
            const SizedBox(height: 18),
          ],
          if (prediction == null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to retry safely',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const StatusLine(
                    icon: Icons.image_search_rounded,
                    title: 'Use a clearer image',
                    value:
                        'Retake the photo in steady lighting and keep the lesion centered in the frame.',
                    tint: AppPalette.primary,
                  ),
                  const SizedBox(height: 12),
                  const StatusLine(
                    icon: Icons.memory_rounded,
                    title: 'On-device AI model',
                    value:
                        'The scan runs inside the app with the bundled TensorFlow Lite model.',
                    tint: AppPalette.aqua,
                  ),
                  const SizedBox(height: 12),
                  const StatusLine(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Private image handling',
                    value:
                        'Photos stay on this device, while Firestore stores only the scan metadata needed for history.',
                    tint: AppPalette.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Retry Analysis',
              isLoading: false,
              onPressed: _retryAnalysis,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _returnToPrep,
              child: const Text('Back to Scan Details'),
            ),
          ] else ...[
            PrimaryButton(
              label: _hasSavedCurrentResult
                  ? 'Saved to History'
                  : 'Save to History',
              isLoading: _isSavingResult,
              onPressed: _saveResultToHistory,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _hasSavedCurrentResult ? widget.onOpenHistory : null,
              child: const Text('Open History'),
            ),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Run Another Scan',
            isLoading: false,
            onPressed: _resetScan,
          ),
        ],
      ],
    );
  }
}

enum HistoryDisplayMode { normal, visual }

enum BodyMapSide { front, back }

class BodyMapMarker {
  final String bodyArea;
  final int count;
  final Color? tint;

  const BodyMapMarker({required this.bodyArea, this.count = 0, this.tint});
}

class BodyMapView extends StatelessWidget {
  final List<BodyMapMarker> markers;
  final String? selectedBodyArea;
  final ValueChanged<String>? onAreaSelected;
  final bool showLabels;
  final bool showCounts;
  final bool showInactiveMarkers;
  final bool showSelectedMarkerLabel;
  final double height;

  const BodyMapView({
    super.key,
    required this.markers,
    this.selectedBodyArea,
    this.onAreaSelected,
    this.showLabels = false,
    this.showCounts = false,
    this.showInactiveMarkers = true,
    this.showSelectedMarkerLabel = true,
    this.height = 430,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final mapHeight = math.max(height, showLabels ? 560.0 : 520.0);

    return Container(
      height: mapHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF223842) : const Color(0xFFE7F0F2),
            isDark ? const Color(0xFF10242C) : const Color(0xFFC8D5D8),
          ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFB5CACE),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: _BodyMapModelViewer(
                markers: markers,
                selectedBodyArea: selectedBodyArea,
                onAreaSelected: onAreaSelected,
                showLabels: showLabels,
                showCounts: showCounts,
                showInactiveMarkers: showInactiveMarkers,
                showSelectedMarkerLabel: showSelectedMarkerLabel,
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Row(
                children: [
                  Expanded(
                    child: _BodyMapLegendBadge(
                      label: selectedBodyArea == null
                          ? '3D body map'
                          : 'Selected: $selectedBodyArea',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _BodyMapRotationHint(),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceFor(
                      context,
                    ).withValues(alpha: isDark ? 0.64 : 0.78),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppPalette.lineFor(
                        context,
                      ).withValues(alpha: isDark ? 0.36 : 0.70),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      'Drag the 3D body to rotate. Tap a body marker to select the scan area.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.mutedFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyMapModelViewer extends StatelessWidget {
  final List<BodyMapMarker> markers;
  final String? selectedBodyArea;
  final ValueChanged<String>? onAreaSelected;
  final bool showLabels;
  final bool showCounts;
  final bool showInactiveMarkers;
  final bool showSelectedMarkerLabel;

  const _BodyMapModelViewer({
    required this.markers,
    required this.selectedBodyArea,
    required this.onAreaSelected,
    required this.showLabels,
    required this.showCounts,
    required this.showInactiveMarkers,
    required this.showSelectedMarkerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);
    final modelBackground = isDark
        ? const Color(0xFF10272F)
        : const Color(0xFFEAF6F7);

    return ModelViewer(
      key: ValueKey('body-map-${selectedBodyArea ?? 'none'}-${markers.length}'),
      src: 'assets/models/medical_mannequin.glb',
      alt: 'Interactive 3D medical body map',
      backgroundColor: modelBackground,
      loading: Loading.eager,
      reveal: Reveal.auto,
      cameraControls: true,
      disablePan: true,
      disableTap: true,
      disableZoom: false,
      touchAction: TouchAction.panY,
      interactionPrompt: InteractionPrompt.auto,
      interactionPromptStyle: InteractionPromptStyle.basic,
      interactionPromptThreshold: 1200,
      autoRotate: false,
      autoRotateDelay: 3200,
      rotationPerSecond: '16deg',
      cameraOrbit: _bodyMapCameraOrbitFor(selectedBodyArea),
      cameraTarget: '0m 0.94m 0m',
      minCameraOrbit: 'auto 58deg 2.45m',
      maxCameraOrbit: 'auto 88deg 4.20m',
      fieldOfView: '24deg',
      exposure: isDark ? 1.02 : 1.22,
      minHotspotOpacity: 0.18,
      maxHotspotOpacity: 1,
      innerModelViewerHtml: _buildBodyMapHotspots(
        markers: markers,
        selectedBodyArea: selectedBodyArea,
        showLabels: showLabels,
        showCounts: showCounts,
        showInactiveMarkers: showInactiveMarkers,
        showSelectedMarkerLabel: showSelectedMarkerLabel,
      ),
      relatedCss: _bodyMapModelCss(
        primary: AppPalette.primaryFor(context),
        surface: AppPalette.surfaceFor(context),
        ink: AppPalette.inkFor(context),
        muted: AppPalette.mutedFor(context),
        isDark: isDark,
      ),
      javascriptChannels: {
        JavascriptChannel(
          'SkinSafeBodyMap',
          onMessageReceived: (message) {
            final bodyArea = message.message.trim();
            if (bodyArea.isNotEmpty) {
              onAreaSelected?.call(bodyArea);
            }
          },
        ),
      },
      debugLogging: false,
    );
  }
}

class _BodyMapRotationHint extends StatelessWidget {
  const _BodyMapRotationHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surfaceFor(context).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.lineFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.threed_rotation_rounded,
            size: 16,
            color: AppPalette.primaryFor(context),
          ),
          const SizedBox(width: 6),
          Text(
            '3D rotate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.primaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyMapHotspotAnchor {
  final String position;
  final String normal;

  const _BodyMapHotspotAnchor({required this.position, required this.normal});
}

String _buildBodyMapHotspots({
  required List<BodyMapMarker> markers,
  required String? selectedBodyArea,
  required bool showLabels,
  required bool showCounts,
  required bool showInactiveMarkers,
  required bool showSelectedMarkerLabel,
}) {
  final selected = selectedBodyArea?.trim();
  final availableMarkers = <String, BodyMapMarker>{};

  for (final marker in markers) {
    final bodyArea = marker.bodyArea.trim();
    if (bodyArea.isEmpty) {
      continue;
    }
    final isSelected = bodyArea == selected;
    if (showInactiveMarkers || isSelected) {
      availableMarkers[bodyArea] = marker;
    }
  }

  if (selected != null &&
      selected.isNotEmpty &&
      !availableMarkers.containsKey(selected)) {
    availableMarkers[selected] = BodyMapMarker(bodyArea: selected);
  }

  return availableMarkers.values
      .map((marker) {
        final bodyArea = marker.bodyArea.trim();
        final isSelected = bodyArea == selected;
        final shouldShowLabel =
            showLabels || (showSelectedMarkerLabel && isSelected);
        final anchor = _bodyMapHotspotAnchorFor(bodyArea);
        final displayLabel = htmlEscape.convert(
          showCounts && marker.count > 0
              ? '$bodyArea (${marker.count > 9 ? '9+' : marker.count})'
              : bodyArea,
        );
        final areaForJs = htmlEscape.convert(jsonEncode(bodyArea));
        final slot = htmlEscape.convert(_bodyMapHotspotSlotFor(bodyArea));
        final classes = [
          'body-hotspot',
          if (isSelected) 'selected',
          if (shouldShowLabel) 'labeled',
        ].join(' ');

        return '''
<button
  slot="$slot"
  class="$classes"
  data-position="${anchor.position}"
  data-normal="${anchor.normal}"
  type="button"
  aria-label="$displayLabel"
  onclick="SkinSafeBodyMap.postMessage($areaForJs)">
  <span class="hotspot-dot"></span>
  <span class="hotspot-label">$displayLabel</span>
</button>''';
      })
      .join('\n');
}

String _bodyMapModelCss({
  required Color primary,
  required Color surface,
  required Color ink,
  required Color muted,
  required bool isDark,
}) {
  final primaryRgb = _cssRgb(primary);
  final surfaceRgb = _cssRgb(surface);
  final inkRgb = _cssRgb(ink);
  final mutedRgb = _cssRgb(muted);
  final ringAlpha = isDark ? 0.36 : 0.24;

  return '''
model-viewer {
  width: 100%;
  height: 100%;
  --poster-color: transparent;
  --progress-bar-color: rgb($primaryRgb);
  --progress-bar-height: 3px;
}

.body-hotspot {
  align-items: center;
  background: rgba($surfaceRgb, ${isDark ? 0.78 : 0.88});
  border: 1px solid rgba($primaryRgb, 0.48);
  border-radius: 999px;
  box-shadow:
    0 10px 24px rgba(0, 0, 0, ${isDark ? 0.30 : 0.15}),
    0 0 0 8px rgba($primaryRgb, $ringAlpha);
  color: rgb($inkRgb);
  cursor: pointer;
  display: inline-flex;
  font: 800 12px system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
  gap: 7px;
  min-height: 28px;
  min-width: 28px;
  padding: 5px;
  transform: translate(-50%, -50%);
  transition: transform 180ms ease, opacity 180ms ease, box-shadow 180ms ease;
  white-space: nowrap;
}

.body-hotspot:hover,
.body-hotspot.selected {
  box-shadow:
    0 14px 30px rgba(0, 0, 0, ${isDark ? 0.36 : 0.18}),
    0 0 0 10px rgba($primaryRgb, ${isDark ? 0.42 : 0.30});
  transform: translate(-50%, -50%) scale(1.08);
}

.hotspot-dot {
  background: rgb($primaryRgb);
  border: 2px solid rgba(255, 255, 255, 0.94);
  border-radius: 999px;
  display: block;
  height: 14px;
  min-width: 14px;
  width: 14px;
}

.hotspot-label {
  color: rgb($mutedRgb);
  display: none;
  line-height: 1;
  max-width: 128px;
  overflow: hidden;
  padding-right: 4px;
  text-overflow: ellipsis;
}

.body-hotspot.labeled .hotspot-label,
.body-hotspot.selected .hotspot-label {
  display: inline-block;
}
''';
}

String _cssRgb(Color color) {
  return '${(color.r * 255).round().clamp(0, 255)}, '
      '${(color.g * 255).round().clamp(0, 255)}, '
      '${(color.b * 255).round().clamp(0, 255)}';
}

String _bodyMapHotspotSlotFor(String bodyArea) {
  final normalized = bodyArea.trim().toLowerCase();
  final safe = normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'hotspot-${safe.isEmpty ? 'body-area' : safe}';
}

String _bodyMapCameraOrbitFor(String? bodyArea) {
  final normalized = bodyArea?.trim().toLowerCase() ?? '';
  if (normalized.contains('back')) {
    return '180deg 74deg 3.45m';
  }
  if (normalized.contains('left')) {
    return '-22deg 74deg 3.45m';
  }
  if (normalized.contains('right')) {
    return '22deg 74deg 3.45m';
  }
  return '0deg 74deg 3.45m';
}

_BodyMapHotspotAnchor _bodyMapHotspotAnchorFor(String bodyArea) {
  final normalized = bodyArea.trim().toLowerCase();

  if (normalized.contains('scalp')) {
    return const _BodyMapHotspotAnchor(
      position: '0m 2.02m 0.04m',
      normal: '0m 1m 0.2m',
    );
  }
  if (normalized.contains('face')) {
    return const _BodyMapHotspotAnchor(
      position: '0m 1.86m 0.16m',
      normal: '0m 0m 1m',
    );
  }
  if (normalized.contains('neck')) {
    return const _BodyMapHotspotAnchor(
      position: '0m 1.65m 0.12m',
      normal: '0m 0.15m 1m',
    );
  }
  if (normalized.contains('back')) {
    return const _BodyMapHotspotAnchor(
      position: '0m 1.36m -0.20m',
      normal: '0m 0m -1m',
    );
  }
  if (normalized.contains('chest')) {
    return const _BodyMapHotspotAnchor(
      position: '0m 1.43m 0.20m',
      normal: '0m 0m 1m',
    );
  }
  if (normalized.contains('abdomen') || normalized.contains('stomach')) {
    return const _BodyMapHotspotAnchor(
      position: '0m 1.18m 0.19m',
      normal: '0m 0m 1m',
    );
  }
  if (normalized.contains('left') && normalized.contains('hand')) {
    return const _BodyMapHotspotAnchor(
      position: '-0.52m 0.72m 0.08m',
      normal: '-0.75m -0.08m 0.45m',
    );
  }
  if (normalized.contains('right') && normalized.contains('hand')) {
    return const _BodyMapHotspotAnchor(
      position: '0.52m 0.72m 0.08m',
      normal: '0.75m -0.08m 0.45m',
    );
  }
  if (normalized.contains('left') && normalized.contains('arm')) {
    return const _BodyMapHotspotAnchor(
      position: '-0.43m 1.18m 0.10m',
      normal: '-0.85m 0.05m 0.36m',
    );
  }
  if (normalized.contains('right') && normalized.contains('arm')) {
    return const _BodyMapHotspotAnchor(
      position: '0.43m 1.18m 0.10m',
      normal: '0.85m 0.05m 0.36m',
    );
  }
  if (normalized.contains('left') && normalized.contains('foot')) {
    return const _BodyMapHotspotAnchor(
      position: '-0.17m 0.03m 0.19m',
      normal: '-0.28m -0.25m 0.90m',
    );
  }
  if (normalized.contains('right') && normalized.contains('foot')) {
    return const _BodyMapHotspotAnchor(
      position: '0.17m 0.03m 0.19m',
      normal: '0.28m -0.25m 0.90m',
    );
  }
  if (normalized.contains('left') && normalized.contains('leg')) {
    return const _BodyMapHotspotAnchor(
      position: '-0.15m 0.50m 0.10m',
      normal: '-0.25m 0m 0.92m',
    );
  }
  if (normalized.contains('right') && normalized.contains('leg')) {
    return const _BodyMapHotspotAnchor(
      position: '0.15m 0.50m 0.10m',
      normal: '0.25m 0m 0.92m',
    );
  }
  if (normalized.contains('hand')) {
    return const _BodyMapHotspotAnchor(
      position: '0.52m 0.72m 0.08m',
      normal: '0.75m -0.08m 0.45m',
    );
  }
  if (normalized.contains('arm')) {
    return const _BodyMapHotspotAnchor(
      position: '0.43m 1.18m 0.10m',
      normal: '0.85m 0.05m 0.36m',
    );
  }
  if (normalized.contains('leg')) {
    return const _BodyMapHotspotAnchor(
      position: '0.15m 0.50m 0.10m',
      normal: '0.25m 0m 0.92m',
    );
  }
  if (normalized.contains('foot')) {
    return const _BodyMapHotspotAnchor(
      position: '0.17m 0.03m 0.19m',
      normal: '0.28m -0.25m 0.90m',
    );
  }

  return const _BodyMapHotspotAnchor(
    position: '0m 1.08m 0.20m',
    normal: '0m 0m 1m',
  );
}

class BodyMapHumanPainter extends CustomPainter {
  final bool isDark;
  final BodyMapSide side;
  final double rotationTurns;

  const BodyMapHumanPainter({
    required this.isDark,
    required this.side,
    required this.rotationTurns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final normalizedRotation = _normalizeBodyMapRotation(rotationTurns);
    final sideAmount = _bodyMapSideAmountForRotation(rotationTurns);
    final isSideProfile = sideAmount > 0.70;
    final facingRight =
        math.sin(normalizedRotation * math.pi * 2) >= 0 ||
        normalizedRotation == 0;
    final skinBase = isDark ? const Color(0xFFACB8B8) : const Color(0xFFD7D4CE);
    final skinHighlight = isDark
        ? const Color(0xFFE5ECE8)
        : const Color(0xFFFAF8F1);
    final skinShade = isDark
        ? const Color(0xFF667577)
        : const Color(0xFF9C9D99);
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.38)
          : const Color(0xFF596164).withValues(alpha: 0.55);
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.09)
          : const Color(0xFF0B6971).withValues(alpha: 0.055);
    final labelPaint = TextPainter(
      text: TextSpan(
        text: _bodyMapViewLabelFor(rotationTurns),
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.58)
              : const Color(0xFF31565C).withValues(alpha: 0.62),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _drawStudioBackdrop(canvas, size, sideAmount);
    _drawBodyMapGrid(canvas, size, guidePaint);
    _drawGroundShadow(canvas, size, sideAmount);
    _drawRotateAffordance(canvas, size, sideAmount);

    if (isSideProfile) {
      _drawSideSilhouette(
        canvas: canvas,
        size: size,
        centerX: size.width * 0.50,
        topY: size.height * 0.13,
        height: size.height * 0.79,
        outlinePaint: outlinePaint,
        skinBase: skinBase,
        skinHighlight: skinHighlight,
        skinShade: skinShade,
        facingRight: facingRight,
      );
    } else {
      _drawForwardSilhouette(
        canvas: canvas,
        size: size,
        centerX: size.width * 0.50,
        topY: size.height * 0.13,
        height: size.height * 0.79,
        outlinePaint: outlinePaint,
        skinBase: skinBase,
        skinHighlight: skinHighlight,
        skinShade: skinShade,
        isBack: side == BodyMapSide.back,
      );
    }

    _drawRotationIndicator(canvas, size, normalizedRotation, sideAmount);
    labelPaint.paint(
      canvas,
      Offset(size.width * 0.50 - labelPaint.width / 2, size.height * 0.945),
    );
  }

  @override
  bool shouldRepaint(covariant BodyMapHumanPainter oldDelegate) {
    return isDark != oldDelegate.isDark ||
        side != oldDelegate.side ||
        rotationTurns != oldDelegate.rotationTurns;
  }

  void _drawBodyMapGrid(Canvas canvas, Size size, Paint guidePaint) {
    for (var x = size.width * 0.16; x < size.width; x += size.width * 0.18) {
      canvas.drawLine(
        Offset(x, size.height * 0.22),
        Offset(x, size.height * 0.91),
        guidePaint,
      );
    }
    for (var y = size.height * 0.32; y < size.height * 0.84; y += 72) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * 0.50, y),
          width: size.width * 0.38,
          height: 16,
        ),
        0,
        math.pi * 2,
        false,
        guidePaint..color = guidePaint.color.withValues(alpha: 0.055),
      );
    }
  }

  void _drawStudioBackdrop(Canvas canvas, Size size, double sideAmount) {
    final centerGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.44, size.height * 0.36),
        size.width * 0.52,
        [
          Colors.white.withValues(alpha: isDark ? 0.09 : 0.42),
          Colors.white.withValues(alpha: 0),
        ],
      );
    final rimGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * (0.64 + sideAmount * 0.04), size.height * 0.32),
        size.width * 0.40,
        [
          const Color(0xFF5FCAC7).withValues(alpha: isDark ? 0.11 : 0.18),
          const Color(0xFF5FCAC7).withValues(alpha: 0),
        ],
      );
    final bodyDepth = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.57, size.height * 0.48),
        size.width * (0.24 + sideAmount * 0.08),
        [
          Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
          Colors.black.withValues(alpha: 0),
        ],
      );

    canvas.drawRect(Offset.zero & size, centerGlow);
    canvas.drawRect(Offset.zero & size, rimGlow);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.57, size.height * 0.51),
        width: size.width * (0.32 + sideAmount * 0.08),
        height: size.height * 0.62,
      ),
      bodyDepth,
    );
  }

  void _drawGroundShadow(Canvas canvas, Size size, double sideAmount) {
    final shadowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.50, size.height * 0.905),
        size.width * (0.18 + sideAmount * 0.08),
        [
          Colors.black.withValues(alpha: isDark ? 0.30 : 0.12),
          Colors.black.withValues(alpha: 0),
        ],
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.905),
        width: size.width * (0.36 + sideAmount * 0.14),
        height: size.height * 0.045,
      ),
      shadowPaint,
    );
  }

  void _drawForwardSilhouette({
    required Canvas canvas,
    required Size size,
    required double centerX,
    required double topY,
    required double height,
    required Paint outlinePaint,
    required Color skinBase,
    required Color skinHighlight,
    required Color skinShade,
    required bool isBack,
  }) {
    final unit = height / 100;
    final widthScale = _bodyMapWidthScaleForRotation(rotationTurns);
    final turnShift = math.sin(rotationTurns * math.pi * 2) * unit * 2.1;
    final detailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = outlinePaint.color.withValues(alpha: 0.34);
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX - unit * 27, topY + unit * 18),
        Offset(centerX + unit * 30, topY + unit * 92),
        [
          skinHighlight.withValues(alpha: 0.94),
          skinBase.withValues(alpha: 0.96),
          skinShade.withValues(alpha: 0.88),
        ],
        const [0.02, 0.48, 1],
      );
    final sideShadePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? Colors.black : const Color(0xFF9C6F56)).withValues(
        alpha: isDark ? 0.12 : 0.10,
      );
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: isDark ? 0.16 : 0.34);

    void drawPath(Path path) {
      canvas.drawPath(path, bodyPaint);
      canvas.drawPath(path, outlinePaint);
    }

    void drawOval(Rect rect) {
      canvas.drawOval(rect, bodyPaint);
      canvas.drawOval(rect, outlinePaint);
    }

    void drawRRect(RRect rect) {
      canvas.drawRRect(rect, bodyPaint);
      canvas.drawRRect(rect, outlinePaint);
    }

    canvas.save();
    canvas.translate(centerX + turnShift, 0);
    canvas.scale(widthScale, 1);
    canvas.translate(-centerX, 0);

    final neck = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, topY + unit * 18.7),
        width: unit * 7.4,
        height: unit * 9.1,
      ),
      Radius.circular(unit * 3),
    );
    final torso = Path()
      ..moveTo(centerX - unit * 4.5, topY + unit * 21)
      ..cubicTo(
        centerX - unit * 10.2,
        topY + unit * 21.3,
        centerX - unit * 20.2,
        topY + unit * 23.8,
        centerX - unit * 25.2,
        topY + unit * 30.2,
      )
      ..cubicTo(
        centerX - unit * 22.4,
        topY + unit * 41,
        centerX - unit * 19.4,
        topY + unit * 53,
        centerX - unit * 15.5,
        topY + unit * 63,
      )
      ..cubicTo(
        centerX - unit * 11.2,
        topY + unit * 68,
        centerX - unit * 4.8,
        topY + unit * 69.2,
        centerX,
        topY + unit * 69.2,
      )
      ..cubicTo(
        centerX + unit * 4.8,
        topY + unit * 69.2,
        centerX + unit * 11.2,
        topY + unit * 68,
        centerX + unit * 15.5,
        topY + unit * 63,
      )
      ..cubicTo(
        centerX + unit * 19.4,
        topY + unit * 53,
        centerX + unit * 22.4,
        topY + unit * 41,
        centerX + unit * 25.2,
        topY + unit * 30.2,
      )
      ..cubicTo(
        centerX + unit * 20.2,
        topY + unit * 23.8,
        centerX + unit * 10.2,
        topY + unit * 21.3,
        centerX + unit * 4.5,
        topY + unit * 21,
      )
      ..close();

    final leftArm = Path()
      ..moveTo(centerX - unit * 24.2, topY + unit * 29.5)
      ..cubicTo(
        centerX - unit * 29,
        topY + unit * 36,
        centerX - unit * 30,
        topY + unit * 50,
        centerX - unit * 28.6,
        topY + unit * 64,
      )
      ..cubicTo(
        centerX - unit * 28.2,
        topY + unit * 70.2,
        centerX - unit * 25.8,
        topY + unit * 75.2,
        centerX - unit * 22.2,
        topY + unit * 75.4,
      )
      ..cubicTo(
        centerX - unit * 19.7,
        topY + unit * 75.4,
        centerX - unit * 18.7,
        topY + unit * 70.5,
        centerX - unit * 19.3,
        topY + unit * 64,
      )
      ..cubicTo(
        centerX - unit * 20.6,
        topY + unit * 51,
        centerX - unit * 19.5,
        topY + unit * 39.5,
        centerX - unit * 17.4,
        topY + unit * 32.5,
      )
      ..close();
    final rightArm = Path()
      ..moveTo(centerX + unit * 24.2, topY + unit * 29.5)
      ..cubicTo(
        centerX + unit * 29,
        topY + unit * 36,
        centerX + unit * 30,
        topY + unit * 50,
        centerX + unit * 28.6,
        topY + unit * 64,
      )
      ..cubicTo(
        centerX + unit * 28.2,
        topY + unit * 70.2,
        centerX + unit * 25.8,
        topY + unit * 75.2,
        centerX + unit * 22.2,
        topY + unit * 75.4,
      )
      ..cubicTo(
        centerX + unit * 19.7,
        topY + unit * 75.4,
        centerX + unit * 18.7,
        topY + unit * 70.5,
        centerX + unit * 19.3,
        topY + unit * 64,
      )
      ..cubicTo(
        centerX + unit * 20.6,
        topY + unit * 51,
        centerX + unit * 19.5,
        topY + unit * 39.5,
        centerX + unit * 17.4,
        topY + unit * 32.5,
      )
      ..close();

    final leftLeg = Path()
      ..moveTo(centerX - unit * 12.8, topY + unit * 66)
      ..cubicTo(
        centerX - unit * 15.6,
        topY + unit * 78,
        centerX - unit * 15.2,
        topY + unit * 90,
        centerX - unit * 13.4,
        topY + unit * 96,
      )
      ..cubicTo(
        centerX - unit * 12,
        topY + unit * 100.4,
        centerX - unit * 6.8,
        topY + unit * 100.3,
        centerX - unit * 6.2,
        topY + unit * 96,
      )
      ..cubicTo(
        centerX - unit * 5.4,
        topY + unit * 84,
        centerX - unit * 5.1,
        topY + unit * 75,
        centerX - unit * 4.2,
        topY + unit * 67,
      )
      ..close();
    final rightLeg = Path()
      ..moveTo(centerX + unit * 12.8, topY + unit * 66)
      ..cubicTo(
        centerX + unit * 15.6,
        topY + unit * 78,
        centerX + unit * 15.2,
        topY + unit * 90,
        centerX + unit * 13.4,
        topY + unit * 96,
      )
      ..cubicTo(
        centerX + unit * 12,
        topY + unit * 100.4,
        centerX + unit * 6.8,
        topY + unit * 100.3,
        centerX + unit * 6.2,
        topY + unit * 96,
      )
      ..cubicTo(
        centerX + unit * 5.4,
        topY + unit * 84,
        centerX + unit * 5.1,
        topY + unit * 75,
        centerX + unit * 4.2,
        topY + unit * 67,
      )
      ..close();
    final leftFoot = Path()
      ..moveTo(centerX - unit * 12.1, topY + unit * 95.5)
      ..cubicTo(
        centerX - unit * 15.6,
        topY + unit * 97.5,
        centerX - unit * 15.2,
        topY + unit * 100.6,
        centerX - unit * 10.8,
        topY + unit * 100.8,
      )
      ..lineTo(centerX - unit * 6.5, topY + unit * 100.4)
      ..cubicTo(
        centerX - unit * 5.8,
        topY + unit * 98.6,
        centerX - unit * 6.2,
        topY + unit * 97,
        centerX - unit * 7.1,
        topY + unit * 95.8,
      )
      ..close();
    final rightFoot = Path()
      ..moveTo(centerX + unit * 12.1, topY + unit * 95.5)
      ..cubicTo(
        centerX + unit * 15.6,
        topY + unit * 97.5,
        centerX + unit * 15.2,
        topY + unit * 100.6,
        centerX + unit * 10.8,
        topY + unit * 100.8,
      )
      ..lineTo(centerX + unit * 6.5, topY + unit * 100.4)
      ..cubicTo(
        centerX + unit * 5.8,
        topY + unit * 98.6,
        centerX + unit * 6.2,
        topY + unit * 97,
        centerX + unit * 7.1,
        topY + unit * 95.8,
      )
      ..close();

    drawPath(leftLeg);
    drawPath(rightLeg);
    drawPath(leftFoot);
    drawPath(rightFoot);
    drawPath(leftArm);
    drawPath(rightArm);
    drawRRect(neck);
    drawPath(torso);
    drawOval(
      Rect.fromCenter(
        center: Offset(centerX - unit * 6.8, topY + unit * 9.4),
        width: unit * 2.1,
        height: unit * 4.0,
      ),
    );
    drawOval(
      Rect.fromCenter(
        center: Offset(centerX + unit * 6.8, topY + unit * 9.4),
        width: unit * 2.1,
        height: unit * 4.0,
      ),
    );
    drawOval(
      Rect.fromCenter(
        center: Offset(centerX, topY + unit * 8.8),
        width: unit * 12.6,
        height: unit * 15.8,
      ),
    );
    canvas.drawLine(
      Offset(centerX + unit * 15.8, topY + unit * 31),
      Offset(centerX + unit * 20.6, topY + unit * 69),
      sideShadePaint,
    );
    canvas.drawLine(
      Offset(centerX - unit * 13.5, topY + unit * 26),
      Offset(centerX - unit * 9.2, topY + unit * 60),
      highlightPaint,
    );

    if (isBack) {
      canvas.drawLine(
        Offset(centerX, topY + unit * 26),
        Offset(centerX, topY + unit * 61),
        detailPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX - unit * 6.5, topY + unit * 37),
          width: unit * 13,
          height: unit * 16,
        ),
        -math.pi * 0.10,
        -math.pi * 0.72,
        false,
        detailPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX + unit * 6.5, topY + unit * 37),
          width: unit * 13,
          height: unit * 16,
        ),
        math.pi * 0.10,
        math.pi * 0.72,
        false,
        detailPaint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX, topY + unit * 38),
          width: unit * 27,
          height: unit * 19,
        ),
        math.pi * 0.08,
        math.pi * 0.84,
        false,
        detailPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX, topY + unit * 49),
          width: unit * 18,
          height: unit * 12,
        ),
        math.pi * 0.10,
        math.pi * 0.80,
        false,
        detailPaint..color = detailPaint.color.withValues(alpha: 0.20),
      );
      canvas.drawCircle(
        Offset(centerX, topY + unit * 53.2),
        unit * 0.8,
        detailPaint,
      );
    }

    _drawForwardSurfaceDetails(
      canvas: canvas,
      centerX: centerX,
      topY: topY,
      unit: unit,
      detailPaint: detailPaint,
      highlightPaint: highlightPaint,
      shadePaint: sideShadePaint,
      isBack: isBack,
    );

    for (final xSign in const [-1, 1]) {
      final handX = centerX + unit * 20.8 * xSign;
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(handX + unit * 0.5 * xSign * i, topY + unit * 67),
          Offset(handX + unit * 1.0 * xSign * i, topY + unit * 70.2),
          detailPaint,
        );
      }
    }
    canvas.restore();
  }

  void _drawForwardSurfaceDetails({
    required Canvas canvas,
    required double centerX,
    required double topY,
    required double unit,
    required Paint detailPaint,
    required Paint highlightPaint,
    required Paint shadePaint,
    required bool isBack,
  }) {
    final softDetail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = detailPaint.color.withValues(alpha: 0.62);
    final softShade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..color = shadePaint.color.withValues(alpha: 0.72);

    canvas.drawLine(
      Offset(centerX - unit * 1.2, topY + unit * 7.3),
      Offset(centerX + unit * 1.0, topY + unit * 10.6),
      softDetail,
    );
    canvas.drawLine(
      Offset(centerX - unit * 2.2, topY + unit * 13.0),
      Offset(centerX + unit * 2.2, topY + unit * 12.8),
      softDetail..color = softDetail.color.withValues(alpha: 0.30),
    );

    if (isBack) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX - unit * 6.7, topY + unit * 47),
          width: unit * 11,
          height: unit * 25,
        ),
        -math.pi * 0.30,
        math.pi * 0.45,
        false,
        softDetail,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX + unit * 6.7, topY + unit * 47),
          width: unit * 11,
          height: unit * 25,
        ),
        math.pi * 0.85,
        math.pi * 0.45,
        false,
        softDetail,
      );
      canvas.drawLine(
        Offset(centerX - unit * 8.5, topY + unit * 67),
        Offset(centerX - unit * 8.7, topY + unit * 91),
        softShade,
      );
      canvas.drawLine(
        Offset(centerX + unit * 8.5, topY + unit * 67),
        Offset(centerX + unit * 8.7, topY + unit * 91),
        softShade,
      );
    } else {
      canvas.drawLine(
        Offset(centerX - unit * 11.2, topY + unit * 29),
        Offset(centerX - unit * 3.2, topY + unit * 33),
        softDetail,
      );
      canvas.drawLine(
        Offset(centerX + unit * 11.2, topY + unit * 29),
        Offset(centerX + unit * 3.2, topY + unit * 33),
        softDetail,
      );
      canvas.drawLine(
        Offset(centerX, topY + unit * 39.5),
        Offset(centerX, topY + unit * 57.8),
        softDetail..color = softDetail.color.withValues(alpha: 0.38),
      );
      for (final y in <double>[43, 49.5, 55.5]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(centerX - unit * 3.0, topY + unit * y),
            width: unit * 7.0,
            height: unit * 3.2,
          ),
          math.pi * 0.05,
          math.pi * 0.65,
          false,
          softDetail,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(centerX + unit * 3.0, topY + unit * y),
            width: unit * 7.0,
            height: unit * 3.2,
          ),
          math.pi * 0.30,
          math.pi * 0.65,
          false,
          softDetail,
        );
      }
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX - unit * 5.5, topY + unit * 64),
          width: unit * 9,
          height: unit * 7,
        ),
        math.pi * 0.08,
        math.pi * 0.48,
        false,
        softDetail,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX + unit * 5.5, topY + unit * 64),
          width: unit * 9,
          height: unit * 7,
        ),
        math.pi * 0.46,
        math.pi * 0.48,
        false,
        softDetail,
      );
    }

    for (final xSign in const [-1, 1]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX + unit * 21 * xSign, topY + unit * 47),
          width: unit * 5.8,
          height: unit * 30,
        ),
        xSign < 0 ? -math.pi * 0.16 : math.pi * 0.66,
        math.pi * 0.42,
        false,
        softShade,
      );
      canvas.drawLine(
        Offset(centerX + unit * 7.8 * xSign, topY + unit * 69),
        Offset(centerX + unit * 7.3 * xSign, topY + unit * 93),
        highlightPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX + unit * 9.7 * xSign, topY + unit * 81),
          width: unit * 6.2,
          height: unit * 5.4,
        ),
        math.pi * 0.12,
        math.pi * 0.72,
        false,
        softDetail,
      );
      canvas.drawLine(
        Offset(centerX + unit * 10.8 * xSign, topY + unit * 89),
        Offset(centerX + unit * 10.2 * xSign, topY + unit * 95),
        softDetail,
      );
    }
  }

  void _drawSideSilhouette({
    required Canvas canvas,
    required Size size,
    required double centerX,
    required double topY,
    required double height,
    required Paint outlinePaint,
    required Color skinBase,
    required Color skinHighlight,
    required Color skinShade,
    required bool facingRight,
  }) {
    final unit = height / 100;
    final sign = facingRight ? 1.0 : -1.0;
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX - unit * 12 * sign, topY + unit * 18),
        Offset(centerX + unit * 16 * sign, topY + unit * 91),
        [
          skinShade.withValues(alpha: 0.86),
          skinBase.withValues(alpha: 0.96),
          skinHighlight.withValues(alpha: 0.90),
        ],
        const [0, 0.52, 1],
      );
    final farLimbPaint = Paint()
      ..color = skinShade.withValues(alpha: isDark ? 0.42 : 0.34);
    final detailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = outlinePaint.color.withValues(alpha: 0.32);
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: isDark ? 0.14 : 0.28);

    void drawPath(Path path, {Paint? fillPaint}) {
      canvas.drawPath(path, fillPaint ?? bodyPaint);
      canvas.drawPath(path, outlinePaint);
    }

    void drawOval(Rect rect, {Paint? fillPaint}) {
      canvas.drawOval(rect, fillPaint ?? bodyPaint);
      canvas.drawOval(rect, outlinePaint);
    }

    final farArm = Path()
      ..moveTo(centerX - sign * unit * 4.5, topY + unit * 28)
      ..cubicTo(
        centerX - sign * unit * 8.8,
        topY + unit * 41,
        centerX - sign * unit * 8.6,
        topY + unit * 58,
        centerX - sign * unit * 5.4,
        topY + unit * 72,
      )
      ..cubicTo(
        centerX - sign * unit * 3.2,
        topY + unit * 74,
        centerX - sign * unit * 0.9,
        topY + unit * 72,
        centerX - sign * unit * 1.7,
        topY + unit * 68,
      )
      ..cubicTo(
        centerX - sign * unit * 3.8,
        topY + unit * 54,
        centerX - sign * unit * 3.2,
        topY + unit * 41,
        centerX - sign * unit * 0.8,
        topY + unit * 30,
      )
      ..close();
    final farLeg = Path()
      ..moveTo(centerX - sign * unit * 3.7, topY + unit * 64)
      ..cubicTo(
        centerX - sign * unit * 5.8,
        topY + unit * 77,
        centerX - sign * unit * 5.2,
        topY + unit * 91,
        centerX - sign * unit * 3.6,
        topY + unit * 97,
      )
      ..cubicTo(
        centerX - sign * unit * 0.6,
        topY + unit * 99.5,
        centerX + sign * unit * 2.6,
        topY + unit * 98.6,
        centerX + sign * unit * 1.8,
        topY + unit * 94,
      )
      ..cubicTo(
        centerX + sign * unit * 0.7,
        topY + unit * 82,
        centerX + sign * unit * 0.4,
        topY + unit * 72,
        centerX + sign * unit * 2.4,
        topY + unit * 64,
      )
      ..close();
    final torso = Path()
      ..moveTo(centerX - sign * unit * 5.4, topY + unit * 21)
      ..cubicTo(
        centerX + sign * unit * 3.7,
        topY + unit * 20.6,
        centerX + sign * unit * 12.4,
        topY + unit * 29,
        centerX + sign * unit * 12.1,
        topY + unit * 41,
      )
      ..cubicTo(
        centerX + sign * unit * 13.2,
        topY + unit * 51,
        centerX + sign * unit * 10.4,
        topY + unit * 61,
        centerX + sign * unit * 6.3,
        topY + unit * 66.2,
      )
      ..cubicTo(
        centerX + sign * unit * 1.6,
        topY + unit * 69.2,
        centerX - sign * unit * 6.7,
        topY + unit * 67.5,
        centerX - sign * unit * 8.8,
        topY + unit * 61.2,
      )
      ..cubicTo(
        centerX - sign * unit * 11.1,
        topY + unit * 48,
        centerX - sign * unit * 10.8,
        topY + unit * 32,
        centerX - sign * unit * 5.4,
        topY + unit * 21,
      )
      ..close();
    final nearArm = Path()
      ..moveTo(centerX + sign * unit * 2.9, topY + unit * 29.6)
      ..cubicTo(
        centerX + sign * unit * 7.2,
        topY + unit * 40,
        centerX + sign * unit * 7,
        topY + unit * 58,
        centerX + sign * unit * 4.9,
        topY + unit * 71,
      )
      ..cubicTo(
        centerX + sign * unit * 3.2,
        topY + unit * 75.4,
        centerX - sign * unit * 1.8,
        topY + unit * 75.2,
        centerX - sign * unit * 0.2,
        topY + unit * 69.5,
      )
      ..cubicTo(
        centerX + sign * unit * 2.5,
        topY + unit * 55,
        centerX + sign * unit * 1.6,
        topY + unit * 43,
        centerX - sign * unit * 0.6,
        topY + unit * 31,
      )
      ..close();
    final nearLeg = Path()
      ..moveTo(centerX + sign * unit * 4.6, topY + unit * 64)
      ..cubicTo(
        centerX + sign * unit * 8.2,
        topY + unit * 77,
        centerX + sign * unit * 7.8,
        topY + unit * 91,
        centerX + sign * unit * 6.6,
        topY + unit * 96.4,
      )
      ..cubicTo(
        centerX + sign * unit * 5.8,
        topY + unit * 100,
        centerX + sign * unit * 0.5,
        topY + unit * 100,
        centerX + sign * unit * 0.1,
        topY + unit * 95.2,
      )
      ..cubicTo(
        centerX - sign * unit * 0.6,
        topY + unit * 84,
        centerX - sign * unit * 0.8,
        topY + unit * 73,
        centerX + sign * unit * 1.9,
        topY + unit * 64,
      )
      ..close();
    final head = Path()
      ..moveTo(centerX - sign * unit * 4.4, topY + unit * 4.8)
      ..cubicTo(
        centerX - sign * unit * 1.6,
        topY + unit * 0.8,
        centerX + sign * unit * 5.6,
        topY + unit * 1.4,
        centerX + sign * unit * 7.5,
        topY + unit * 7.7,
      )
      ..cubicTo(
        centerX + sign * unit * 10.4,
        topY + unit * 8.6,
        centerX + sign * unit * 10.3,
        topY + unit * 11.2,
        centerX + sign * unit * 7.7,
        topY + unit * 12.3,
      )
      ..cubicTo(
        centerX + sign * unit * 6.1,
        topY + unit * 16.2,
        centerX + sign * unit * 1.4,
        topY + unit * 18.2,
        centerX - sign * unit * 2.9,
        topY + unit * 16.2,
      )
      ..cubicTo(
        centerX - sign * unit * 6.1,
        topY + unit * 13.5,
        centerX - sign * unit * 6.8,
        topY + unit * 8.2,
        centerX - sign * unit * 4.4,
        topY + unit * 4.8,
      )
      ..close();
    final neck = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX - sign * unit * 1.7, topY + unit * 19.1),
        width: unit * 6.5,
        height: unit * 8.8,
      ),
      Radius.circular(unit * 3),
    );

    canvas.drawPath(farArm, farLimbPaint);
    canvas.drawPath(farArm, outlinePaint);
    canvas.drawPath(farLeg, farLimbPaint);
    canvas.drawPath(farLeg, outlinePaint);
    drawPath(nearLeg);
    drawPath(torso);
    canvas.drawRRect(neck, bodyPaint);
    canvas.drawRRect(neck, outlinePaint);
    drawPath(nearArm);
    drawPath(head);
    drawOval(
      Rect.fromCenter(
        center: Offset(centerX - sign * unit * 4.4, topY + unit * 9.2),
        width: unit * 2.0,
        height: unit * 3.8,
      ),
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX + sign * unit * 5.5, topY + unit * 44),
        width: unit * 10,
        height: unit * 25,
      ),
      facingRight ? -math.pi * 0.50 : math.pi * 0.50,
      facingRight ? math.pi * 0.52 : -math.pi * 0.52,
      false,
      detailPaint,
    );
    canvas.drawLine(
      Offset(centerX - sign * unit * 6.7, topY + unit * 30),
      Offset(centerX - sign * unit * 8.7, topY + unit * 61),
      detailPaint,
    );
    canvas.drawLine(
      Offset(centerX + sign * unit * 6.4, topY + unit * 36),
      Offset(centerX + sign * unit * 6.0, topY + unit * 58),
      highlightPaint,
    );
    canvas.drawLine(
      Offset(centerX + sign * unit * 4.7, topY + unit * 77),
      Offset(centerX + sign * unit * 4.1, topY + unit * 91),
      detailPaint,
    );
    canvas.drawCircle(
      Offset(centerX + sign * unit * 6.1, topY + unit * 9.1),
      unit * 0.45,
      detailPaint,
    );
  }

  void _drawRotationIndicator(
    Canvas canvas,
    Size size,
    double normalizedRotation,
    double sideAmount,
  ) {
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? Colors.white : const Color(0xFF0B6971)).withValues(
        alpha: 0.14,
      );
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? const Color(0xFF8AE6D9) : const Color(0xFF078995))
          .withValues(alpha: 0.62 + sideAmount * 0.18);
    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.905),
      width: size.width * 0.30,
      height: size.height * 0.035,
    );
    canvas.drawArc(rect, math.pi * 0.08, math.pi * 0.84, false, trackPaint);
    canvas.drawArc(
      rect,
      math.pi * 0.08,
      math.pi * (0.14 + normalizedRotation * 0.70),
      false,
      activePaint,
    );
  }

  void _drawRotateAffordance(Canvas canvas, Size size, double sideAmount) {
    final center = Offset(size.width * 0.50, size.height * 0.515);
    final width = size.width * (0.50 - sideAmount * 0.10);
    final height = size.height * 0.50;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? Colors.white : const Color(0xFF0B6971)).withValues(
        alpha: 0.11,
      );
    final arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = (isDark ? const Color(0xFF8AE6D9) : const Color(0xFF078995))
          .withValues(alpha: 0.40);
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawArc(rect, -math.pi * 0.18, math.pi * 0.50, false, trackPaint);
    canvas.drawArc(rect, math.pi * 0.68, math.pi * 0.50, false, trackPaint);

    final rightTip = Offset(
      center.dx + width * 0.42,
      center.dy - height * 0.11,
    );
    final leftTip = Offset(center.dx - width * 0.42, center.dy + height * 0.11);
    canvas.drawLine(rightTip, rightTip + const Offset(-9, -5), arrowPaint);
    canvas.drawLine(rightTip, rightTip + const Offset(-3, 10), arrowPaint);
    canvas.drawLine(leftTip, leftTip + const Offset(9, 5), arrowPaint);
    canvas.drawLine(leftTip, leftTip + const Offset(3, -10), arrowPaint);
  }
}

class _BodyMapLegendBadge extends StatelessWidget {
  final String label;

  const _BodyMapLegendBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surfaceFor(context).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.lineFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.accessibility_new_rounded,
            size: 16,
            color: AppPalette.primaryFor(context),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.inkFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LegacyBodyMapPainter extends CustomPainter {
  final bool isDark;
  final BodyMapSide side;

  const LegacyBodyMapPainter({required this.isDark, required this.side});

  @override
  void paint(Canvas canvas, Size size) {
    final skinFill = isDark
        ? const Color(0xFF6C8F92).withValues(alpha: 0.68)
        : const Color(0xFFF6DDCB);
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.44)
          : const Color(0xFF465A5E).withValues(alpha: 0.62);
    final bodyPaint = Paint()..color = skinFill;
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.10)
          : const Color(0xFF0B6971).withValues(alpha: 0.09);
    final labelPaint = TextPainter(
      text: TextSpan(
        text: side == BodyMapSide.front ? 'Front view' : 'Back view',
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.58)
              : const Color(0xFF31565C).withValues(alpha: 0.62),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    for (var x = size.width * 0.16; x < size.width; x += size.width * 0.18) {
      canvas.drawLine(
        Offset(x, size.height * 0.20),
        Offset(x, size.height * 0.94),
        guidePaint,
      );
    }

    _drawMedicalSilhouette(
      canvas: canvas,
      size: size,
      centerX: size.width * 0.50,
      topY: size.height * 0.17,
      height: size.height * 0.74,
      paint: bodyPaint,
      outlinePaint: outlinePaint,
      isBack: side == BodyMapSide.back,
    );

    labelPaint.paint(
      canvas,
      Offset(size.width * 0.50 - labelPaint.width / 2, size.height * 0.935),
    );
  }

  @override
  bool shouldRepaint(covariant LegacyBodyMapPainter oldDelegate) {
    return isDark != oldDelegate.isDark || side != oldDelegate.side;
  }

  void _drawMedicalSilhouette({
    required Canvas canvas,
    required Size size,
    required double centerX,
    required double topY,
    required double height,
    required Paint paint,
    required Paint outlinePaint,
    required bool isBack,
  }) {
    final unit = height / 100;
    final headRadiusX = unit * 6.2;
    final headRadiusY = unit * 7.8;
    final path = Path();

    path.addOval(
      Rect.fromCenter(
        center: Offset(centerX, topY + unit * 9),
        width: headRadiusX * 2,
        height: headRadiusY * 2,
      ),
    );

    final body = Path()
      ..moveTo(centerX - unit * 3.6, topY + unit * 17)
      ..cubicTo(
        centerX - unit * 5.2,
        topY + unit * 19,
        centerX - unit * 8.5,
        topY + unit * 22,
        centerX - unit * 12.6,
        topY + unit * 23.2,
      )
      ..cubicTo(
        centerX - unit * 18.2,
        topY + unit * 25,
        centerX - unit * 20.5,
        topY + unit * 31,
        centerX - unit * 20.2,
        topY + unit * 38,
      )
      ..cubicTo(
        centerX - unit * 20.0,
        topY + unit * 48,
        centerX - unit * 19.4,
        topY + unit * 57,
        centerX - unit * 18.5,
        topY + unit * 66,
      )
      ..cubicTo(
        centerX - unit * 18.0,
        topY + unit * 70,
        centerX - unit * 15.6,
        topY + unit * 72,
        centerX - unit * 14.2,
        topY + unit * 68,
      )
      ..cubicTo(
        centerX - unit * 13.0,
        topY + unit * 55,
        centerX - unit * 13.4,
        topY + unit * 42,
        centerX - unit * 12.0,
        topY + unit * 33,
      )
      ..cubicTo(
        centerX - unit * 10.8,
        topY + unit * 42,
        centerX - unit * 9.8,
        topY + unit * 50,
        centerX - unit * 8.4,
        topY + unit * 57,
      )
      ..lineTo(centerX - unit * 4.7, topY + unit * 57.8)
      ..cubicTo(
        centerX - unit * 6.8,
        topY + unit * 69,
        centerX - unit * 7.2,
        topY + unit * 81,
        centerX - unit * 7.2,
        topY + unit * 94,
      )
      ..cubicTo(
        centerX - unit * 7.2,
        topY + unit * 98,
        centerX - unit * 12.0,
        topY + unit * 99,
        centerX - unit * 12.4,
        topY + unit * 95,
      )
      ..cubicTo(
        centerX - unit * 13.4,
        topY + unit * 82,
        centerX - unit * 14.2,
        topY + unit * 69,
        centerX - unit * 13.2,
        topY + unit * 58.2,
      )
      ..lineTo(centerX + unit * 13.2, topY + unit * 58.2)
      ..cubicTo(
        centerX + unit * 14.2,
        topY + unit * 69,
        centerX + unit * 13.4,
        topY + unit * 82,
        centerX + unit * 12.4,
        topY + unit * 95,
      )
      ..cubicTo(
        centerX + unit * 12.0,
        topY + unit * 99,
        centerX + unit * 7.2,
        topY + unit * 98,
        centerX + unit * 7.2,
        topY + unit * 94,
      )
      ..cubicTo(
        centerX + unit * 7.2,
        topY + unit * 81,
        centerX + unit * 6.8,
        topY + unit * 69,
        centerX + unit * 4.7,
        topY + unit * 57.8,
      )
      ..lineTo(centerX + unit * 8.4, topY + unit * 57)
      ..cubicTo(
        centerX + unit * 9.8,
        topY + unit * 50,
        centerX + unit * 10.8,
        topY + unit * 42,
        centerX + unit * 12.0,
        topY + unit * 33,
      )
      ..cubicTo(
        centerX + unit * 13.4,
        topY + unit * 42,
        centerX + unit * 13.0,
        topY + unit * 55,
        centerX + unit * 14.2,
        topY + unit * 68,
      )
      ..cubicTo(
        centerX + unit * 15.6,
        topY + unit * 72,
        centerX + unit * 18.0,
        topY + unit * 70,
        centerX + unit * 18.5,
        topY + unit * 66,
      )
      ..cubicTo(
        centerX + unit * 19.4,
        topY + unit * 57,
        centerX + unit * 20.0,
        topY + unit * 48,
        centerX + unit * 20.2,
        topY + unit * 38,
      )
      ..cubicTo(
        centerX + unit * 20.5,
        topY + unit * 31,
        centerX + unit * 18.2,
        topY + unit * 25,
        centerX + unit * 12.6,
        topY + unit * 23.2,
      )
      ..cubicTo(
        centerX + unit * 8.5,
        topY + unit * 22,
        centerX + unit * 5.2,
        topY + unit * 19,
        centerX + unit * 3.6,
        topY + unit * 17,
      )
      ..close();

    canvas.drawPath(body, paint);
    canvas.drawPath(body, outlinePaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);

    if (!isBack) {
      final chestPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outlinePaint.color.withValues(alpha: 0.34);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX, topY + unit * 38),
          width: unit * 19,
          height: unit * 16,
        ),
        math.pi * 0.12,
        math.pi * 0.76,
        false,
        chestPaint,
      );
    } else {
      final spinePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outlinePaint.color.withValues(alpha: 0.26);
      canvas.drawLine(
        Offset(centerX, topY + unit * 25),
        Offset(centerX, topY + unit * 56),
        spinePaint,
      );
    }
  }
}

double _normalizeBodyMapRotation(double turns) {
  final normalized = turns % 1.0;
  return normalized < 0 ? normalized + 1.0 : normalized;
}

BodyMapSide _bodyMapSideForRotation(double turns) {
  final normalized = _normalizeBodyMapRotation(turns);
  return normalized >= 0.25 && normalized < 0.75
      ? BodyMapSide.back
      : BodyMapSide.front;
}

double _bodyMapWidthScaleForRotation(double turns) {
  final normalized = _normalizeBodyMapRotation(turns);
  final sideCompression = math.cos(normalized * math.pi * 2).abs();
  return 0.42 + (sideCompression * 0.58);
}

double _bodyMapSideAmountForRotation(double turns) {
  final normalized = _normalizeBodyMapRotation(turns);
  return 1 - math.cos(normalized * math.pi * 2).abs();
}

String _bodyMapViewLabelFor(double turns) {
  final widthScale = _bodyMapWidthScaleForRotation(turns);
  if (widthScale < 0.68) {
    return 'Side view';
  }
  return _bodyMapSideForRotation(turns) == BodyMapSide.back
      ? 'Back view'
      : 'Front view';
}

class HistoryOverviewPage extends StatefulWidget {
  final List<ScanRecord> records;
  final ValueChanged<String> onAddBodyArea;

  const HistoryOverviewPage({
    super.key,
    required this.records,
    required this.onAddBodyArea,
  });

  @override
  State<HistoryOverviewPage> createState() => _HistoryOverviewPageState();
}

class _HistoryOverviewPageState extends State<HistoryOverviewPage> {
  String? _selectedPatient;
  HistoryDisplayMode _displayMode = HistoryDisplayMode.normal;

  void _openBodyAreaHistory({
    required String bodyArea,
    required List<ScanRecord> patientRecords,
  }) {
    final patientName = _selectedPatient;
    if (patientName == null) {
      return;
    }

    Navigator.of(context).push(
      _buildRoute(
        BodyAreaHistoryPage(
          patientName: patientName,
          bodyArea: bodyArea,
          records: patientRecords
              .where((record) => record.bodyArea == bodyArea)
              .toList(),
        ),
      ),
    );
  }

  List<BodyMapMarker> _visualMarkersFor({
    required List<ScanRecord> patientRecords,
    required List<String> bodyAreas,
  }) {
    return bodyAreas
        .map((bodyArea) {
          final areaRecords = patientRecords
              .where((record) => record.bodyArea == bodyArea)
              .toList(growable: false);

          return BodyMapMarker(
            bodyArea: bodyArea,
            count: areaRecords.length,
            tint: _markerTintFor(areaRecords),
          );
        })
        .toList(growable: false);
  }

  Color _markerTintFor(List<ScanRecord> records) {
    final statuses = records.map((record) => record.status.toLowerCase());
    if (statuses.any((status) => status.contains('specialist'))) {
      return AppPalette.danger;
    }
    if (statuses.any((status) => status.contains('caution'))) {
      return AppPalette.warning;
    }
    if (statuses.any((status) => status.contains('monitor'))) {
      return AppPalette.primary;
    }
    return AppPalette.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availablePatients =
        widget.records
            .map((record) => record.patientName.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final patientFilteredRecords = _selectedPatient == null
        ? <ScanRecord>[]
        : widget.records
              .where((record) => record.patientName == _selectedPatient)
              .toList();
    final availableBodyAreas =
        patientFilteredRecords
            .map((record) => record.bodyArea.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return AppShellPageLayout(
      title: 'Scan History',
      subtitle:
          'Select a patient first, then open a saved body area to review its lesions and scan details.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('History view', style: theme.textTheme.titleLarge),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Normal View'),
                    selected: _displayMode == HistoryDisplayMode.normal,
                    onSelected: (_) {
                      setState(() => _displayMode = HistoryDisplayMode.normal);
                    },
                    selectedColor: AppPalette.primarySoftFor(context),
                    backgroundColor: AppPalette.surfaceFor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: _displayMode == HistoryDisplayMode.normal
                            ? AppPalette.primaryFor(context)
                            : AppPalette.lineFor(context),
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _displayMode == HistoryDisplayMode.normal
                          ? AppPalette.primaryFor(context)
                          : AppPalette.inkFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Full Visual Detail'),
                    selected: _displayMode == HistoryDisplayMode.visual,
                    onSelected: (_) {
                      setState(() => _displayMode = HistoryDisplayMode.visual);
                    },
                    selectedColor: AppPalette.primarySoftFor(context),
                    backgroundColor: AppPalette.surfaceFor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: _displayMode == HistoryDisplayMode.visual
                            ? AppPalette.primaryFor(context)
                            : AppPalette.lineFor(context),
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: _displayMode == HistoryDisplayMode.visual
                          ? AppPalette.primaryFor(context)
                          : AppPalette.inkFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select patient', style: theme.textTheme.titleLarge),
              const SizedBox(height: 14),
              if (availablePatients.isEmpty)
                Text(
                  'No patients have saved scan history yet. Save a scan first and the patient will appear here.',
                  style: theme.textTheme.bodyLarge,
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availablePatients.map((patientName) {
                    final isSelected = _selectedPatient == patientName;

                    return ChoiceChip(
                      label: Text(patientName),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedPatient = patientName;
                        });
                      },
                      selectedColor: AppPalette.primarySoftFor(context),
                      backgroundColor: AppPalette.surfaceFor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: isSelected
                              ? AppPalette.primaryFor(context)
                              : AppPalette.lineFor(context),
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppPalette.primaryFor(context)
                            : AppPalette.inkFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_selectedPatient == null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a patient to continue',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'After you select a patient, this page will show only that patient\'s body areas with saved moles.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          if (_displayMode == HistoryDisplayMode.normal)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Saved body areas for $_selectedPatient',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => widget.onAddBodyArea(''),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add body area'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (availableBodyAreas.isEmpty)
                    Text(
                      'This patient does not have any saved body areas yet.',
                      style: theme.textTheme.bodyLarge,
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableBodyAreas
                          .map(
                            (bodyArea) => ActionChip(
                              avatar: Icon(
                                Icons.accessibility_new_rounded,
                                size: 18,
                                color: AppPalette.primaryFor(context),
                              ),
                              label: Text(bodyArea),
                              onPressed: () {
                                _openBodyAreaHistory(
                                  bodyArea: bodyArea,
                                  patientRecords: patientFilteredRecords,
                                );
                              },
                              backgroundColor: AppPalette.surfaceFor(context),
                              side: BorderSide(
                                color: AppPalette.lineFor(context),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            )
          else
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Full visual detail',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => widget.onAddBodyArea(''),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap a colored body marker to open that area and review its saved lesion timeline.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (availableBodyAreas.isEmpty)
                    Text(
                      'This patient does not have any saved body areas yet.',
                      style: theme.textTheme.bodyLarge,
                    )
                  else ...[
                    BodyMapView(
                      markers: _visualMarkersFor(
                        patientRecords: patientFilteredRecords,
                        bodyAreas: availableBodyAreas,
                      ),
                      showLabels: true,
                      showCounts: true,
                      onAreaSelected: (bodyArea) {
                        _openBodyAreaHistory(
                          bodyArea: bodyArea,
                          patientRecords: patientFilteredRecords,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Green means low-risk saved records, blue means monitor closely, yellow means caution, and red means specialist review was recommended.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

enum StoredAssetType { rawPhoto, illustration }

class StoredAssetPreview extends StatelessWidget {
  final String title;
  final ScanRecord record;
  final StoredAssetType assetType;

  const StoredAssetPreview({
    super.key,
    required this.title,
    required this.record,
    required this.assetType,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = switch (assetType) {
      StoredAssetType.rawPhoto => record.rawImageUrl,
      StoredAssetType.illustration => record.illustrationImageUrl,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppPalette.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildStoredImage(imageUrl),
        ),
      ],
    );
  }

  Widget _buildStoredImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (imageUrl.startsWith('preview://')) {
      return Container(
        height: 220,
        width: double.infinity,
        color: AppPalette.surface,
        alignment: Alignment.center,
        child: const Text(
          'Preview stored for test mode',
          style: TextStyle(
            color: AppPalette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final file = File(imageUrl);
    if (!file.existsSync()) {
      return Container(
        height: 220,
        width: double.infinity,
        color: AppPalette.surface,
        alignment: Alignment.center,
        child: const Text(
          'Saved image file was not found on this device',
          style: TextStyle(
            color: AppPalette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Image.file(
      file,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class LesionComparisonSummaryCard extends StatelessWidget {
  final LesionComparisonSnapshot comparison;

  const LesionComparisonSummaryCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final latest = comparison.latest;
    final previous = comparison.previous;
    final riskDelta = comparison.riskDelta;
    final coverageDelta = comparison.coverageDelta;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest comparison',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          if (previous == null)
            Text(
              'Only one saved visit is available for this lesion. Save another follow-up scan to compare changes over time.',
              style: Theme.of(context).textTheme.bodyLarge,
            )
          else ...[
            DetailRow(
              label: 'Latest visit',
              value: _formatDateLabel(latest.capturedAt),
            ),
            const SizedBox(height: 10),
            DetailRow(
              label: 'Previous visit',
              value: _formatDateLabel(previous.capturedAt),
            ),
            const SizedBox(height: 10),
            DetailRow(
              label: 'Class change',
              value: latest.predictedClass == previous.predictedClass
                  ? latest.predictedClass
                  : '${previous.predictedClass} -> ${latest.predictedClass}',
            ),
            const SizedBox(height: 10),
            DetailRow(
              label: 'Risk change',
              value: riskDelta == null
                  ? 'Not enough data'
                  : '${latest.riskScore!.toStringAsFixed(1)}% (${riskDelta >= 0 ? '+' : ''}${riskDelta.toStringAsFixed(1)}%)',
            ),
            const SizedBox(height: 10),
            DetailRow(
              label: 'Coverage change',
              value: coverageDelta == null
                  ? 'Not measured'
                  : '${latest.lesionCoveragePercent!.toStringAsFixed(1)}% (${coverageDelta >= 0 ? '+' : ''}${coverageDelta.toStringAsFixed(1)}%)',
            ),
            const SizedBox(height: 12),
            Text(
              latest.summary.isNotEmpty
                  ? latest.summary
                  : 'Review the latest summary and compare it with the previous visit for visible changes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _GhostReferencePreview extends StatelessWidget {
  final ScanRecord record;

  const _GhostReferencePreview({required this.record});

  @override
  Widget build(BuildContext context) {
    final imageUrl = record.imageUrl;

    if (imageUrl.startsWith('http')) {
      return Opacity(
        opacity: 0.2,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          color: Colors.white.withValues(alpha: 0.75),
          colorBlendMode: BlendMode.screen,
        ),
      );
    }

    if (imageUrl.startsWith('preview://')) {
      return Container(
        color: Colors.white.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: const Icon(
          Icons.gesture_outlined,
          color: Colors.white70,
          size: 38,
        ),
      );
    }

    final file = File(imageUrl);
    if (!file.existsSync()) {
      return Container(
        color: Colors.white.withValues(alpha: 0.06),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white70,
          size: 34,
        ),
      );
    }

    return Opacity(
      opacity: 0.2,
      child: Image.file(
        file,
        fit: BoxFit.cover,
        color: Colors.white.withValues(alpha: 0.75),
        colorBlendMode: BlendMode.screen,
      ),
    );
  }
}

class BodyAreaHistoryPage extends StatefulWidget {
  final String patientName;
  final String bodyArea;
  final List<ScanRecord> records;

  const BodyAreaHistoryPage({
    super.key,
    required this.patientName,
    required this.bodyArea,
    required this.records,
  });

  @override
  State<BodyAreaHistoryPage> createState() => _BodyAreaHistoryPageState();
}

class _BodyAreaHistoryPageState extends State<BodyAreaHistoryPage> {
  static const LesionTrackingService _lesionTrackingService =
      LesionTrackingService();
  String? _selectedLesionFilter;
  int _selectedEntryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppPalette.isDark(context);
    final pageBackground = isDark ? AppPalette.darkCanvas : AppPalette.canvas;
    final lesionLabels = _lesionTrackingService.lesionLabelsFor(widget.records);
    final activeLesion =
        _selectedLesionFilter ??
        (lesionLabels.isNotEmpty ? lesionLabels.first : null);
    final filteredRecords = activeLesion == null
        ? <ScanRecord>[]
        : _lesionTrackingService.timelineForLesion(
            records: widget.records,
            lesionLabel: activeLesion,
          );
    final comparison = activeLesion == null
        ? null
        : _lesionTrackingService.buildComparison(
            records: widget.records,
            lesionLabel: activeLesion,
          );
    final hasRecords = filteredRecords.isNotEmpty;
    final selectedIndex = hasRecords
        ? _selectedEntryIndex.clamp(0, filteredRecords.length - 1)
        : 0;
    final selectedEntry = hasRecords ? filteredRecords[selectedIndex] : null;
    final showSelectedEntryIllustration =
        selectedEntry != null &&
        selectedEntry.hasIllustrationImage &&
        !_isLowRiskNonMelanomaRecord(selectedEntry);
    final showSelectedEntryAssets =
        selectedEntry != null &&
        (selectedEntry.hasRawImage || showSelectedEntryIllustration);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        surfaceTintColor: pageBackground,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.bodyArea, style: theme.textTheme.titleLarge),
            Text(widget.patientName, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: AppPremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved lesion spots',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (lesionLabels.isEmpty)
                        Text(
                          'No lesion spots were saved for this body area yet.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: lesionLabels
                              .map(
                                (label) => ChoiceChip(
                                  label: Text(label),
                                  selected: activeLesion == label,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedLesionFilter = label;
                                      _selectedEntryIndex = 0;
                                    });
                                  },
                                  selectedColor: AppPalette.primarySoftFor(
                                    context,
                                  ),
                                  backgroundColor: AppPalette.surfaceFor(
                                    context,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    side: BorderSide(
                                      color: activeLesion == label
                                          ? AppPalette.primaryFor(context)
                                          : AppPalette.lineFor(context),
                                    ),
                                  ),
                                  labelStyle: TextStyle(
                                    color: activeLesion == label
                                        ? AppPalette.primaryFor(context)
                                        : AppPalette.inkFor(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (!hasRecords) ...[
                  AppCard(
                    child: Text(
                      'Select a lesion spot to review its saved scan history.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ] else ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved lesion timeline',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        for (var i = 0; i < filteredRecords.length; i++) ...[
                          HistoryEntryTile(
                            record: filteredRecords[i],
                            isSelected: i == selectedIndex,
                            onTap: () {
                              setState(() => _selectedEntryIndex = i);
                            },
                          ),
                          if (i != filteredRecords.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                  if (comparison != null) ...[
                    const SizedBox(height: 18),
                    LesionComparisonSummaryCard(comparison: comparison),
                  ],
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${selectedEntry!.patientName} - ${selectedEntry.location}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDateLabel(selectedEntry.capturedAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        if (showSelectedEntryAssets) ...[
                          Text(
                            showSelectedEntryIllustration
                                ? selectedEntry.savedAssetLabel
                                : 'Saved raw scan photo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (selectedEntry.hasRawImage) ...[
                            StoredAssetPreview(
                              title: 'Saved raw scan photo',
                              record: selectedEntry,
                              assetType: StoredAssetType.rawPhoto,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (showSelectedEntryIllustration) ...[
                            StoredAssetPreview(
                              title: 'Generated lesion illustration',
                              record: selectedEntry,
                              assetType: StoredAssetType.illustration,
                            ),
                            const SizedBox(height: 18),
                          ],
                        ],
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppPalette.primarySoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Care summary',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppPalette.primary),
                              ),
                              const SizedBox(height: 8),
                              DetailRow(
                                label: 'Status',
                                value: selectedEntry.status,
                              ),
                              const SizedBox(height: 10),
                              DetailRow(
                                label: 'Patient',
                                value: selectedEntry.patientName,
                              ),
                              const SizedBox(height: 10),
                              if (selectedEntry.patientAge.isNotEmpty) ...[
                                DetailRow(
                                  label: 'Age',
                                  value: selectedEntry.patientAge,
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (selectedEntry.patientContact.isNotEmpty) ...[
                                DetailRow(
                                  label: 'Contact',
                                  value: selectedEntry.patientContact,
                                ),
                                const SizedBox(height: 10),
                              ],
                              DetailRow(
                                label: 'Class',
                                value: selectedEntry.predictedClass,
                              ),
                              const SizedBox(height: 10),
                              DetailRow(
                                label: 'Body area',
                                value: selectedEntry.bodyArea,
                              ),
                              const SizedBox(height: 10),
                              DetailRow(
                                label: 'Source',
                                value: selectedEntry.captureSource,
                              ),
                              const SizedBox(height: 10),
                              DetailRow(
                                label: 'Risk score',
                                value: selectedEntry.riskScore == null
                                    ? 'Pending'
                                    : '${selectedEntry.riskScore!.toStringAsFixed(1)}%',
                              ),
                              const SizedBox(height: 10),
                              DetailRow(
                                label: 'Visible lesion area',
                                value:
                                    selectedEntry.lesionCoveragePercent == null
                                    ? 'Not measured'
                                    : '${selectedEntry.lesionCoveragePercent!.toStringAsFixed(1)}%',
                              ),
                              if (selectedEntry.hasFollowUpReminder) ...[
                                const SizedBox(height: 10),
                                DetailRow(
                                  label: 'Reminder',
                                  value: selectedEntry.isFollowUpReminderDue
                                      ? 'Follow-up due now'
                                      : 'Follow-up scheduled',
                                ),
                                const SizedBox(height: 10),
                                DetailRow(
                                  label: 'Next check',
                                  value: _formatDateLabel(
                                    selectedEntry.followUpReminderDate!,
                                  ),
                                ),
                              ],
                              if (selectedEntry
                                  .imageQualityStatus
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                DetailRow(
                                  label: 'Photo quality',
                                  value:
                                      '${selectedEntry.imageQualityScore?.round() ?? 0}/100 - ${selectedEntry.imageQualityStatus}',
                                ),
                              ],
                              if (selectedEntry
                                  .imageQualitySummary
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  selectedEntry.imageQualitySummary,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppPalette.ink),
                                ),
                              ],
                              const SizedBox(height: 10),
                              DetailRow(
                                label: 'Note',
                                value: selectedEntry.note.isEmpty
                                    ? 'No note added'
                                    : selectedEntry.note,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                selectedEntry.questionnaireSummary.isEmpty
                                    ? 'No questionnaire details were saved for this scan.'
                                    : selectedEntry.questionnaireSummary,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppPalette.ink),
                              ),
                              if (selectedEntry
                                  .baselineRiskSummary
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  selectedEntry.baselineRiskSummary,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppPalette.ink),
                                ),
                              ],
                              if (selectedEntry
                                  .combinedRiskSummary
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  selectedEntry.combinedRiskSummary,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppPalette.ink),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                selectedEntry.summary,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppPalette.ink),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                selectedEntry.nextStep,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PreScanSafetyNoticeCard extends StatelessWidget {
  const PreScanSafetyNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppPalette.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: AppPalette.warning,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan safety note',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the AI result as follow-up guidance, not a diagnosis. Save the first scan as a baseline, follow the reminder, and contact a doctor if the spot changes, bleeds, hurts, or worries you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PatientRiskContextCard extends StatelessWidget {
  final String baselineSummary;
  final String scanQuestionnaireSummary;
  final String combinedSummary;
  final int flagCount;

  const PatientRiskContextCard({
    super.key,
    required this.baselineSummary,
    required this.scanQuestionnaireSummary,
    required this.combinedSummary,
    required this.flagCount,
  });

  @override
  Widget build(BuildContext context) {
    final tint = flagCount >= 4
        ? AppPalette.danger
        : flagCount >= 2
        ? AppPalette.warning
        : flagCount == 1
        ? AppPalette.primary
        : AppPalette.success;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.fact_check_outlined, color: tint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient context used',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$flagCount supporting risk-context flag${flagCount == 1 ? '' : 's'} selected.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(combinedSummary, style: Theme.of(context).textTheme.bodyMedium),
          if (flagCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              '$baselineSummary $scanQuestionnaireSummary',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class ResultActionGuidanceCard extends StatelessWidget {
  final ScanPredictionResult prediction;

  const ResultActionGuidanceCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final action = _ResultActionInfo.fromPrediction(prediction);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: action.tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(action.icon, color: action.tint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended next step',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  action.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: action.tint),
                ),
                const SizedBox(height: 6),
                Text(
                  action.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (action.note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    action.note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: action.tint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultActionInfo {
  final String title;
  final String description;
  final String note;
  final IconData icon;
  final Color tint;

  const _ResultActionInfo({
    required this.title,
    required this.description,
    required this.note,
    required this.icon,
    required this.tint,
  });

  factory _ResultActionInfo.fromPrediction(ScanPredictionResult prediction) {
    final status = prediction.status.toLowerCase();

    if (status.contains('retake')) {
      return const _ResultActionInfo(
        title: 'Retake the photo now',
        description:
            'The image is not clear enough for a reliable review. Take another close, well-lit photo before saving this scan.',
        note: 'Immediate retake recommended',
        icon: Icons.photo_camera_back_outlined,
        tint: AppPalette.primary,
      );
    }

    if (status.contains('specialist')) {
      return const _ResultActionInfo(
        title: 'Specialist review recommended',
        description:
            'Do not wait for another app re-scan. Arrange a dermatologist or qualified clinician review as soon as possible.',
        note: 'Urgent review guidance',
        icon: Icons.local_hospital_outlined,
        tint: AppPalette.danger,
      );
    }

    if (status.contains('caution')) {
      return const _ResultActionInfo(
        title: 'Doctor review advised',
        description:
            'Save this result and arrange a clinician review. A short reminder can help you compare the same spot again.',
        note: 'Short follow-up reminder suggested',
        icon: Icons.medical_information_outlined,
        tint: AppPalette.warning,
      );
    }

    if (status.contains('monitor')) {
      return const _ResultActionInfo(
        title: 'Monitor the same lesion',
        description:
            'Save this as a comparison point and re-scan the same mole in 7 to 14 days using the same body area and spot label.',
        note: '7 to 14 day follow-up suggested',
        icon: Icons.event_repeat_outlined,
        tint: AppPalette.primary,
      );
    }

    return const _ResultActionInfo(
      title: 'Save as a baseline scan',
      description:
          'Use this as a baseline for routine self-checks. Re-check monthly and contact a doctor if the spot changes or worries you.',
      note: 'Monthly baseline reminder suggested',
      icon: Icons.bookmark_added_outlined,
      tint: AppPalette.success,
    );
  }
}

class FollowUpReminderSettingCard extends StatelessWidget {
  final bool enabled;
  final int days;
  final DateTime nextReviewDate;
  final bool locked;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onDaysChanged;

  const FollowUpReminderSettingCard({
    super.key,
    required this.enabled,
    required this.days,
    required this.nextReviewDate,
    this.locked = false,
    required this.onEnabledChanged,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = enabled ? AppPalette.primaryFor(context) : AppPalette.muted;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.notification_important_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Follow-up reminder',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Optional reminder to review this same spot again.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: locked ? null : onEnabledChanged,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ReminderDaysChip(
                  label: '7 days',
                  selected: days == 7,
                  onTap: locked ? null : () => onDaysChanged(7),
                ),
                _ReminderDaysChip(
                  label: '14 days',
                  selected: days == 14,
                  onTap: locked ? null : () => onDaysChanged(14),
                ),
                _ReminderDaysChip(
                  label: '30 days',
                  selected: days == 30,
                  onTap: locked ? null : () => onDaysChanged(30),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DetailRow(
              label: 'Next check',
              value: _formatDateLabel(nextReviewDate),
            ),
            const SizedBox(height: 12),
            Text(
              locked
                  ? 'This reminder setting has been saved with the scan record.'
                  : 'This supports self-monitoring only and does not replace medical care.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderDaysChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ReminderDaysChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      selectedColor: AppPalette.primarySoftFor(context),
      backgroundColor: AppPalette.surfaceFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected
              ? AppPalette.primaryFor(context)
              : AppPalette.lineFor(context),
        ),
      ),
      labelStyle: TextStyle(
        color: selected
            ? AppPalette.primaryFor(context)
            : AppPalette.inkFor(context),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class QuestionnaireToggleTile extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const QuestionnaireToggleTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

enum LearnSection { abcde, stages, prevention }

class LearnOverviewPage extends StatefulWidget {
  const LearnOverviewPage({super.key});

  @override
  State<LearnOverviewPage> createState() => _LearnOverviewPageState();
}

class _LearnOverviewPageState extends State<LearnOverviewPage> {
  LearnSection _section = LearnSection.prevention;

  @override
  Widget build(BuildContext context) {
    return AppShellPageLayout(
      title: 'Learn',
      subtitle:
          'Read simple guidance about warning signs, melanoma stages, and everyday prevention.',
      children: [
        const UvWarningCard(),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse topics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  LearnSectionChip(
                    label: 'Prevention',
                    selected: _section == LearnSection.prevention,
                    onTap: () =>
                        setState(() => _section = LearnSection.prevention),
                  ),
                  LearnSectionChip(
                    label: 'ABCDE Rule',
                    selected: _section == LearnSection.abcde,
                    onTap: () => setState(() => _section = LearnSection.abcde),
                  ),
                  LearnSectionChip(
                    label: 'Melanoma Stages',
                    selected: _section == LearnSection.stages,
                    onTap: () => setState(() => _section = LearnSection.stages),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_section == LearnSection.abcde)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABCDE quick guide',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < kAbcdeTopics.length; i++) ...[
                  EducationTopicCard(topic: kAbcdeTopics[i]),
                  if (i != kAbcdeTopics.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        if (_section == LearnSection.stages)
          const MelanomaStagesEducationContent(),
        if (_section == LearnSection.prevention)
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prevention tips',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.ink,
                  ),
                ),
                SizedBox(height: 16),
                StatusLine(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Current UV care',
                  value:
                      'Check the live UV card above before spending time in direct sunlight.',
                  tint: AppPalette.danger,
                ),
                SizedBox(height: 12),
                StatusLine(
                  icon: Icons.shield_outlined,
                  title: 'Sun protection',
                  value:
                      'Use sunscreen, protective clothing, and shade during high UV hours.',
                  tint: AppPalette.warning,
                ),
                SizedBox(height: 12),
                StatusLine(
                  icon: Icons.search_rounded,
                  title: 'Monthly self-check',
                  value:
                      'Look for new spots or changes in existing moles using the ABCDE rule.',
                  tint: AppPalette.primary,
                ),
                SizedBox(height: 12),
                StatusLine(
                  icon: Icons.event_available_outlined,
                  title: 'Follow-up consistency',
                  value:
                      'Use the same body location, angle, and timing for better visual comparison.',
                  tint: AppPalette.success,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ProfileOverviewPage extends StatefulWidget {
  final AppUser? user;

  const ProfileOverviewPage({super.key, required this.user});

  @override
  State<ProfileOverviewPage> createState() => _ProfileOverviewPageState();
}

class _ProfileOverviewPageState extends State<ProfileOverviewPage> {
  late bool _remindersEnabled;
  late bool _doctorRoutingEnabled;
  late bool _emailSummariesEnabled;

  @override
  void initState() {
    super.initState();
    _remindersEnabled = true;
    _doctorRoutingEnabled = true;
    _emailSummariesEnabled = false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final themeScope = SkinSafeThemeScope.of(context);
    final theme = Theme.of(context);
    final user = widget.user;

    return AppShellPageLayout(
      title: 'Profile',
      subtitle:
          'Review your account details and choose how the app supports your follow-up care.',
      headerTrailing: UserAvatarBadge(initials: user?.initials ?? 'SS'),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Details', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              DetailRow(label: 'Name', value: user?.name ?? '-'),
              const SizedBox(height: 12),
              DetailRow(label: 'Email', value: user?.email ?? '-'),
              const SizedBox(height: 12),
              DetailRow(
                label: 'Age',
                value: user?.age.trim().isEmpty == true
                    ? '-'
                    : user?.age ?? '-',
              ),
              const SizedBox(height: 12),
              DetailRow(
                label: 'Contact',
                value: user?.contact.trim().isEmpty == true
                    ? '-'
                    : user?.contact ?? '-',
              ),
              const SizedBox(height: 12),
              DetailRow(
                label: 'Sun type',
                value: user?.skinReaction ?? 'Not specified',
              ),
              const SizedBox(height: 18),
              Text('Baseline Skin Profile', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              StatusLine(
                icon: Icons.scatter_plot_outlined,
                title: 'Many or unusual moles',
                value: user?.manyMolesReported == true
                    ? 'Reported'
                    : 'Not reported',
                tint: AppPalette.primary,
              ),
              const SizedBox(height: 12),
              StatusLine(
                icon: Icons.wb_sunny_outlined,
                title: 'Sunburn or tanning history',
                value: user?.sunburnOrTanningHistoryReported == true
                    ? 'Reported'
                    : 'Not reported',
                tint: AppPalette.warning,
              ),
              const SizedBox(height: 12),
              StatusLine(
                icon: Icons.family_restroom_outlined,
                title: 'Family skin cancer history',
                value: user?.familySkinCancerHistoryReported == true
                    ? 'Reported'
                    : 'Not reported',
                tint: AppPalette.aqua,
              ),
              const SizedBox(height: 12),
              StatusLine(
                icon: Icons.medical_information_outlined,
                title: 'Previous skin cancer concern',
                value: user?.previousSkinCancerHistoryReported == true
                    ? 'Reported'
                    : 'Not reported',
                tint: AppPalette.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferences', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              ScanSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                description:
                    'Use a deep blue-green interface for low-light checking.',
                value: themeScope.isDarkMode,
                onChanged: themeScope.onDarkModeChanged,
              ),
              const SizedBox(height: 14),
              ScanSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Follow-up reminders',
                description:
                    'Allow the app to suggest when the next check should happen.',
                value: _remindersEnabled,
                onChanged: (value) {
                  setState(() => _remindersEnabled = value);
                },
              ),
              const SizedBox(height: 14),
              ScanSettingTile(
                icon: Icons.local_hospital_outlined,
                title: 'Doctor routing suggestions',
                description:
                    'Show clinic and dermatologist actions after cautionary results.',
                value: _doctorRoutingEnabled,
                onChanged: (value) {
                  setState(() => _doctorRoutingEnabled = value);
                },
              ),
              const SizedBox(height: 14),
              ScanSettingTile(
                icon: Icons.email_outlined,
                title: 'Email summary preference',
                description:
                    'Prepare for future shareable scan summaries and report delivery.',
                value: _emailSummariesEnabled,
                onChanged: (value) {
                  setState(() => _emailSummariesEnabled = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy and safety', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              const StatusLine(
                icon: Icons.verified_user_outlined,
                title: 'Medical use warning',
                value:
                    'SkinSafe provides screening support only and should not be used as a confirmed diagnosis.',
                tint: AppPalette.warning,
              ),
              const SizedBox(height: 12),
              const StatusLine(
                icon: Icons.storage_rounded,
                title: 'Stored data',
                value:
                    'The app stores account details, scan photos, generated illustrations, and scan history for follow-up tracking.',
                tint: AppPalette.primary,
              ),
              const SizedBox(height: 12),
              const StatusLine(
                icon: Icons.location_on_outlined,
                title: 'Location use',
                value:
                    'Location is used only to estimate UV exposure guidance when available.',
                tint: AppPalette.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Logout',
          isLoading: false,
          onPressed: () async {
            await auth.signOut();
          },
        ),
      ],
    );
  }
}

final UvForecastService _uvForecastService = UvForecastService();

Color _uvColorForIndex(double uvIndex) {
  if (uvIndex >= 8) {
    return AppPalette.danger;
  }
  if (uvIndex >= 3) {
    return AppPalette.warning;
  }
  return AppPalette.success;
}

String _uvLabelForIndex(double uvIndex) {
  if (uvIndex >= 8) {
    return 'High';
  }
  if (uvIndex >= 3) {
    return 'Moderate';
  }
  return 'Low';
}

class UvWarningCard extends StatefulWidget {
  const UvWarningCard({super.key});

  @override
  State<UvWarningCard> createState() => _UvWarningCardState();
}

class _UvWarningCardState extends State<UvWarningCard> {
  late Future<UvForecastSummary> _uvFuture;

  @override
  void initState() {
    super.initState();
    _uvFuture = _uvForecastService.loadCurrentUv();
  }

  void _retry() {
    setState(() {
      _uvFuture = _uvForecastService.loadCurrentUv(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UvForecastSummary>(
      future: _uvFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Current UV',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to load live UV right now. Tap retry to try again.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Current UV',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  minHeight: 8,
                  backgroundColor: AppPalette.primarySoft,
                  color: AppPalette.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading the current UV level...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final forecast = snapshot.data!;
        final riskColor = _uvColorForIndex(forecast.currentUvIndex);

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.wb_sunny_outlined, color: riskColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current UV',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_uvLabelForIndex(forecast.currentUvIndex)} exposure level around ${forecast.observedAtLabel}.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'UV ${forecast.currentUvIndex.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                forecast.currentUvIndex >= 8
                    ? 'Try to avoid direct sun right now and use shade, sunscreen, and protective clothing.'
                    : forecast.currentUvIndex >= 3
                    ? 'Use sunscreen and reduce long sun exposure if you will be outside.'
                    : 'UV is lower right now, but sun protection is still a good habit.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              Text(
                forecast.isFallback
                    ? 'Live UV could not be confirmed, so an estimated regional value is shown.'
                    : forecast.sourceLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class AppShellPageLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? headerTrailing;
  final List<Widget> children;

  const AppShellPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    this.headerTrailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        const Positioned.fill(child: AppPremiumBackground()),
        Positioned(
          top: -92,
          right: -118,
          child: _BackgroundGlow(
            size: 260,
            color: AppPalette.primaryFor(context).withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          top: 112,
          left: -150,
          child: _BackgroundGlow(
            size: 260,
            color: AppPalette.aqua.withValues(alpha: 0.07),
          ),
        ),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CompactBrand(),
                    const Spacer(),
                    ...?(headerTrailing == null
                        ? null
                        : <Widget>[headerTrailing!]),
                  ],
                ),
                const SizedBox(height: 30),
                Text(title, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(subtitle, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AppPremiumBackground extends StatelessWidget {
  final Widget? child;

  const AppPremiumBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF06161B),
                  Color(0xFF082B32),
                  Color(0xFF0B2228),
                  Color(0xFF051014),
                ]
              : const [
                  Color(0xFFFBFEFF),
                  Color(0xFFEAF8FA),
                  Color(0xFFEFFBF6),
                  Color(0xFFF7FCFC),
                ],
          stops: const [0.0, 0.34, 0.72, 1.0],
        ),
      ),
      child: child,
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 24),
          ],
        ),
      ),
    );
  }
}

class OnboardingCard extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingCard({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [slide.accent, AppPalette.primary],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'SkinSafe Tutorial',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(slide.title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(slide.description, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? AppPalette.darkSurfaceHigh.withValues(alpha: 0.82)
            : AppPalette.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? AppPalette.darkLine.withValues(alpha: 0.58)
              : AppPalette.line.withValues(alpha: 0.62),
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.shadowFor(context),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const AppTopBar({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.surfaceFor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? AppPalette.darkLine
                    : Colors.white.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.shadowFor(context),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppPalette.inkFor(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppPalette.mutedFor(context), size: 20),
        suffixIcon: suffixIcon,
        hintText: hint,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primaryFor(context),
          foregroundColor: AppPalette.isDark(context)
              ? AppPalette.darkCanvas
              : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: theme.textTheme.titleMedium)),
      ],
    );
  }
}

class StatusLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color tint;

  const StatusLine({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AppPalette.isDark(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isDark
                  ? AppPalette.darkLine.withValues(alpha: 0.62)
                  : Colors.white.withValues(alpha: 0.72),
            ),
          ),
          child: Icon(icon, color: tint, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class ScanPreviewCard extends StatelessWidget {
  final ScanFlowStage stage;
  final bool autoScanEnabled;
  final bool flashEnabled;
  final bool ghostOutlineEnabled;
  final Uint8List? previewBytes;
  final String stabilityLabel;

  const ScanPreviewCard({
    super.key,
    required this.stage,
    required this.autoScanEnabled,
    required this.flashEnabled,
    required this.ghostOutlineEnabled,
    required this.previewBytes,
    required this.stabilityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isAnalyzing = stage == ScanFlowStage.analyzing;
    final isComplete = stage == ScanFlowStage.result;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live scan preview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF10324A),
                  Color(0xFF1A5E6E),
                  Color(0xFF2B6F79),
                ],
              ),
            ),
            child: Stack(
              children: [
                if (previewBytes != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.memory(previewBytes!, fit: BoxFit.cover),
                    ),
                  ),
                if (previewBytes != null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: Colors.black.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: PreviewTag(
                    label: isComplete
                        ? 'RESULT READY'
                        : isAnalyzing
                        ? 'ANALYZING'
                        : previewBytes == null
                        ? 'WAITING FOR PHOTO'
                        : 'PHOTO READY',
                    color: isComplete
                        ? AppPalette.success
                        : isAnalyzing
                        ? AppPalette.warning
                        : AppPalette.aqua,
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Row(
                    children: [
                      PreviewIconBadge(
                        icon: flashEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                      ),
                      const SizedBox(width: 8),
                      PreviewIconBadge(
                        icon: ghostOutlineEnabled
                            ? Icons.flip_to_front_rounded
                            : Icons.crop_free_rounded,
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 214,
                      height: 214,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.84),
                          width: 2.4,
                        ),
                      ),
                    ),
                  ),
                ),
                if (ghostOutlineEnabled)
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.18,
                        child: Container(
                          width: 168,
                          height: 126,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: isComplete ? 88 : 72,
                      height: isComplete ? 88 : 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(
                        isComplete
                            ? Icons.check_rounded
                            : isAnalyzing
                            ? Icons.sync_rounded
                            : Icons.center_focus_strong_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stabilityLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isComplete
                              ? 'The raw scan photo and generated lesion illustration are ready to save on this device with scan metadata in history.'
                              : isAnalyzing
                              ? 'Preparing the selected image, scan details, and on-device model review.'
                              : previewBytes == null
                              ? 'Capture a lesion photo or choose an existing one before starting the guided scan.'
                              : 'Use this selected image as the source for the guided scan and history flow.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PreviewMiniPill(
                              label: autoScanEnabled
                                  ? 'Auto-Scan On'
                                  : 'Auto-Scan Off',
                            ),
                            const PreviewMiniPill(label: '2s Stability'),
                            PreviewMiniPill(
                              label: ghostOutlineEnabled
                                  ? 'Ghost Outline'
                                  : 'Free Capture',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveCameraCaptureScreen extends StatefulWidget {
  final String bodyArea;
  final bool ghostOutlineEnabled;
  final bool flashEnabled;
  final bool autoScanEnabled;
  final ScanRecord? followUpReference;

  const LiveCameraCaptureScreen({
    super.key,
    required this.bodyArea,
    required this.ghostOutlineEnabled,
    required this.flashEnabled,
    required this.autoScanEnabled,
    required this.followUpReference,
  });

  @override
  State<LiveCameraCaptureScreen> createState() =>
      _LiveCameraCaptureScreenState();
}

class _LiveCameraCaptureScreenState extends State<LiveCameraCaptureScreen> {
  static const double _stabilityMotionThreshold = 0.85;

  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _isCapturing = false;
  bool _isStabilityRunning = false;
  String? _errorMessage;
  Timer? _stabilityTimer;
  StreamSubscription<UserAccelerometerEvent>? _motionSubscription;
  int _stabilityCountdown = 2;
  double _motionMagnitude = 0;
  bool _isMotionStable = true;
  DateTime? _lastMotionSampleAt;

  bool get _hasRecentUnstableMotion {
    final lastSample = _lastMotionSampleAt;
    if (lastSample == null) {
      return false;
    }
    return !_isMotionStable &&
        DateTime.now().difference(lastSample) < const Duration(seconds: 1);
  }

  String get _captureModeLabel {
    if (widget.autoScanEnabled) {
      return 'Guided auto scan ready';
    }
    return 'Manual capture ready';
  }

  String get _captureInstruction {
    if (widget.autoScanEnabled) {
      return 'Hold the lesion steady inside the ring and keep the phone still for a clearer capture.';
    }
    return 'Center the lesion inside the ring, then tap the shutter when the image looks clear.';
  }

  String get _stabilityHeadline {
    if (_isCapturing) {
      return 'Capturing photo...';
    }
    if (_isStabilityRunning && _hasRecentUnstableMotion) {
      return 'Movement detected';
    }
    if (_isStabilityRunning) {
      return 'Hold steady for $_stabilityCountdown second${_stabilityCountdown == 1 ? '' : 's'}';
    }
    if (widget.autoScanEnabled) {
      return 'Start the 2-second guided hold';
    }
    return 'Manual capture is ready';
  }

  String get _stabilitySupportingText {
    if (_isCapturing) {
      return 'The camera is saving the current lesion image.';
    }
    if (_isStabilityRunning && _hasRecentUnstableMotion) {
      return 'Keep the phone still. The timer will continue once movement settles.';
    }
    if (_isStabilityRunning) {
      return 'Motion looks steady. Keep the lesion centered until capture.';
    }
    if (widget.autoScanEnabled) {
      return 'Tap start when the lesion is centered. The app will count down and capture automatically.';
    }
    return 'You can still use the guided hold before taking a manual photo.';
  }

  @override
  void initState() {
    super.initState();
    _startMotionMonitoring();
    _initializeFuture = _initializeCamera();
  }

  void _startMotionMonitoring() {
    _motionSubscription =
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        ).listen(
          (event) {
            final magnitude = math.sqrt(
              (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
            );
            final isStable = magnitude < _stabilityMotionThreshold;
            if (!mounted) {
              return;
            }

            setState(() {
              _motionMagnitude = magnitude;
              _isMotionStable = isStable;
              _lastMotionSampleAt = DateTime.now();
            });
          },
          onError: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isMotionStable = true;
              _lastMotionSampleAt = null;
            });
          },
        );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(
        widget.flashEnabled ? FlashMode.torch : FlashMode.off,
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _errorMessage = null;
      });
      if (widget.autoScanEnabled) {
        _startStabilityCountdown();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'The live camera could not be opened on this device right now.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (_isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    _cancelStabilityCountdown(resetCounter: false);
    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        SelectedScanImage(
          id: 'live-camera-${DateTime.now().microsecondsSinceEpoch}',
          name: file.name,
          path: file.path,
          bytes: bytes,
          source: ScanImageSource.camera,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to capture a photo from the live camera.';
      });
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _startStabilityCountdown() {
    if (_isCapturing || _isStabilityRunning) {
      return;
    }

    _stabilityTimer?.cancel();
    setState(() {
      _isStabilityRunning = true;
      _stabilityCountdown = 2;
      _errorMessage = null;
    });

    _stabilityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_hasRecentUnstableMotion) {
        setState(() => _stabilityCountdown = 2);
        return;
      }

      if (_stabilityCountdown <= 1) {
        timer.cancel();
        setState(() {
          _isStabilityRunning = false;
          _stabilityCountdown = 2;
        });
        unawaited(_capturePhoto());
        return;
      }

      setState(() {
        _stabilityCountdown -= 1;
      });
    });
  }

  void _cancelStabilityCountdown({bool resetCounter = true}) {
    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _isStabilityRunning = false;
      if (resetCounter) {
        _stabilityCountdown = 2;
      }
    });
  }

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    _motionSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initializeFuture,
          builder: (context, snapshot) {
            final controller = _controller;

            if (_errorMessage != null) {
              return _LiveCameraErrorState(
                message: _errorMessage!,
                onClose: () => Navigator.of(context).pop(),
              );
            }

            if (snapshot.connectionState != ConnectionState.done ||
                controller == null ||
                !controller.value.isInitialized) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(controller)),
                Positioned.fill(
                  child: _LiveCameraOverlay(
                    bodyArea: widget.bodyArea,
                    ghostOutlineEnabled: widget.ghostOutlineEnabled,
                    autoScanEnabled: widget.autoScanEnabled,
                    isStabilityRunning: _isStabilityRunning,
                    stabilityCountdown: _stabilityCountdown,
                    motionMagnitude: _motionMagnitude,
                    isMotionStable: !_hasRecentUnstableMotion,
                    followUpReference: widget.followUpReference,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _LiveCameraTopButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.38),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Live camera scan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Position the ${widget.bodyArea.toLowerCase()} area inside the guide ring.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _LiveCameraStatusBadge(
                                    color: const Color(0xFF83E2B6),
                                    label: _captureModeLabel,
                                  ),
                                  const SizedBox(width: 8),
                                  _LiveCameraStatusBadge(
                                    color: Colors.white,
                                    label: widget.ghostOutlineEnabled
                                        ? 'Follow-up alignment on'
                                        : 'New scan mode',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 26,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _captureInstruction,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _LiveCameraPill(
                                  icon: Icons.auto_mode_rounded,
                                  label: widget.autoScanEnabled
                                      ? 'Auto scan prepared'
                                      : 'Manual shutter',
                                ),
                                const _LiveCameraPill(
                                  icon: Icons.timer_outlined,
                                  label: '2-second steady hold',
                                ),
                                _LiveCameraPill(
                                  icon: Icons.flip_to_front_rounded,
                                  label: widget.ghostOutlineEnabled
                                      ? 'Follow-up alignment'
                                      : 'Fresh capture',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _LiveCameraCountdownPanel(
                              headline: _stabilityHeadline,
                              supportingText: _stabilitySupportingText,
                              countdown: _isStabilityRunning
                                  ? _stabilityCountdown.toString()
                                  : (widget.autoScanEnabled ? '2s' : 'Ready'),
                              isActive: _isStabilityRunning,
                              isMotionStable: !_hasRecentUnstableMotion,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _LiveCameraRoundButton(
                            icon: Icons.photo_library_outlined,
                            onTap: () => Navigator.of(context).pop(),
                            size: 54,
                            semanticLabel: 'Back to scan page',
                          ),
                          _LiveCameraShutterButton(
                            isLoading: _isCapturing,
                            onTap: _capturePhoto,
                          ),
                          _LiveCameraRoundButton(
                            icon: _isStabilityRunning
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            onTap: _isStabilityRunning
                                ? _cancelStabilityCountdown
                                : _startStabilityCountdown,
                            size: 54,
                            semanticLabel: _isStabilityRunning
                                ? 'Cancel guided hold'
                                : 'Start guided hold',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LiveCameraOverlay extends StatelessWidget {
  final String bodyArea;
  final bool ghostOutlineEnabled;
  final bool autoScanEnabled;
  final bool isStabilityRunning;
  final int stabilityCountdown;
  final double motionMagnitude;
  final bool isMotionStable;
  final ScanRecord? followUpReference;

  const _LiveCameraOverlay({
    required this.bodyArea,
    required this.ghostOutlineEnabled,
    required this.autoScanEnabled,
    required this.isStabilityRunning,
    required this.stabilityCountdown,
    required this.motionMagnitude,
    required this.isMotionStable,
    required this.followUpReference,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.14),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.22),
            ],
          ),
        ),
        child: Center(
          child: AspectRatio(
            aspectRatio: 0.82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.6,
                    ),
                  ),
                ),
                if (ghostOutlineEnabled)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 54,
                        vertical: 98,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(
                            0xFF8ED8FF,
                          ).withValues(alpha: 0.55),
                          width: 1.6,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (followUpReference != null)
                            _GhostReferencePreview(record: followUpReference!),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF8ED8FF,
                              ).withValues(alpha: 0.07),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  width: 232,
                  height: 232,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.82),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isStabilityRunning && !isMotionStable
                        ? const Color(0xFFE25663).withValues(alpha: 0.26)
                        : isStabilityRunning
                        ? const Color(0xFF2A8C68).withValues(alpha: 0.28)
                        : Colors.black.withValues(alpha: 0.24),
                    border: Border.all(
                      color: isStabilityRunning && !isMotionStable
                          ? const Color(0xFFFFB3BB)
                          : isStabilityRunning
                          ? const Color(0xFF83E2B6)
                          : Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                  child: Center(
                    child: isStabilityRunning
                        ? Text(
                            '$stabilityCountdown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : const Icon(
                            Icons.center_focus_strong_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                  ),
                ),
                Positioned(
                  top: 42,
                  child: _LiveCameraCenterLabel(
                    title: isStabilityRunning && !isMotionStable
                        ? 'Movement detected'
                        : isStabilityRunning
                        ? 'Keep the phone steady'
                        : autoScanEnabled
                        ? 'Hold steady for guided capture'
                        : 'Frame the lesion clearly',
                    subtitle: ghostOutlineEnabled
                        ? followUpReference == null
                              ? 'A ghost guide will appear here after this lesion has a saved follow-up image.'
                              : 'Match the previous saved lesion view as closely as possible.'
                        : 'Keep the most important skin change inside the ring.',
                  ),
                ),
                Positioned(
                  bottom: 58,
                  child: _LiveCameraAreaChip(
                    label: isStabilityRunning
                        ? '${isMotionStable ? 'Steady' : 'Moving'} ${motionMagnitude.toStringAsFixed(1)}'
                        : bodyArea,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveCameraTopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _LiveCameraTopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _LiveCameraPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LiveCameraPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCameraRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final String? semanticLabel;

  const _LiveCameraRoundButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Tooltip(
          message: semanticLabel ?? '',
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _LiveCameraStatusBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _LiveCameraStatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCameraCountdownPanel extends StatelessWidget {
  final String headline;
  final String supportingText;
  final String countdown;
  final bool isActive;
  final bool isMotionStable;

  const _LiveCameraCountdownPanel({
    required this.headline,
    required this.supportingText,
    required this.countdown,
    required this.isActive,
    required this.isMotionStable,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isMotionStable
        ? const Color(0xFF2A8C68)
        : const Color(0xFFE25663);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? activeColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              countdown,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  supportingText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCameraCenterLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LiveCameraCenterLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCameraAreaChip extends StatelessWidget {
  final String label;

  const _LiveCameraAreaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        'Body area: $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LiveCameraShutterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _LiveCameraShutterButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 84,
        height: 84,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _LiveCameraErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _LiveCameraErrorState({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Camera unavailable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Go Back',
                isLoading: false,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreviewTag extends StatelessWidget {
  final String label;
  final Color color;

  const PreviewTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewIconBadge extends StatelessWidget {
  final IconData icon;

  const PreviewIconBadge({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }
}

class PreviewMiniPill extends StatelessWidget {
  final String label;

  const PreviewMiniPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ScanSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ScanSettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppPalette.primarySoftFor(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppPalette.primaryFor(context)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

class ScanInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  const ScanInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }
}

enum AnalysisStepState { pending, active, complete }

class ScanProcessingHero extends StatefulWidget {
  final double progress;

  const ScanProcessingHero({super.key, required this.progress});

  @override
  State<ScanProcessingHero> createState() => _ScanProcessingHeroState();
}

class _ScanProcessingHeroState extends State<ScanProcessingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppPalette.primaryFor(context);
    final soft = AppPalette.primarySoftFor(context);
    final progressPercent = (widget.progress.clamp(0.0, 1.0) * 100).round();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.96 + (math.sin(_controller.value * math.pi * 2) * 0.04);
        final scanOffset = 34 + (_controller.value * 102);

        return Center(
          child: SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primary.withValues(alpha: 0.16),
                        AppPalette.aqua.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _controller.value * math.pi * 2,
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                      backgroundColor: soft,
                    ),
                  ),
                ),
                Positioned(
                  top: scanOffset,
                  left: 46,
                  right: 46,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          primary.withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.surfaceFor(context),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.24),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.center_focus_strong_rounded,
                          color: primary,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$progressPercent%',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnalysisStepTile extends StatelessWidget {
  final String label;
  final AnalysisStepState state;

  const AnalysisStepTile({super.key, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      AnalysisStepState.pending => AppPalette.line,
      AnalysisStepState.active => AppPalette.primary,
      AnalysisStepState.complete => AppPalette.success,
    };
    final icon = switch (state) {
      AnalysisStepState.pending => Icons.more_horiz_rounded,
      AnalysisStepState.active => Icons.timelapse_rounded,
      AnalysisStepState.complete => Icons.check_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: state == AnalysisStepState.pending ? 0.28 : 0.12,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RiskMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const RiskMetricChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppPalette.primary),
          ),
        ],
      ),
    );
  }
}

class SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  const SummaryStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppPalette.ink),
          ),
        ],
      ),
    );
  }
}

class HistoryEntryTile extends StatelessWidget {
  final ScanRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const HistoryEntryTile({
    super.key,
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColorForValue(record.status);
    final reminderColor = record.isFollowUpReminderDue
        ? AppPalette.danger
        : AppPalette.warning;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.primarySoft : AppPalette.canvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppPalette.primary : AppPalette.line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.patientName} - ${_formatDateLabel(record.capturedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record.bodyArea} - ${record.location}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (record.hasFollowUpReminder) ...[
              Tooltip(
                message: record.isFollowUpReminderDue
                    ? 'Follow-up due now'
                    : 'Follow-up reminder set',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: reminderColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: reminderColor.withValues(alpha: 0.36),
                    ),
                  ),
                  child: Icon(
                    Icons.priority_high_rounded,
                    color: reminderColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                record.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SnapshotPreviewCard extends StatelessWidget {
  final String title;
  final String caption;
  final Color tint;

  const SnapshotPreviewCard({
    super.key,
    required this.title,
    required this.caption,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 132,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: 0.22),
                  tint.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 86,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: tint.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class LearnSectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const LearnSectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: isSelected
            ? AppPalette.primaryFor(context)
            : AppPalette.inkFor(context),
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppPalette.primarySoftFor(context),
      backgroundColor: AppPalette.surfaceFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected
              ? AppPalette.primaryFor(context)
              : AppPalette.lineFor(context),
        ),
      ),
    );
  }
}

class AbcdeTopic {
  final String letter;
  final String title;
  final String description;
  final Color tint;

  const AbcdeTopic({
    required this.letter,
    required this.title,
    required this.description,
    required this.tint,
  });
}

const List<AbcdeTopic> kAbcdeTopics = [
  AbcdeTopic(
    letter: 'A',
    title: 'Asymmetry',
    description:
        'One half of the spot does not look like the other half when you compare its overall shape.',
    tint: AppPalette.primary,
  ),
  AbcdeTopic(
    letter: 'B',
    title: 'Border',
    description:
        'Edges look irregular, blurred, or uneven instead of smooth and clearly defined.',
    tint: AppPalette.warning,
  ),
  AbcdeTopic(
    letter: 'C',
    title: 'Color',
    description:
        'More than one color may appear in the same lesion, including darker or patchy areas.',
    tint: AppPalette.aqua,
  ),
  AbcdeTopic(
    letter: 'D',
    title: 'Diameter',
    description:
        'Larger spots deserve attention, especially when size keeps increasing over time.',
    tint: AppPalette.success,
  ),
  AbcdeTopic(
    letter: 'E',
    title: 'Evolution',
    description:
        'Any visible change in size, shape, color, or symptoms can be the most important sign to monitor.',
    tint: AppPalette.primary,
  ),
];

class EducationTopicCard extends StatelessWidget {
  final AbcdeTopic topic;

  const EducationTopicCard({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: topic.tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                topic.letter,
                style: TextStyle(
                  color: topic.tint,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  topic.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MelanomaStageInfo {
  final String stage;
  final String title;
  final String description;
  final String clinicalFocus;
  final String patientTakeaway;
  final IconData icon;
  final Color tint;

  const MelanomaStageInfo({
    required this.stage,
    required this.title,
    required this.description,
    required this.clinicalFocus,
    required this.patientTakeaway,
    required this.icon,
    required this.tint,
  });
}

const List<MelanomaStageInfo> kMelanomaStages = [
  MelanomaStageInfo(
    stage: 'Stage 0',
    title: 'In situ',
    description:
        'Abnormal melanocytes are limited to the outermost skin layer.',
    clinicalFocus: 'No deeper skin invasion is identified.',
    patientTakeaway: 'Early clinical treatment is usually highly effective.',
    icon: Icons.layers_clear_outlined,
    tint: AppPalette.success,
  ),
  MelanomaStageInfo(
    stage: 'Stage 1',
    title: 'Early localized',
    description:
        'The melanoma is still localized in the skin and is usually thinner.',
    clinicalFocus: 'Doctors consider thickness and ulceration.',
    patientTakeaway: 'Professional assessment should not be delayed.',
    icon: Icons.center_focus_strong_outlined,
    tint: AppPalette.aqua,
  ),
  MelanomaStageInfo(
    stage: 'Stage 2',
    title: 'Higher local risk',
    description:
        'The melanoma is still mainly local, but can be thicker or have riskier features.',
    clinicalFocus: 'Sentinel lymph node assessment may be discussed.',
    patientTakeaway: 'Timely dermatologist review becomes more important.',
    icon: Icons.priority_high_rounded,
    tint: AppPalette.warning,
  ),
  MelanomaStageInfo(
    stage: 'Stage 3',
    title: 'Regional spread',
    description:
        'Melanoma may involve nearby lymph nodes, lymph vessels, or nearby skin/tissue.',
    clinicalFocus: 'Specialists assess regional lymph node involvement.',
    patientTakeaway: 'This needs coordinated specialist care.',
    icon: Icons.hub_outlined,
    tint: AppPalette.warning,
  ),
  MelanomaStageInfo(
    stage: 'Stage 4',
    title: 'Advanced spread',
    description:
        'Melanoma has spread to distant organs or distant parts of the body.',
    clinicalFocus:
        'Imaging and specialist oncology planning are usually needed.',
    patientTakeaway: 'Urgent specialist management is required.',
    icon: Icons.emergency_outlined,
    tint: AppPalette.danger,
  ),
];

class MelanomaStagesEducationContent extends StatelessWidget {
  const MelanomaStagesEducationContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppPalette.primaryFor(
                        context,
                      ).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.stacked_line_chart_rounded,
                      color: AppPalette.primaryFor(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Melanoma stages',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stages describe how far melanoma has grown or spread. SkinSafe does not assign a cancer stage; only a clinician can do that after examination and medical tests.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What doctors look at',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              const StatusLine(
                icon: Icons.straighten_rounded,
                title: 'Tumor thickness',
                value:
                    'How deeply the melanoma has grown into the skin is an important staging factor.',
                tint: AppPalette.primary,
              ),
              SizedBox(height: 12),
              const StatusLine(
                icon: Icons.healing_outlined,
                title: 'Ulceration',
                value:
                    'Doctors check whether the surface skin over the melanoma is broken.',
                tint: AppPalette.warning,
              ),
              SizedBox(height: 12),
              const StatusLine(
                icon: Icons.account_tree_outlined,
                title: 'Lymph nodes',
                value:
                    'Nearby lymph node involvement can move melanoma into a regional stage.',
                tint: AppPalette.aqua,
              ),
              SizedBox(height: 12),
              const StatusLine(
                icon: Icons.travel_explore_outlined,
                title: 'Distant spread',
                value:
                    'Doctors may use tests to check whether melanoma has spread to distant organs.',
                tint: AppPalette.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stage overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < kMelanomaStages.length; i++) ...[
                MelanomaStageCard(stage: kMelanomaStages[i]),
                if (i != kMelanomaStages.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use this in the app',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Use this page to understand medical language before or after a doctor visit. AI scan results should be treated as screening support, not as staging or diagnosis.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MelanomaStageCard extends StatelessWidget {
  final MelanomaStageInfo stage;

  const MelanomaStageCard({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stage.tint.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: stage.tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(stage.icon, color: stage.tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stage.tint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stage.stage,
                        style: TextStyle(
                          color: stage.tint,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stage.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stage.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stage.tint.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical focus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: stage.tint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.clinicalFocus,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Patient takeaway',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: stage.tint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.patientTakeaway,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeaturePlaceholderCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> bullets;

  const FeaturePlaceholderCard({
    super.key,
    required this.title,
    required this.description,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 18),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: const BoxDecoration(
                      color: AppPalette.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(bullet, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const MiniFeatureChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.primarySoftFor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppPalette.primaryFor(context), size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppPalette.primaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class UserAvatarBadge extends StatelessWidget {
  final String initials;

  const UserAvatarBadge({super.key, required this.initials});

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppPalette.darkSurfaceHigh, AppPalette.darkSurface]
              : const [AppPalette.blushSoft, AppPalette.cream],
        ),
        border: Border.all(
          color: isDark ? AppPalette.darkLine : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.shadowFor(context),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppPalette.inkFor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class CompactBrand extends StatelessWidget {
  const CompactBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(size: 40),
        const SizedBox(width: 10),
        Text(
          'SkinSafe',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: 22, letterSpacing: -0.7),
        ),
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.isDark(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.82),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.shadowFor(context),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Container(
            width: size * 0.64,
            height: size * 0.64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? const Color(0xFF092D35) : AppPalette.ink,
                  AppPalette.primaryFor(context),
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.22),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.primaryFor(context).withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.medical_services_outlined,
              color: Colors.white,
              size: size * 0.30,
            ),
          ),
        ],
      ),
    );
  }
}

String _authMessageFor(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'invalid-credential':
    case 'user-not-found':
    case 'wrong-password':
      return 'Your email or password is incorrect.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'email-already-in-use':
      return 'An account already exists with this email address.';
    case 'weak-password':
      return 'Use a stronger password with at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts right now. Please wait and try again.';
    case 'network-request-failed':
      return 'Network issue detected. Check your internet and try again.';
    default:
      return error.message ?? 'Authentication failed. Please try again.';
  }
}

String _passwordResetMessageFor(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return 'Enter a valid email address to reset your password.';
    case 'missing-email':
      return 'Enter your email address first.';
    case 'network-request-failed':
      return 'Network issue detected. Check your internet and try again.';
    default:
      return error.message ??
          'We could not send the password reset email right now.';
  }
}

String _nameFromEmail(String email) {
  final localPart = email.trim().split('@').first;
  if (localPart.isEmpty) {
    return 'SkinSafe User';
  }

  final words = localPart
      .split(RegExp(r'[._-]+'))
      .where((part) => part.isNotEmpty)
      .map(_capitalize)
      .toList();

  return words.isEmpty ? 'SkinSafe User' : words.join(' ');
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

String _formatDateLabel(DateTime value) {
  const monthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = monthLabels[value.month - 1];
  final day = value.day.toString().padLeft(2, '0');
  return '$month $day, ${value.year}';
}

Color _statusColorForValue(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('high') ||
      normalized.contains('specialist') ||
      normalized.contains('urgent')) {
    return AppPalette.danger;
  }
  if (normalized.contains('unavailable') || normalized.contains('error')) {
    return AppPalette.warning;
  }
  if (normalized.contains('caution')) {
    return AppPalette.warning;
  }
  if (normalized.contains('monitor') || normalized.contains('watch')) {
    return AppPalette.primary;
  }
  if (normalized.contains('stable') || normalized.contains('low')) {
    return AppPalette.success;
  }
  return AppPalette.aqua;
}

void _showMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isError ? AppPalette.danger : AppPalette.primary,
    ),
  );
}

PageRouteBuilder<void> _buildRoute(Widget child) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
