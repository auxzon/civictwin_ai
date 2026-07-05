import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'voice_input_service.dart';

final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  return VoiceInputService();
});
