import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wake_audio.dart';

final bhaktiWakeProvider = ChangeNotifierProvider(
  (ref) => BhaktiWakeController(WakeAudio()),
);

class BhaktiWakeController extends ChangeNotifier {
  BhaktiWakeController(this._audio);

  static const _key = 'bhakti_foreground_wake_enabled';
  final WakeAudio _audio;
  Future<void> _pending = Future.value();
  bool enabled = false;
  bool changing = false;
  bool _foreground = false;
  bool _modal = false;
  bool _active = false;
  bool _closed = false;
  Timer? _retry;
  VoidCallback? onWake;
  bool get _wanted =>
      enabled && _foreground && !_modal && !_closed && onWake != null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (_closed || changing) return;
    enabled = prefs.getBool(_key) ?? false;
    notifyListeners();
    await _sync();
  }

  Future<bool> setEnabled(bool value) async {
    if (changing) return false;
    changing = true;
    notifyListeners();
    try {
      if (value && !await _audio.permission(request: true)) {
        await _audio.stop();
        return false;
      }
      enabled = value;
      await _sync();
      if (value && _wanted && !_active) enabled = false;
      await (await SharedPreferences.getInstance()).setBool(_key, enabled);
      return enabled == value;
    } catch (_) {
      return false;
    } finally {
      changing = false;
      if (!_closed) notifyListeners();
    }
  }

  void foreground(bool value) {
    _foreground = value;
    unawaited(_sync());
  }

  Future<void> setModal(bool open) {
    _modal = open;
    return _sync();
  }

  Future<void> _sync() {
    _retry?.cancel();
    return _pending = _pending
        .then((_) async {
          if (!_wanted) {
            if (_active) {
              _active = false;
              await _audio.stop();
            }
            return;
          }
          if (_active || !await _audio.permission(request: false) || !_wanted) {
            return;
          }
          _active = true;
          try {
            await _audio.start(() {
              if (_active && _wanted) onWake?.call();
            }, _interrupted);
          } catch (_) {
            _active = false;
            await _audio.stop();
          }
        })
        .catchError((Object e) {
          debugPrint('Bhakti wake listener unavailable: $e');
        });
  }

  void _interrupted() {
    if (!_active || !_wanted || _retry?.isActive == true) return;
    _pending = _pending
        .then((_) async {
          if (!_active) return;
          _active = false;
          await _audio.stop();
        })
        .whenComplete(() {
          if (_wanted) _retry = Timer(const Duration(seconds: 2), _sync);
        })
        .catchError(
          (Object e) => debugPrint('Bhakti microphone interrupted: $e'),
        );
  }

  @override
  void dispose() {
    _closed = true;
    onWake = null;
    unawaited(_sync());
    super.dispose();
  }
}
