import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import 'user_preview_sheet.dart';

/// Real interactive world map (OpenStreetMap / CARTO dark tiles).
/// Online users are placed at real coordinates — tap a marker to open their
/// preview and start a chat or call.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  static const _start = LatLng(30, 0); // world-ish center
  double _zoom = 2.4;
  LatLng? _myLocation;
  bool _locating = false;

  void _zoomBy(double delta) {
    final z = (_zoom + delta).clamp(1.5, 18.0);
    setState(() => _zoom = z);
    _map.move(_map.camera.center, z);
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('Turn on location services to find people near you.',
            type: SnackType.error);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _toast('Location permission denied.', type: SnackType.error);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _myLocation = here;
        _zoom = 14;
      });
      _map.move(here, 14);
    } catch (e) {
      _toast('Could not get your location.', type: SnackType.error);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String msg, {SnackType type = SnackType.info}) {
    if (!mounted) return;
    showSnack(context, msg, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final onlineCount = Mock.mapUsers.where((u) => u.online).length;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _start,
              initialZoom: _zoom,
              minZoom: 1.5,
              maxZoom: 18,
              backgroundColor: AppColors.n900,
              onPositionChanged: (pos, _) => _zoom = pos.zoom,
              interactionOptions: const InteractionOptions(
                // Explicit gestures: one-finger drag, two-finger pinch zoom &
                // move, trackpad/wheel zoom, double-tap and fling.
                flags: InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.doubleTapDragZoom |
                    InteractiveFlag.scrollWheelZoom |
                    InteractiveFlag.flingAnimation,
                pinchZoomThreshold: 0.2,
                scrollWheelVelocity: 0.005,
                enableMultiFingerGestureRace: true,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'com.speek.app',
                tileProvider: NetworkTileProvider(),
              ),
              MarkerLayer(
                markers: [
                  for (final u in Mock.mapUsers)
                    Marker(
                      point: LatLng(u.lat, u.lng),
                      width: 54,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: _UserMarker(
                        user: u,
                        onTap: () => showUserPreview(context, u),
                      ),
                    ),
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 28,
                      height: 28,
                      child: const _MeMarker(),
                    ),
                ],
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution('OpenStreetMap',
                      onTap: () {}),
                  TextSourceAttribution('CARTO', onTap: () {}),
                ],
              ),
            ],
          ),

          // Search bar + filter
          Positioned(
            top: topPad + 8,
            left: Insets.x4,
            right: Insets.x4,
            child: Row(
              children: [
                Expanded(child: _SearchBar()),
                const SizedBox(width: 10),
                _glassIcon(Icons.tune_rounded, () {}),
              ],
            ),
          ),

          // Zoom controls
          Positioned(
            right: Insets.x4,
            top: topPad + 70,
            child: Column(
              children: [
                _glassIcon(Icons.add, () => _zoomBy(1)),
                const SizedBox(height: 8),
                _glassIcon(Icons.remove, () => _zoomBy(-1)),
                const SizedBox(height: 8),
                _glassIcon(
                    _locating ? Icons.hourglass_empty_rounded : Icons.my_location_rounded,
                    _locateMe),
              ],
            ),
          ),

          // Online count pill
          Positioned(
            left: Insets.x4,
            bottom: 110,
            child: Pill('🌐 $onlineCount speakers online now'),
          ),
        ],
      ),
    );
  }

  Widget _glassIcon(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF12121A).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      );
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.n200),
          const SizedBox(width: 8),
          Text('Search a city or country',
              style: AppText.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Avatar marker with online dot and a small pointer below.
class _UserMarker extends StatelessWidget {
  final SpeekUser user;
  final VoidCallback onTap;
  const _UserMarker({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ringColor =
        user.online ? AppColors.brand500 : Colors.white.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.n800,
              border: Border.all(color: ringColor, width: 2),
              boxShadow: [
                if (user.online)
                  BoxShadow(
                      color: AppColors.brand500.withValues(alpha: 0.5),
                      blurRadius: 12),
              ],
            ),
            child: Avatar(user.photoUrl, size: 40, online: user.online),
          ),
          // pointer
          Transform.translate(
            offset: const Offset(0, -3),
            child: CustomPaint(
              size: const Size(12, 8),
              painter: _PointerPainter(ringColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing blue dot for the current user's real location.
class _MeMarker extends StatelessWidget {
  const _MeMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cyan,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.cyan.withValues(alpha: 0.6), blurRadius: 14),
        ],
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  final Color color;
  _PointerPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.n800;
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => oldDelegate.color != color;
}
