import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/design_system.dart';
import '../../core/widgets/civictwin_button.dart';
import '../../core/widgets/civictwin_empty_state.dart';
import '../../core/widgets/civictwin_error_state.dart';
import '../../core/widgets/civictwin_glass_panel.dart';

import '../../core/widgets/civictwin_spinner.dart';
import '../../core/widgets/civictwin_status_chip.dart';
import '../authentication/auth_provider.dart';
import '../history/history_provider.dart';
import '../history/models/mission_history_item.dart';
import '../mission/mission_provider.dart';
import '../mission/models/mission_models.dart';
import '../timeline/timeline_slider.dart';
import '../voice/voice_provider.dart';
import 'providers/map_state_notifier.dart';

/// The constituency this MVP build is wired to. Hardcoding a single
/// constituency ID is a deliberate scope decision for this phase — a
/// constituency picker is a natural next feature, not implemented here
/// per the "no invented UI" instruction.
const String _kDefaultConstituencyId = 'const_mumbai_north';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _isCapturingVoice = false;
  String? _selectedWardId;
  MissionBrief? _selectedBrief;
  bool _isHistoryOpen = false;

  final Map<String, BitmapDescriptor> _customMarkers = {};
  String? _selectedMarkerId;

  late final AnimationController _entryController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initCustomMarkers();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 1.03, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _entryController.forward();
  }

  Future<void> _initCustomMarkers() async {
    final colors = {
      'critical': const Color(0xFFFF1744),
      'high': const Color(0xFFFF9100),
      'medium': const Color(0xFF00E5FF),
      'low': const Color(0xFF29B6F6),
      'completed': const Color(0xFF00E676),
    };

    for (final entry in colors.entries) {
      _customMarkers['${entry.key}_normal'] = await _drawCustomMarker(entry.value, isSelected: false);
      _customMarkers['${entry.key}_selected'] = await _drawCustomMarker(entry.value, isSelected: true);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _drawCustomMarker(Color color, {required bool isSelected}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double size = isSelected ? 64.0 : 40.0;
    final double radius = size / 2.0;

    // Draw shadow/outer glow
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: isSelected ? 0.45 : 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(radius, radius), radius - 2, glowPaint);

    // Draw white outer ring
    final Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: isSelected ? 0.95 : 0.7)
      ..strokeWidth = isSelected ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(radius, radius), radius - 6, borderPaint);

    // Draw central solid node
    final Paint nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius - (isSelected ? 11 : 9), nodePaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.bytes(bytes);
  }

  String? _getWardIdForBrief(MissionBrief brief) {
    if (brief.evidence.isNotEmpty) {
      final firstSig = brief.evidence.first;
      final parts = firstSig.split('_');
      if (parts.length >= 2) {
        return 'ward_${parts[1]}';
      }
    }
    if (brief.missionId.contains('ward_')) {
      final match = RegExp(r'ward_\d+').firstMatch(brief.missionId);
      if (match != null) return match.group(0);
    }
    return null;
  }

  LatLng _getWardCenter(String wardId) {
    switch (wardId) {
      case 'ward_14':
        return const LatLng(19.202, 72.825);
      case 'ward_17':
        return const LatLng(19.222, 72.845);
      case 'ward_09':
        return const LatLng(19.248, 72.859);
      case 'ward_22':
        return const LatLng(19.186, 72.831);
      case 'ward_05':
        return const LatLng(19.215, 72.812);
      default:
        return const LatLng(19.183, 72.848);
    }
  }

  void _onBriefSelected(MissionBrief brief) {
    final wardId = _getWardIdForBrief(brief);
    setState(() {
      _selectedBrief = brief;
      _selectedWardId = wardId;
    });

    if (wardId != null) {
      final center = _getWardCenter(wardId);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 14.5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _handleMicPressed() async {
    if (_isCapturingVoice) return;
    setState(() => _isCapturingVoice = true);

    ref
        .read(appUIStateProvider.notifier)
        .updateState(OperationalState.listening);

    try {
      final voiceService = ref.read(voiceInputServiceProvider);
      final command = await voiceService.captureCommand();

      final controller = _mapController;
      final bounds = controller != null
          ? await controller.getVisibleRegion()
          : LatLngBounds(
              southwest: const LatLng(19.0760, 72.8300),
              northeast: const LatLng(19.1900, 72.8700),
            );

      await ref
          .read(missionControllerProvider.notifier)
          .submitCommand(
            constituencyId: _kDefaultConstituencyId,
            command: command,
            currentMapBounds: bounds,
          );
    } finally {
      if (mounted) setState(() => _isCapturingVoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(appUIStateProvider);
    final missionState = ref.watch(missionControllerProvider);

    ref.listen<AsyncValue<List<MissionHistoryItem>>>(
      missionHistoryProvider(_kDefaultConstituencyId),
      (previous, next) {
        next.whenData((items) {
          if (items.isNotEmpty && ref.read(missionControllerProvider).response == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ref.read(missionControllerProvider).response == null) {
                ref.read(missionControllerProvider.notifier).setMissionResponse(items.first.selectedPlan);
              }
            });
          }
        });
      },
    );

    final response = missionState.response;
    if (response != null && _selectedBrief == null && response.briefs.isNotEmpty) {
      final firstBrief = response.briefs.first;
      final wardId = _getWardIdForBrief(firstBrief);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedBrief == null) {
          setState(() {
            _selectedBrief = firstBrief;
            _selectedWardId = wardId;
          });
        }
      });
    }

    ref.listen(mapLayersProvider(_kDefaultConstituencyId), (previous, next) {
      next.whenData((data) {
        final markers = data.signals.map((s) {
          final coords = s['coords'];
          return Marker(
            markerId: MarkerId(s['id'] as String),
            position: LatLng(
              (coords['latitude'] as num).toDouble(),
              (coords['longitude'] as num).toDouble(),
            ),
            infoWindow: InfoWindow(
              title: s['category'] as String,
              snippet: s['description'] as String,
            ),
          );
        }).toList();

        final polygons = data.wards.map((w) {
          final coordsList = w['polygon_coordinates'] as List<dynamic>;
          final points = coordsList.map((p) {
            return LatLng(
              (p['latitude'] as num).toDouble(),
              (p['longitude'] as num).toDouble(),
            );
          }).toList();

          return Polygon(
            polygonId: PolygonId(w['id'] as String),
            points: points,
            strokeWidth: 2,
            strokeColor: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.3),
            fillColor: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.08),
          );
        }).toList();

        ref.read(appUIStateProvider.notifier).loadSignals(markers);
        ref.read(appUIStateProvider.notifier).loadWards(polygons);
      });
    });

    ref.listen(missionControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppDesignSystem.brandMetallicSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppDesignSystem.borderRadii8,
            side: BorderSide(
              color: AppDesignSystem.semanticError.withValues(alpha: 0.3),
            ),
          ),
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppDesignSystem.semanticError,
                size: AppDesignSystem.iconSizeMedium,
              ),
              AppDesignSystem.width12,
              Expanded(
                child: Text(
                  next.errorMessage!,
                  style: AppDesignSystem.body.copyWith(
                    color: AppDesignSystem.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ));
      }

      if (next.response != null && next.response != previous?.response) {
        final briefs = next.response!.briefs;
        if (briefs.isNotEmpty) {
          final firstBrief = briefs.first;
          LatLng targetCenter = const LatLng(19.183, 72.848);
          if (firstBrief.mission.contains('Kandivali')) {
            targetCenter = const LatLng(19.202, 72.825);
          } else if (firstBrief.mission.contains('Borivali')) {
            targetCenter = const LatLng(19.222, 72.845);
          }

          final controller = _mapController;
          if (controller != null) {
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: targetCenter, zoom: 14.5),
              ),
            ).then((_) {
              ref.read(appUIStateProvider.notifier).updateState(OperationalState.planLoaded);
            });
          } else {
            ref.read(appUIStateProvider.notifier).updateState(OperationalState.planLoaded);
          }
        }
      }
    });

    final mapLayersAsync = ref.watch(mapLayersProvider(_kDefaultConstituencyId));
    final rawSignals = mapLayersAsync.maybeWhen(
      data: (data) => data.signals,
      orElse: () => <dynamic>[],
    );

    final Set<Marker> enrichedMarkers = uiState.signalMarkers.map((m) {
      final signalId = m.markerId.value;
      final signal = rawSignals.firstWhere(
        (s) => s['id'] == signalId,
        orElse: () => null,
      );
      if (signal == null) return m;

      final status = signal['status'] as String;
      final severity = signal['severity'] as int;

      String severityKey = 'low';
      if (status.toLowerCase() == 'closed' || status.toLowerCase() == 'completed') {
        severityKey = 'completed';
      } else if (severity >= 9) {
        severityKey = 'critical';
      } else if (severity >= 7) {
        severityKey = 'high';
      } else if (severity >= 5) {
        severityKey = 'medium';
      }

      final isSelected = signalId == _selectedMarkerId;
      final iconKey = '${severityKey}_${isSelected ? "selected" : "normal"}';
      final icon = _customMarkers[iconKey] ?? BitmapDescriptor.defaultMarker;

      return m.copyWith(
        iconParam: icon,
        onTapParam: () {
          setState(() {
            _selectedMarkerId = signalId;
          });
          final coords = signal['coords'];
          final latLng = LatLng(
            (coords['latitude'] as num).toDouble(),
            (coords['longitude'] as num).toDouble(),
          );
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: latLng, zoom: 15.0),
            ),
          );
        },
      );
    }).toSet();

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppDesignSystem.brandObsidianBg,
        body: Column(
          children: [
          // ─── Premium Top Navigation Bar ───
          _PremiumTopNav(
            onLogout: () async {
              await ref.read(authServiceProvider).signOut();
            },
            onHistoryTap: () {
              ref.invalidate(
                missionHistoryProvider(_kDefaultConstituencyId),
              );
              setState(() => _isHistoryOpen = !_isHistoryOpen);
            },
            isHistoryOpen: _isHistoryOpen,
          ),

          // ─── Main Content Area ───
          Expanded(
            child: Row(
              children: [
                // ─── Left Analytics Sidebar ───
                _PremiumSidebar(
                  uiState: uiState,
                  response: missionState.response,
                  isCapturingVoice: _isCapturingVoice,
                  onMicPressed: _handleMicPressed,
                ),

                // ─── Center: Map + Bottom Panel ───
                Expanded(
                  child: Stack(
                    children: [
                      // Map Canvas
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(AppDesignSystem.space4),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: AppDesignSystem.borderRadii12,
                            border: Border.all(
                              color: AppDesignSystem.brandBorderTranslucent,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: AppDesignSystem.borderRadii12,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: uiState.cameraTarget,
                                zoom: 13,
                              ),
                              markers: enrichedMarkers,
                              polygons: uiState.wardPolygons.map((p) {
                                if (p.polygonId.value == _selectedWardId) {
                                  return p.copyWith(
                                    strokeColorParam: AppDesignSystem.brandNeonCyan,
                                    fillColorParam: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.15),
                                    strokeWidthParam: 3,
                                  );
                                }
                                return p.copyWith(
                                  strokeColorParam: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.25),
                                  fillColorParam: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.04),
                                  strokeWidthParam: 1,
                                );
                              }).toSet(),
                              onMapCreated: (controller) => _mapController = controller,
                            ),
                          ),
                        ),
                      ),

                      // ─── Floating Status Bar (top center) ───
                      Positioned(
                        top: AppDesignSystem.space12,
                        left: AppDesignSystem.space64,
                        right: AppDesignSystem.space64,
                        child: Center(
                          child: CivicTwinGlassPanel(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDesignSystem.space16,
                              vertical: AppDesignSystem.space8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppDesignSystem.semanticSuccess,
                                  ),
                                ),
                                AppDesignSystem.width8,
                                Text(
                                  'Mumbai North Constituency',
                                  style: AppDesignSystem.bodySmall.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                AppDesignSystem.width16,
                                Container(
                                  width: 1,
                                  height: 14,
                                  color: AppDesignSystem.brandBorderTranslucent,
                                ),
                                AppDesignSystem.width16,
                                Text(
                                  '${uiState.wardPolygons.length} Wards',
                                  style: AppDesignSystem.caption.copyWith(
                                    color: AppDesignSystem.brandNeonCyan,
                                  ),
                                ),
                                AppDesignSystem.width12,
                                Text(
                                  '${uiState.signalMarkers.length} Signals',
                                  style: AppDesignSystem.caption.copyWith(
                                    color: AppDesignSystem.brandNeonCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ─── Floating Legend (top right) ───
                      Positioned(
                        top: AppDesignSystem.space12,
                        right: AppDesignSystem.space12,
                        child: const _PremiumMapLegend(),
                      ),

                      // ─── Floating Signal Info Window (top left of map) ───
                      if (_selectedMarkerId != null)
                        Positioned(
                          top: AppDesignSystem.space12,
                          left: AppDesignSystem.space12,
                          child: _PremiumSignalDetailCard(
                            signalId: _selectedMarkerId!,
                            signals: rawSignals,
                            onClose: () => setState(() => _selectedMarkerId = null),
                          ),
                        ),

                      // ─── Bottom Mission Briefs Panel ───
                      if (missionState.response != null)
                        Positioned(
                          left: AppDesignSystem.space12,
                          right: AppDesignSystem.space12,
                          bottom: AppDesignSystem.space12,
                          child: SizedBox(
                            height: 240,
                            child: _PremiumBriefsPanel(
                              response: missionState.response!,
                              selectedBrief: _selectedBrief,
                              onBriefSelected: _onBriefSelected,
                            ),
                          ),
                        ),

                      // ─── Floating Mic Button ───
                      Positioned(
                        right: AppDesignSystem.space16,
                        bottom: missionState.response != null ? 264 : AppDesignSystem.space16,
                        child: _PremiumMicButton(
                          isCapturing: _isCapturingVoice,
                          onPressed: _handleMicPressed,
                        ),
                      ),

                      // ─── Full-Screen AI Overlay ───
                      if (uiState.state == OperationalState.thinking ||
                          uiState.state == OperationalState.listening)
                        _PremiumAIOverlay(state: uiState.state),
                    ],
                  ),
                ),

                // ─── Right History Panel (Animated Slide) ───
                AnimatedContainer(
                  duration: AppDesignSystem.durationMedium,
                  curve: AppDesignSystem.curveStandard,
                  width: _isHistoryOpen ? AppDesignSystem.historyPanelWidth : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: _isHistoryOpen
                      ? _PremiumHistoryPanel(
                          constituencyId: _kDefaultConstituencyId,
                          onClose: () => setState(() => _isHistoryOpen = false),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

// =============================================================================
// PREMIUM TOP NAVIGATION BAR
// =============================================================================
class _PremiumTopNav extends StatelessWidget {
  const _PremiumTopNav({
    required this.onLogout,
    required this.onHistoryTap,
    required this.isHistoryOpen,
  });

  final VoidCallback onLogout;
  final VoidCallback onHistoryTap;
  final bool isHistoryOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDesignSystem.topNavHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.space24),
      decoration: const BoxDecoration(
        color: AppDesignSystem.brandObsidianBg,
        border: Border(
          bottom: BorderSide(
            color: AppDesignSystem.brandBorderTranslucent,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF070809),
              border: Border.all(
                color: AppDesignSystem.brandBorderTranslucent,
                width: 1.2,
              ),
              borderRadius: AppDesignSystem.borderRadii8,
            ),
            padding: const EdgeInsets.all(6),
            child: const CustomPaint(
              painter: _GeometricMonogramPainter(),
            ),
          ),
          AppDesignSystem.width12,
          Text(
            'CIVICTWIN AI',
            style: AppDesignSystem.heading3.copyWith(
              color: AppDesignSystem.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              fontSize: 16,
            ),
          ),
          AppDesignSystem.width8,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.space8,
              vertical: AppDesignSystem.space4,
            ),
            decoration: BoxDecoration(
              color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.1),
              borderRadius: AppDesignSystem.borderRadii4,
              border: Border.all(
                color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'ENTERPRISE',
              style: AppDesignSystem.caption.copyWith(
                color: AppDesignSystem.brandNeonCyan,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const Spacer(),

          // Nav Items
          _NavItem(
            icon: Icons.map_outlined,
            label: 'Map',
            isActive: true,
          ),
          AppDesignSystem.width8,
          _NavItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            isActive: false,
          ),
          AppDesignSystem.width8,
          _NavItem(
            icon: Icons.assessment_outlined,
            label: 'Reports',
            isActive: false,
          ),

          const Spacer(),

          // Actions
          _TopNavIconButton(
            icon: Icons.notifications_none_outlined,
            tooltip: 'Notifications',
            onTap: () {},
          ),
          AppDesignSystem.width4,
          _TopNavIconButton(
            icon: isHistoryOpen ? Icons.close : Icons.history_outlined,
            tooltip: isHistoryOpen ? 'Close History' : 'Planning History',
            onTap: onHistoryTap,
            isActive: isHistoryOpen,
          ),
          AppDesignSystem.width4,
          _TopNavIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () {},
          ),
          AppDesignSystem.width16,

          // Logout
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.space12,
                  vertical: AppDesignSystem.space8,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppDesignSystem.borderRadii8,
                  border: Border.all(
                    color: AppDesignSystem.brandBorderTranslucent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.logout_outlined,
                      color: AppDesignSystem.textMuted,
                      size: 16,
                    ),
                    AppDesignSystem.width8,
                    Text(
                      'Sign Out',
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDesignSystem.durationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space12,
          vertical: AppDesignSystem.space8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppDesignSystem.brandNeonCyan.withValues(alpha: 0.1)
              : _isHovered
                  ? AppDesignSystem.brandBorderTranslucent
                  : Colors.transparent,
          borderRadius: AppDesignSystem.borderRadii8,
          border: isActive
              ? Border.all(
                  color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 16,
              color: isActive
                  ? AppDesignSystem.brandNeonCyan
                  : AppDesignSystem.textMuted,
            ),
            AppDesignSystem.width8,
            Text(
              widget.label,
              style: AppDesignSystem.bodySmall.copyWith(
                color: isActive
                    ? AppDesignSystem.brandNeonCyan
                    : AppDesignSystem.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopNavIconButton extends StatefulWidget {
  const _TopNavIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool isActive;

  @override
  State<_TopNavIconButton> createState() => _TopNavIconButtonState();
}

class _TopNavIconButtonState extends State<_TopNavIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip ?? '',
          waitDuration: AppDesignSystem.durationMedium,
          child: AnimatedContainer(
            duration: AppDesignSystem.durationFast,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppDesignSystem.brandNeonCyan.withValues(alpha: 0.1)
                  : _isHovered
                      ? AppDesignSystem.brandBorderTranslucent
                      : Colors.transparent,
              borderRadius: AppDesignSystem.borderRadii8,
            ),
            child: Icon(
              widget.icon,
              size: AppDesignSystem.iconSizeMedium,
              color: widget.isActive
                  ? AppDesignSystem.brandNeonCyan
                  : _isHovered
                      ? AppDesignSystem.textPrimary
                      : AppDesignSystem.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PREMIUM LEFT SIDEBAR
// =============================================================================
class _PremiumSidebar extends StatelessWidget {
  const _PremiumSidebar({
    required this.uiState,
    required this.response,
    required this.isCapturingVoice,
    required this.onMicPressed,
  });

  final AppUIState uiState;
  final MissionResponse? response;
  final bool isCapturingVoice;
  final VoidCallback onMicPressed;

  @override
  Widget build(BuildContext context) {
    final hasPlan = response != null;

    int totalBudget = 0;
    int totalBeneficiaries = 0;
    double avgConfidence = 0.0;

    if (hasPlan) {
      final briefs = response!.briefs;
      for (final brief in briefs) {
        totalBudget += brief.budget;
        totalBeneficiaries += brief.beneficiaries;
        avgConfidence += brief.confidence;
      }
      if (briefs.isNotEmpty) {
        avgConfidence /= briefs.length;
      }
    }

    return Container(
      width: AppDesignSystem.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppDesignSystem.brandMetallicSurface,
        border: Border(
          right: BorderSide(
            color: AppDesignSystem.brandBorderTranslucent,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // System Status Header
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.space16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppDesignSystem.brandBorderTranslucent,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDesignSystem.semanticSuccess,
                    boxShadow: [
                      BoxShadow(
                        color: AppDesignSystem.semanticSuccess.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                AppDesignSystem.width8,
                Text(
                  'SYSTEM ONLINE',
                  style: AppDesignSystem.label.copyWith(
                    color: AppDesignSystem.semanticSuccess,
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
                const Spacer(),
                Text(
                  'v2.1',
                  style: AppDesignSystem.caption.copyWith(
                    color: AppDesignSystem.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDesignSystem.space16,
              AppDesignSystem.space16,
              AppDesignSystem.space16,
              AppDesignSystem.space8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.speed_outlined,
                  size: 16,
                  color: AppDesignSystem.brandNeonCyan,
                ),
                AppDesignSystem.width8,
                Text(
                  'TELEMETRY',
                  style: AppDesignSystem.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),

          // KPI Cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space12,
              ),
              child: Column(
                children: [
                  _SidebarKPICard(
                    icon: Icons.location_city_outlined,
                    label: hasPlan ? 'ALLOCATED BUDGET' : 'MONITORED REGION',
                    value: hasPlan
                        ? '₹${(totalBudget / 100000).toStringAsFixed(1)}L'
                        : 'Mumbai North',
                    subtitle: hasPlan ? 'eSAKSHI fund allocation' : '5 operational zones',
                    accentColor: AppDesignSystem.brandNeonCyan,
                  ),
                  AppDesignSystem.height8,
                  _SidebarKPICard(
                    icon: Icons.people_alt_outlined,
                    label: hasPlan ? 'BENEFICIARY IMPACT' : 'MAPPED WARDS',
                    value: hasPlan
                        ? '${(totalBeneficiaries / 1000).toStringAsFixed(1)}K'
                        : '${uiState.wardPolygons.length} Active',
                    subtitle: hasPlan ? 'Projected public impact' : 'Constituency boundaries',
                    accentColor: AppDesignSystem.semanticInfo,
                  ),
                  AppDesignSystem.height8,
                  _SidebarKPICard(
                    icon: Icons.auto_graph_outlined,
                    label: hasPlan ? 'AI CONFIDENCE' : 'TELEMETRY SIGNALS',
                    value: hasPlan
                        ? '${avgConfidence.toStringAsFixed(1)}%'
                        : '${uiState.signalMarkers.length} Feeds',
                    subtitle: hasPlan ? 'Weighted model accuracy' : 'Real-time sensors',
                    accentColor: AppDesignSystem.semanticSuccess,
                  ),
                  AppDesignSystem.height8,
                  _SidebarKPICard(
                    icon: Icons.security_outlined,
                    label: 'SYSTEM HEALTH',
                    value: '99.9%',
                    subtitle: 'All systems operational',
                    accentColor: AppDesignSystem.semanticSuccess,
                  ),
                ],
              ),
            ),
          ),

          // Voice Command Section
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.space16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppDesignSystem.brandBorderTranslucent,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.mic_outlined,
                      size: 14,
                      color: AppDesignSystem.brandNeonCyan,
                    ),
                    AppDesignSystem.width8,
                    Text(
                      'VOICE COMMAND',
                      style: AppDesignSystem.label.copyWith(
                        fontSize: 9,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                AppDesignSystem.height12,
                CivicTwinButton(
                  onPressed: isCapturingVoice ? null : onMicPressed,
                  label: isCapturingVoice ? 'Listening...' : 'Activate Mission',
                  isLoading: isCapturingVoice,
                  variant: CivicTwinButtonVariant.primary,
                  icon: isCapturingVoice ? Icons.graphic_eq : Icons.mic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarKPICard extends StatefulWidget {
  const _SidebarKPICard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  State<_SidebarKPICard> createState() => _SidebarKPICardState();
}

class _SidebarKPICardState extends State<_SidebarKPICard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDesignSystem.durationFast,
        padding: const EdgeInsets.all(AppDesignSystem.space12),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppDesignSystem.brandObsidianBg.withValues(alpha: 0.8)
              : AppDesignSystem.brandObsidianBg.withValues(alpha: 0.5),
          borderRadius: AppDesignSystem.borderRadii8,
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.3)
                : AppDesignSystem.brandBorderTranslucent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: AppDesignSystem.borderRadii8,
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: widget.accentColor,
              ),
            ),
            AppDesignSystem.width12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: AppDesignSystem.caption.copyWith(
                      color: AppDesignSystem.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                  AppDesignSystem.height4,
                  AnimatedCounter(
                    value: widget.value,
                    style: AppDesignSystem.heading3.copyWith(
                      color: AppDesignSystem.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: AppDesignSystem.caption.copyWith(
                      color: AppDesignSystem.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PREMIUM FLOATING MIC BUTTON
// =============================================================================
class _PremiumMicButton extends StatefulWidget {
  const _PremiumMicButton({
    required this.isCapturing,
    required this.onPressed,
  });

  final bool isCapturing;
  final VoidCallback onPressed;

  @override
  State<_PremiumMicButton> createState() => _PremiumMicButtonState();
}

class _PremiumMicButtonState extends State<_PremiumMicButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isCapturing;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDesignSystem.durationFast,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppDesignSystem.semanticError
                : AppDesignSystem.brandNeonCyan,
            boxShadow: [
              BoxShadow(
                color: (isActive
                        ? AppDesignSystem.semanticError
                        : AppDesignSystem.brandNeonCyan)
                    .withValues(alpha: _isHovered ? 0.5 : 0.3),
                blurRadius: _isHovered ? 20 : 12,
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: Icon(
            isActive ? Icons.mic : Icons.mic_none,
            color: isActive
                ? AppDesignSystem.textPrimary
                : AppDesignSystem.textOnNeon,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PREMIUM AI OVERLAY
// =============================================================================
class _PremiumAIOverlay extends StatefulWidget {
  const _PremiumAIOverlay({required this.state});

  final OperationalState state;

  @override
  State<_PremiumAIOverlay> createState() => _PremiumAIOverlayState();
}

class _PremiumAIOverlayState extends State<_PremiumAIOverlay> {
  int _stageIndex = 0;
  Timer? _timer;

  final List<String> _stages = [
    'Analyzing Signals...',
    'Generating AI Mission...',
    'Loading Spatial Intelligence...',
    'Optimizing eSAKSHI budget allocations...',
    'Synchronizing Analytics...',
    'Rendering Decision Workspace...',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.state != OperationalState.listening) {
      _timer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
        if (mounted) {
          setState(() {
            _stageIndex = (_stageIndex + 1) % _stages.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.state == OperationalState.listening;
    return Positioned.fill(
      child: Container(
        color: AppDesignSystem.brandObsidianBg.withValues(alpha: 0.8),
        child: Center(
          child: CivicTwinGlassPanel(
            padding: const EdgeInsets.all(AppDesignSystem.space32),
            backgroundColor: AppDesignSystem.brandMetallicSurface.withValues(alpha: 0.9),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing icon ring
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isListening
                              ? AppDesignSystem.semanticInfo
                              : AppDesignSystem.brandNeonCyan)
                          .withValues(alpha: 0.1),
                      border: Border.all(
                        color: (isListening
                                ? AppDesignSystem.semanticInfo
                                : AppDesignSystem.brandNeonCyan)
                            .withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isListening
                          ? const Icon(
                              Icons.graphic_eq,
                              size: 32,
                              color: AppDesignSystem.semanticInfo,
                            )
                          : const CivicTwinSpinner(size: 32),
                    ),
                  ),
                  AppDesignSystem.height24,
                  Text(
                    isListening
                        ? 'CAPTURING VOICE COMMAND'
                        : 'AI ENGINE PROCESSING',
                    style: AppDesignSystem.title.copyWith(
                      color: isListening
                          ? AppDesignSystem.semanticInfo
                          : AppDesignSystem.brandNeonCyan,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppDesignSystem.height12,
                  Text(
                    isListening
                        ? 'Speak your spatial resource deployment\ncommand clearly.'
                        : _stages[_stageIndex],
                    style: AppDesignSystem.body.copyWith(
                      color: AppDesignSystem.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppDesignSystem.height24,
                  // Progress indicator bar
                  Container(
                    height: 3,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: AppDesignSystem.borderRadii4,
                      color: AppDesignSystem.brandBorderTranslucent,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: AppDesignSystem.durationSlow,
                        width: isListening ? 60 : 90,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: AppDesignSystem.borderRadii4,
                          color: isListening
                              ? AppDesignSystem.semanticInfo
                              : AppDesignSystem.brandNeonCyan,
                        ),
                      ),
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

// =============================================================================
// PREMIUM MISSION BRIEFS PANEL
// =============================================================================
class _PremiumBriefsPanel extends StatelessWidget {
  const _PremiumBriefsPanel({
    required this.response,
    required this.selectedBrief,
    required this.onBriefSelected,
  });

  final MissionResponse response;
  final MissionBrief? selectedBrief;
  final ValueChanged<MissionBrief> onBriefSelected;

  CivicTwinStatusType _getPriorityType(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return CivicTwinStatusType.error;
      case 'MEDIUM':
        return CivicTwinStatusType.warning;
      case 'LOW':
        return CivicTwinStatusType.info;
      default:
        return CivicTwinStatusType.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CivicTwinGlassPanel(
      padding: const EdgeInsets.all(AppDesignSystem.space12),
      backgroundColor: AppDesignSystem.brandMetallicSurface.withValues(alpha: 0.85),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.space8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: AppDesignSystem.brandNeonCyan,
                ),
                AppDesignSystem.width8,
                Text(
                  'MISSION RECOMMENDATIONS',
                  style: AppDesignSystem.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
                const Spacer(),
                const TimelineSlider(),
              ],
            ),
          ),
          AppDesignSystem.height8,
          // Cards
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: response.briefs.length,
              itemBuilder: (context, index) {
                final brief = response.briefs[index];
                final isSelected = selectedBrief?.missionId == brief.missionId;

                return _PremiumBriefCard(
                  brief: brief,
                  isSelected: isSelected,
                  priorityType: _getPriorityType(brief.priority),
                  onTap: () => onBriefSelected(brief),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBriefCard extends StatefulWidget {
  const _PremiumBriefCard({
    required this.brief,
    required this.isSelected,
    required this.priorityType,
    required this.onTap,
  });

  final MissionBrief brief;
  final bool isSelected;
  final CivicTwinStatusType priorityType;
  final VoidCallback onTap;

  @override
  State<_PremiumBriefCard> createState() => _PremiumBriefCardState();
}

class _PremiumBriefCardState extends State<_PremiumBriefCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDesignSystem.durationFast,
          width: 260,
          margin: const EdgeInsets.symmetric(horizontal: AppDesignSystem.space8),
          padding: const EdgeInsets.all(AppDesignSystem.space12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppDesignSystem.brandNeonCyan.withValues(alpha: 0.08)
                : AppDesignSystem.brandObsidianBg.withValues(alpha: 0.6),
            borderRadius: AppDesignSystem.borderRadii8,
            border: Border.all(
              color: widget.isSelected
                  ? AppDesignSystem.brandNeonCyan.withValues(alpha: 0.5)
                  : _isHovered
                      ? AppDesignSystem.brandBorderTranslucent
                      : AppDesignSystem.brandBorderTranslucent.withValues(alpha: 0.5),
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.1),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CivicTwinStatusChip(
                    label: widget.brief.priority,
                    type: widget.priorityType,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.brief.impactScore}',
                        style: AppDesignSystem.heading3.copyWith(
                          color: AppDesignSystem.brandNeonCyan,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      AppDesignSystem.width4,
                      Text(
                        'pts',
                        style: AppDesignSystem.caption.copyWith(
                          color: AppDesignSystem.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppDesignSystem.height8,
              Text(
                widget.brief.mission,
                style: AppDesignSystem.title.copyWith(
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected
                      ? AppDesignSystem.brandNeonCyan
                      : AppDesignSystem.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                height: 1,
                color: AppDesignSystem.brandBorderTranslucent,
              ),
              AppDesignSystem.height8,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniStat(
                    icon: Icons.account_balance_wallet_outlined,
                    value: '₹${(widget.brief.budget / 100000).toStringAsFixed(1)}L',
                  ),
                  _MiniStat(
                    icon: Icons.people_outline,
                    value: '${(widget.brief.beneficiaries / 1000).toStringAsFixed(0)}K',
                  ),
                  _MiniStat(
                    icon: Icons.verified_outlined,
                    value: '${widget.brief.confidence}%',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppDesignSystem.textMuted),
        AppDesignSystem.width4,
        Text(
          value,
          style: AppDesignSystem.caption.copyWith(
            color: AppDesignSystem.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PREMIUM HISTORY PANEL (Right Slide)
// =============================================================================
class _PremiumHistoryPanel extends ConsumerWidget {
  const _PremiumHistoryPanel({
    required this.constituencyId,
    required this.onClose,
  });

  final String constituencyId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(missionHistoryProvider(constituencyId));

    return Container(
      decoration: const BoxDecoration(
        color: AppDesignSystem.brandMetallicSurface,
        border: Border(
          left: BorderSide(
            color: AppDesignSystem.brandBorderTranslucent,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel Header
          Container(
            padding: const EdgeInsets.all(AppDesignSystem.space16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppDesignSystem.brandBorderTranslucent,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 16,
                  color: AppDesignSystem.brandNeonCyan,
                ),
                AppDesignSystem.width8,
                Text(
                  'PLANNING HISTORY',
                  style: AppDesignSystem.label.copyWith(
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
                const Spacer(),
                _TopNavIconButton(
                  icon: Icons.close,
                  onTap: onClose,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppDesignSystem.space12),
            child: Text(
              'Active eSAKSHI allocations',
              style: AppDesignSystem.bodySmall.copyWith(
                color: AppDesignSystem.textMuted,
              ),
            ),
          ),

          // History List
          Expanded(
            child: historyAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const CivicTwinEmptyState(
                    message: 'No missions have been generated yet.',
                    description: 'Use the voice mic or type a command to trigger spatial reasoning and generate a city decision workspace.',
                    icon: Icons.history,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.space12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: AppDesignSystem.space8,
                      ),
                      padding: const EdgeInsets.all(AppDesignSystem.space12),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.brandObsidianBg.withValues(alpha: 0.5),
                        borderRadius: AppDesignSystem.borderRadii8,
                        border: Border.all(
                          color: AppDesignSystem.brandBorderTranslucent,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppDesignSystem.brandNeonCyan.withValues(alpha: 0.1),
                              borderRadius: AppDesignSystem.borderRadii4,
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: AppDesignSystem.brandNeonCyan,
                              size: 14,
                            ),
                          ),
                          AppDesignSystem.width12,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.command,
                                  style: AppDesignSystem.bodySmall.copyWith(
                                    color: AppDesignSystem.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                AppDesignSystem.height4,
                                Text(
                                  item.createdAt.toLocal().toString().split('.').first,
                                  style: AppDesignSystem.caption.copyWith(
                                    color: AppDesignSystem.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CivicTwinSpinner()),
              error: (error, _) => CivicTwinErrorState(
                errorText: error.toString(),
                onRetry: () => ref.invalidate(missionHistoryProvider(constituencyId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom monogram painter drawing interlocking "C" and "T" geometric paths.
class _GeometricMonogramPainter extends CustomPainter {
  const _GeometricMonogramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintOuter = Paint()
      ..color = AppDesignSystem.textPrimary.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintInner = Paint()
      ..color = AppDesignSystem.brandNeonCyan.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw the "C" outer ring arc
    final pathC = Path();
    pathC.addArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      0.8 * math.pi,
      1.4 * math.pi,
    );
    canvas.drawPath(pathC, paintOuter);

    // Draw the intersecting geometric "T"
    final pathT = Path();
    pathT.moveTo(center.dx - 6, center.dy - 6);
    pathT.lineTo(center.dx + 6, center.dy - 6);
    pathT.moveTo(center.dx, center.dy - 6);
    pathT.lineTo(center.dx, center.dy + 8);
    canvas.drawPath(pathT, paintInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PremiumMapLegend extends StatelessWidget {
  const _PremiumMapLegend();

  @override
  Widget build(BuildContext context) {
    return CivicTwinGlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space12,
        vertical: AppDesignSystem.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SIGNAL SEVERITY',
            style: AppDesignSystem.label.copyWith(
              fontSize: 8,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: AppDesignSystem.brandNeonCyan,
            ),
          ),
          AppDesignSystem.height8,
          _legendItem(const Color(0xFFFF1744), 'Critical Alert'),
          AppDesignSystem.height4,
          _legendItem(const Color(0xFFFF9100), 'High Severity'),
          AppDesignSystem.height4,
          _legendItem(const Color(0xFF00E5FF), 'Medium Severity'),
          AppDesignSystem.height4,
          _legendItem(const Color(0xFF29B6F6), 'Low Severity'),
          AppDesignSystem.height4,
          _legendItem(const Color(0xFF00E676), 'Resolved Today'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
        AppDesignSystem.width8,
        Text(
          label,
          style: AppDesignSystem.caption.copyWith(
            fontSize: 9,
            color: AppDesignSystem.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PremiumSignalDetailCard extends StatelessWidget {
  const _PremiumSignalDetailCard({
    required this.signalId,
    required this.signals,
    required this.onClose,
  });

  final String signalId;
  final List<dynamic> signals;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final signal = signals.firstWhere(
      (s) => s['id'] == signalId,
      orElse: () => null,
    );
    if (signal == null) return const SizedBox.shrink();

    final status = signal['status'] as String;
    final severity = signal['severity'] as int;
    final category = signal['category'] as String;
    final description = signal['description'] as String;
    final wardId = signal['ward_id'] as String;

    Color severityColor = AppDesignSystem.brandNeonCyan;
    if (status.toLowerCase() == 'closed' || status.toLowerCase() == 'completed') {
      severityColor = AppDesignSystem.semanticSuccess;
    } else if (severity >= 9) {
      severityColor = AppDesignSystem.semanticError;
    } else if (severity >= 7) {
      severityColor = AppDesignSystem.semanticWarning;
    } else if (severity >= 5) {
      severityColor = AppDesignSystem.semanticInfo;
    }

    return SizedBox(
      width: 280,
      child: CivicTwinGlassPanel(
        padding: const EdgeInsets.all(AppDesignSystem.space16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: AppDesignSystem.borderRadii4,
                  border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'SEVERITY $severity',
                  style: AppDesignSystem.caption.copyWith(
                    color: severityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppDesignSystem.textMuted,
                  ),
                ),
              ),
            ],
          ),
          AppDesignSystem.height12,
          Text(
            category.toUpperCase(),
            style: AppDesignSystem.label.copyWith(
              fontSize: 10,
              color: AppDesignSystem.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          AppDesignSystem.height4,
          Text(
            'Ward ID: $wardId  •  Status: ${status.toUpperCase()}',
            style: AppDesignSystem.caption.copyWith(
              fontSize: 10,
              color: AppDesignSystem.textMuted,
            ),
          ),
          AppDesignSystem.height8,
          Text(
            description,
            style: AppDesignSystem.bodySmall.copyWith(
              color: AppDesignSystem.textSecondary,
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),);
  }
}

class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
  });

  final String value;
  final String prefix;
  final String suffix;
  final TextStyle? style;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _targetValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _parseAndAnimate();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _parseAndAnimate();
    }
  }

  void _parseAndAnimate() {
    final cleanStr = widget.value.replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(cleanStr) ?? 0.0;
    
    final double start = _targetValue;
    _targetValue = parsed;
    
    _animation = Tween<double>(begin: start, end: _targetValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final current = _animation.value;
        String text;
        if (_targetValue % 1 == 0 && current.roundToDouble() == current) {
          text = current.toInt().toString();
        } else {
          text = current.toStringAsFixed(1);
        }
        
        String finalPrefix = widget.prefix;
        String finalSuffix = widget.suffix;
        if (finalPrefix.isEmpty && finalSuffix.isEmpty) {
          final firstNumIndex = widget.value.indexOf(RegExp(r'[0-9]'));
          if (firstNumIndex > 0) {
            finalPrefix = widget.value.substring(0, firstNumIndex);
          }
          final lastNumIndex = widget.value.lastIndexOf(RegExp(r'[0-9]'));
          if (lastNumIndex >= 0 && lastNumIndex < widget.value.length - 1) {
            finalSuffix = widget.value.substring(lastNumIndex + 1);
          }
        }

        return Text(
          '$finalPrefix$text$finalSuffix',
          style: widget.style,
        );
      },
    );
  }
}
