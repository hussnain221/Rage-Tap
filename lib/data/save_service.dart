import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class SaveService {
  SaveService._();
  static final SaveService instance = SaveService._();

  static const int currentSchemaVersion = 2;
  static const String keySchemaVersion = 'schema_version';
  static const String keyBestScore = 'best_score';
  static const String keyTotalCoins = 'total_coins';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticsEnabled = 'haptics_enabled';
  static const String keyFirstRunDone = 'first_run_done';
  static const String keyTotalRuns = 'total_runs';
  static const String keyBeamHintShown = 'beam_hint_shown';
  static const String keyPitHintShown = 'pit_hint_shown';

  SharedPreferences? _prefs;
  final ValueNotifier<int> bestScoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> totalCoinsNotifier = ValueNotifier<int>(0);

  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    final currentVer = _prefs!.getInt(keySchemaVersion) ?? 0;

    // Schema v1 migration
    if (currentVer < 1) {
      await _prefs!.setInt(keySchemaVersion, 1);
    }

    // Schema v2 migration: add total_coins (§20.2)
    if (currentVer < 2) {
      if (!_prefs!.containsKey(keyTotalCoins)) {
        await _prefs!.setInt(keyTotalCoins, 0);
      }
      await _prefs!.setInt(keySchemaVersion, 2);
    }

    bestScoreNotifier.value = bestScore;
    totalCoinsNotifier.value = totalCoins;
  }

  int get schemaVersion {
    final val = _prefs?.get(keySchemaVersion);
    if (val is int && val >= 1) return val;
    return currentSchemaVersion;
  }

  int get totalCoins {
    final val = _prefs?.get(keyTotalCoins);
    if (val is int) {
      return val < 0 ? 0 : val;
    }
    return 0;
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    final next = totalCoins + amount;
    totalCoinsNotifier.value = next;
    if (_prefs != null) {
      await _prefs!.setInt(keyTotalCoins, next);
    }
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
      bestScoreNotifier.value = clamped;
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

  bool get beamHintShown {
    final val = _prefs?.get(keyBeamHintShown);
    if (val is bool) return val;
    return false;
  }

  set beamHintShown(bool value) {
    _prefs?.setBool(keyBeamHintShown, value);
  }

  Future<void> setBeamHintShown(bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(keyBeamHintShown, value);
    }
  }

  bool get pitHintShown {
    final val = _prefs?.get(keyPitHintShown);
    if (val is bool) return val;
    return false;
  }

  set pitHintShown(bool value) {
    _prefs?.setBool(keyPitHintShown, value);
  }

  Future<void> setPitHintShown(bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(keyPitHintShown, value);
    }
  }

  Future<void> resetProgress() async {
    if (_prefs != null) {
      await _prefs!.setInt(keyBestScore, 0);
      await _prefs!.setInt(keyTotalRuns, 0);
      await _prefs!.setInt(keyTotalCoins, 0);
    }
    bestScoreNotifier.value = 0;
    totalCoinsNotifier.value = 0;
  }
}
