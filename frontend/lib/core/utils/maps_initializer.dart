import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Dynamically injects the Google Maps JavaScript SDK script tag into the DOM head.
///
/// Reads the API key from compile-time defines (`MAPS_API_KEY`) or falls back to
/// an empty string. This keeps the API key out of source control.
void initializeGoogleMaps() {
  if (!kIsWeb) return;

  const apiKey = String.fromEnvironment('MAPS_API_KEY');
  if (apiKey.isEmpty) {
    debugPrint(
      'Warning: MAPS_API_KEY was not supplied via --dart-define. '
      'Google Maps JavaScript SDK will not be dynamically loaded.',
    );
    return;
  }

  final head = web.document.head;
  if (head == null) return;

  // Check if any script matches maps.googleapis.com to prevent duplicate injection
  final scripts = web.document.getElementsByTagName('script');
  for (int i = 0; i < scripts.length; i++) {
    final script = scripts.item(i) as web.HTMLScriptElement?;
    if (script != null && script.src.contains('maps.googleapis.com')) {
      return; // Already injected
    }
  }

  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script.src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey';
  script.async = true;
  head.appendChild(script);
}
