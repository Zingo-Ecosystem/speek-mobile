import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/session.dart';
import '../../data/mock_data.dart';
import '../../data/repositories.dart';
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
  static const _start = LatLng(25, 0); // world-ish center
  double _zoom = 3.2;
  LatLng? _myLocation;
  bool _locating = false;
  bool _needsLocation = false; // show the "enable location" prompt

  // Live data: starts with mock so the map looks alive, replaced by /Map/nearby.
  List<SpeekUser> _users = List.of(Mock.mapUsers);
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    // Authenticated users see real data immediately (worldwide), then we refine
    // around their location once we have it. Guests keep the demo map.
    if (Session.instance.isAuthenticated) {
      _users = const [];
      _refreshNearby(_start);
    }
    // Proactively triggers the OS "Allow location" dialog on entering the map,
    // but stays quiet (no error toasts) if the user declines.
    WidgetsBinding.instance.addPostFrameCallback((_) => _locateMe(silent: true));
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    super.dispose();
  }

  Future<void> _refreshNearby(LatLng at) async {
    if (!Session.instance.isAuthenticated) return;
    try {
      // Pull a wide radius so the map reflects real online speakers worldwide.
      final users = await Repos.map
          .nearby(lat: at.latitude, lng: at.longitude, radiusKm: 20000, limit: 200);
      if (!mounted) return;
      // Once authenticated we always show real data (even if it's just a few),
      // never the demo users.
      setState(() => _users = users);
    } catch (_) {}
  }

  void _startHeartbeat(LatLng at) {
    if (!Session.instance.isAuthenticated) return;
    Repos.map.heartbeat(at.latitude, at.longitude).catchError((_) {});
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      final loc = _myLocation ?? _start;
      Repos.map.heartbeat(loc.latitude, loc.longitude).catchError((_) {});
      // Keep "online / talking" markers fresh.
      _refreshNearby(loc);
    });
  }

  /// Called from the in-app "Enable location" banner. Re-requests permission,
  /// or sends the user to Settings if they previously blocked it for good.
  Future<void> _enableLocation() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }
    await _locateMe();
  }

  void _zoomBy(double delta) {
    final z = (_zoom + delta).clamp(1.5, 18.0);
    setState(() => _zoom = z);
    _map.move(_map.camera.center, z);
  }

  Future<void> _locateMe({bool silent = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        // This shows the OS "Allow location" dialog.
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _needsLocation = true);
        if (!silent) {
          _toast('Allow location access to find people near you.',
              type: SnackType.error);
        }
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _needsLocation = true);
        if (!silent) {
          _toast('Turn on location services to find people near you.',
              type: SnackType.error);
        }
        return;
      }
      if (mounted) setState(() => _needsLocation = false);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15)),
      ).timeout(const Duration(seconds: 18),
          onTimeout: () => Geolocator.getLastKnownPosition().then(
              (p) => p ?? (throw Exception('timeout'))));
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _myLocation = here;
        _zoom = 14;
      });
      _map.move(here, 14);
      _startHeartbeat(here);
      _refreshNearby(here);
    } catch (e) {
      if (!silent) _toast('Could not get your location.', type: SnackType.error);
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
    final onlineCount = _users.where((u) => u.online).length;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _start,
              initialZoom: _zoom,
              minZoom: 2.8,
              maxZoom: 18,
              backgroundColor: AppColors.n900,
              // Keep the camera inside the world so panning never reveals the
              // empty (dark) area beyond the map edges.
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-85, -180),
                  const LatLng(85, 180),
                ),
              ),
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
                // Lift the very dark CARTO tiles a touch so the map reads as a
                // softer dark mode instead of near-black.
                tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    1.18, 0, 0, 0, 22, //
                    0, 1.18, 0, 0, 22, //
                    0, 0, 1.18, 0, 26, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: tileWidget,
                ),
              ),
              MarkerLayer(
                markers: [
                  for (final u in _users)
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

          // Online count pill — short text, left-aligned and lifted above the
          // bottom nav so it never sits under the center Map button.
          Positioned(
            left: Insets.x4,
            bottom: 100 + MediaQuery.of(context).padding.bottom,
            child: Pill('🌐 $onlineCount online'),
          ),

          // Location-required prompt — shown until the user enables location.
          if (_needsLocation)
            Positioned(
              left: Insets.x4,
              right: Insets.x4,
              bottom: 150 + MediaQuery.of(context).padding.bottom,
              child: GestureDetector(
                onTap: _enableLocation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.grad,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.brand500.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Enable location',
                                style: AppText.label
                                    .copyWith(color: Colors.white)),
                            const SizedBox(height: 2),
                            Text('So people can find you on the map',
                                style: AppText.caption.copyWith(
                                    color: Colors.white
                                        .withValues(alpha: 0.85),
                                    fontSize: 11.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
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
    // In a call → green ring + phone badge (stays visible, not removed).
    final ringColor = user.inCall
        ? AppColors.success
        : user.online
            ? AppColors.brand500
            : Colors.white.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
                          color: ringColor.withValues(alpha: 0.5),
                          blurRadius: 12),
                  ],
                ),
                child: Avatar(user.photoUrl,
                    size: 40, online: user.online && !user.inCall, name: user.name),
              ),
              if (user.inCall)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.n900, width: 2),
                    ),
                    child: const Icon(Icons.call, size: 9, color: Colors.white),
                  ),
                ),
            ],
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
