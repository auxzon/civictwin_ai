import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/design_system.dart';
import 'core/widgets/civictwin_error_state.dart';
import 'core/widgets/civictwin_spinner.dart';
import 'features/authentication/auth_provider.dart';
import 'features/authentication/sign_in_screen.dart';
import 'features/map/map_screen.dart';

class CivicTwinApp extends ConsumerWidget {
  const CivicTwinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CivicTwin AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AuthGate(),
    );
  }
}

/// Shows [SignInScreen] until a user is authenticated, then [MapScreen].
/// Loading and error states use design-system components for visual consistency.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user == null ? const SignInScreen() : const MapScreen(),
      loading: () => const Scaffold(
        backgroundColor: AppDesignSystem.brandObsidianBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CivicTwinSpinner(size: 40),
              AppDesignSystem.height16,
              Text(
                'Initializing CivicTwin AI...',
                style: AppDesignSystem.body,
              ),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppDesignSystem.brandObsidianBg,
        body: CivicTwinErrorState(
          errorText: 'Authentication error: $error',
        ),
      ),
    );
  }
}
