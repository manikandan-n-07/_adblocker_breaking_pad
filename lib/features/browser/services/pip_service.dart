import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Handles Picture-in-Picture and background media playback.
/// Communicates with the native Android MainActivity via MethodChannel.
class PiPService {
  static final PiPService instance = PiPService._();
  PiPService._();

  static const MethodChannel _channel = MethodChannel('com.example.browser/pip');

  bool _isInPiP = false;
  bool _isPiPSupported = false;
  bool _mediaPlaying = false;

  /// Whether the app is currently in PiP mode
  bool get isInPiP => _isInPiP;

  /// Whether PiP is supported on this device (Android 8+)
  bool get isPiPSupported => _isPiPSupported;

  /// Track if media is currently playing (set by the browser screen)
  bool get mediaPlaying => _mediaPlaying;

  void setMediaPlaying(bool playing) {
    _mediaPlaying = playing;
  }

  /// Initialize the service and register method call handler
  Future<void> init() async {
    try {
      _isPiPSupported = await _channel.invokeMethod<bool>('isPiPSupported') ?? false;
    } catch (_) {
      _isPiPSupported = false;
    }

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onUserLeaveHint':
          // User pressed Home — enter PiP if media is playing
          if (_mediaPlaying && _isPiPSupported) {
            await enterPiP();
          }
          break;
        case 'onPiPModeChanged':
          _isInPiP = call.arguments as bool? ?? false;
          if (onPiPChanged != null) onPiPChanged!(_isInPiP);
          break;
      }
    });
  }

  /// Callback invoked when PiP state changes
  void Function(bool isInPiP)? onPiPChanged;

  /// Manually enter PiP mode
  Future<bool> enterPiP() async {
    try {
      final result = await _channel.invokeMethod<bool>('enterPiP');
      return result ?? false;
    } catch (e) {
      debugPrint('PiP enterPiP error: $e');
      return false;
    }
  }
}
