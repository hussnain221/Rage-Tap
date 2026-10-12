import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class SaveService {
  SaveService._();
  static final SaveService instance = SaveService._();

  static const String keySchemaVersion = 'schema_version';
  static const String keyBestScore = 'best_score';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticsEnabled = 'haptics_enabled';
  static const String keyFirstRunDone = 'first_run_done';
  static const String keyTotalRuns = 'total_runs';

  SharedPreferences? _prefs;

  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    if (!_prefs!.containsKey(keySchemaVersion)) {
      await _prefs!.setInt(keySchemaVersion, 1);
    }
  }

  int get schemaVersion {
    final val = _prefs?.get(keySchemaVersion);
    if (val is int && val >= 1) return val;
    return 1;
  }

  int get bestScore {
    final val = _prefs?.get(keyBestScore);
    if (val is int) {
      return val.clamp(0, C.maxScore);
    }
    return 0;
  }

  Future<bool> setBestIfHigher(int score) async {
    final clamped = score.clamp(0, C.maxScore);
    if (clamped > bestScore) {
      if (_prefs != null) {
        await _prefs!.setInt(keyBestScore, clamped);
      }
      return true;
    }
    return false;
  }

  bool get soundEnabled {
    final val = _prefs?.get(keySoundEnabled);
    if (val is bool) return val;
    return true;
  }

  set soundEnabled(bool value) {
    _prefs?.setBool(keySoundEnabled, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(keySoundEnabled, value);
    }
  }

  bool get hapticsEnabled {
    final val = _prefs?.get(keyHapticsEnabled);
    if (val is bool) return val;
    return true;
  }

  set hapticsEnabled(bool value) {
    _prefs?.setBool(keyHapticsEnabled, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(keyHapticsEnabled, value);
    }
  }

  bool get firstRunDone {
    final val = _prefs?.get(keyFirstRunDone);
    if (val is bool) return val;
    return false;
  }

  set firstRunDone(bool value) {
    _prefs?.setBool(keyFirstRunDone, value);
  }

  Future<void> setFirstRunDone(bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(keyFirstRunDone, value);
    }
  }

  int get totalRuns {
    final val = _prefs?.get(keyTotalRuns);
    if (val is int) {
      return val < 0 ? 0 : val;
    }
    return 0;
  }

  Future<void> incrementTotalRuns() async {
    final next = totalRuns + 1;
    if (_prefs != null) {
      await _prefs!.setInt(keyTotalRuns, next);
    }
  }

  Future<void> resetProgress() async {
    if (_prefs != null) {
      await _prefs!.setInt(keyBestScore, 0);
      await _prefs!.setInt(keyTotalRuns, 0);
    }
  }
}
