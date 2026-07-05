import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../history/history_provider.dart';
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

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  bool _isCapturingVoice = false;

  @override
  void dispose() {
    _mapController?.dispose();
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

    ref.listen(missionControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicTwin AI'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                ref.invalidate(
                  missionHistoryProvider(_kDefaultConstituencyId),
                );
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: _HistoryPanel(constituencyId: _kDefaultConstituencyId),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: uiState.cameraTarget,
              zoom: 13,
            ),
            markers: uiState.signalMarkers,
            polygons: uiState.wardPolygons,
            onMapCreated: (controller) => _mapController = controller,
          ),
          if (uiState.state == OperationalState.thinking)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (missionState.response != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _MissionBriefsPanel(response: missionState.response!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleMicPressed,
        backgroundColor: _isCapturingVoice ? Colors.red : null,
        child: Icon(_isCapturingVoice ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}

/// Minimal, functional list of generated mission briefs. Presentation is
/// intentionally plain — a `Card` list, not the glassmorphic overlay
/// design from Document 05 — per the current scope's focus on working
/// logic over visual polish.
class _MissionBriefsPanel extends StatelessWidget {
  const _MissionBriefsPanel({required this.response});

  final MissionResponse response;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          const TimelineSlider(),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: response.briefs.length,
              itemBuilder: (context, index) {
                final brief = response.briefs[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 260,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brief.mission,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('Priority: ${brief.priority}'),
                          Text('Impact score: ${brief.impactScore}'),
                          Text('Budget: \u20b9${brief.budget}'),
                          Text('Confidence: ${brief.confidence}%'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends ConsumerWidget {
  const _HistoryPanel({required this.constituencyId});

  final String constituencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(missionHistoryProvider(constituencyId));

    return historyAsync.when(
      data: (items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item.command),
            subtitle: Text(item.createdAt.toLocal().toString()),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Failed to load history: $error')),
    );
  }
}
