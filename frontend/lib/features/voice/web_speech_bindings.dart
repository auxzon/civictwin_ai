// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:async';
import 'dart:js_util' as js_util;

/// Minimal JS interop wrapper around the browser's SpeechRecognition API
/// (`window.SpeechRecognition` or vendor-prefixed
/// `window.webkitSpeechRecognition`), using `dart:js_util` rather than
/// `dart:js_interop` extension types.
///
/// Rationale: `SpeechRecognitionResultList`/`SpeechRecognitionResult` are
/// array-*like* JS objects, not real JS Arrays or a shape that maps
/// cleanly onto typed `dart:js_interop` extension types without more
/// scaffolding than this feature warrants. `js_util`'s dynamic
/// `getProperty`/`callMethod` is a simpler, long-supported way to walk
/// that structure correctly.
///
/// IMPORTANT: this file has not been exercised in a real browser during
/// development (no Flutter/Dart toolchain available in this environment).
/// Treat it as the first thing to manually smoke-test — open the app in
/// Chrome, trigger the mic button, and confirm a transcript comes back —
/// before relying on it for a live demo. Safari's Web Speech API support
/// is notably incomplete; this is a Chrome/Edge-first feature by nature
/// of the underlying browser API, not a bug in this binding.
class WebSpeechRecognizer {
  Object? _recognition;

  /// True if the browser exposes either the standard or webkit-prefixed
  /// SpeechRecognition constructor on `window`.
  bool get isSupported {
    final window = js_util.globalThis;
    return js_util.hasProperty(window, 'SpeechRecognition') ||
        js_util.hasProperty(window, 'webkitSpeechRecognition');
  }

  /// Starts listening and resolves with the final transcript once the
  /// browser reports a result, or throws if unsupported / on error.
  Future<String> listenOnce({String lang = 'en-IN'}) {
    if (!isSupported) {
      throw StateError('Web Speech API is not supported in this browser.');
    }

    final completer = Completer<String>();
    final window = js_util.globalThis;

    final ctorName = js_util.hasProperty(window, 'SpeechRecognition')
        ? 'SpeechRecognition'
        : 'webkitSpeechRecognition';
    final recognition = js_util.callConstructor(
      js_util.getProperty(window, ctorName) as Object,
      const <Object?>[],
    );
    _recognition = recognition;

    js_util.setProperty(recognition, 'continuous', false);
    js_util.setProperty(recognition, 'interimResults', false);
    js_util.setProperty(recognition, 'lang', lang);

    js_util.setProperty(
      recognition,
      'onresult',
      js_util.allowInterop((Object event) {
        final transcript = _extractTranscript(event);
        if (!completer.isCompleted) {
          completer.complete(transcript);
        }
      }),
    );

    js_util.setProperty(
      recognition,
      'onerror',
      js_util.allowInterop((Object event) {
        if (!completer.isCompleted) {
          final message = js_util.getProperty(event, 'error') as String?;
          completer.completeError(
            StateError('Speech recognition error: ${message ?? 'unknown'}'),
          );
        }
      }),
    );

    js_util.callMethod(recognition, 'start', const <Object?>[]);

    return completer.future;
  }

  String _extractTranscript(Object event) {
    final results = js_util.getProperty(event, 'results');
    final firstResult = js_util.callMethod(results, 'item', [0]);
    final firstAlternative = js_util.callMethod(firstResult, 'item', [0]);
    return js_util.getProperty(firstAlternative, 'transcript') as String;
  }

  void stop() {
    final recognition = _recognition;
    if (recognition != null) {
      js_util.callMethod(recognition, 'stop', const <Object?>[]);
    }
  }
}
