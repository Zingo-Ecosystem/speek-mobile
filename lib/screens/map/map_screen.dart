import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/session.dart';
import '../../state/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/repositories.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import 'map_filter_sheet.dart';
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
  static const _start = LatLng(30, 8); // world-ish center
  double _zoom = 2.4;
  LatLng? _myLocation;
  bool _locating = false;
  bool _needsLocation = false;

  // Live data
  List<SpeekUser> _users = List.of(Mock.mapUsers);
  Timer? _heartbeat;

  // Active filters
  MapFilter _filter = const MapFilter();

  // Boost state
  bool _boosting = false;

  @override
  void initState() {
    super.initState();
    if (Session.instance.isAuthenticated) {
      _users = const [];
      _refreshNearby(_start);
    }
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
      final users = await Repos.map.nearby(
        lat: at.latitude,
        lng: at.longitude,
        radiusKm: 20000,
        limit: 200,
        role: _filter.role,
        maxCefrLevel: _filter.maxCefrLevel,
        countryCode: _filter.countryCode.isEmpty ? null : _filter.countryCode,
        goals: _filter.goals == 0 ? null : _filter.goals,
      );

      debugPrint('nearby users: ${users.length}');
      if (!mounted) return;
      setState(() => _users = users);
    } catch (_) {}
  }

  void _startHeartbeat(LatLng at) {
    debugPrint('[Heartbeat] isAuthenticated=${Session.instance.isAuthenticated}');
    if (!Session.instance.isAuthenticated) return;
    // Respect the "Show me on the map" privacy toggle.
    if (AppState.instance.showOnMap) {
      Repos.map.heartbeat(at.latitude, at.longitude)
          .then((_) => debugPrint('[Heartbeat] sent ${at.latitude},${at.longitude}'))
          .catchError((e) => debugPrint('[Heartbeat] error: $e'));
    }
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      final loc = _myLocation ?? _start;
      if (AppState.instance.showOnMap) {
        Repos.map.heartbeat(loc.latitude, loc.longitude)
            .then((_) => debugPrint('[Heartbeat] tick'))
            .catchError((e) => debugPrint('[Heartbeat] tick error: $e'));
      } else {
        Repos.map.offline().catchError((_) {});
      }
      _refreshNearby(loc);
    });
  }

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

  Future<void> _openFilter() async {
    final result = await showMapFilter(context, _filter);
    if (result == null || !mounted) return;
    setState(() => _filter = result);
    _refreshNearby(_myLocation ?? _start);
  }

  Future<void> _boost() async {
    if (_boosting) return;
    setState(() => _boosting = true);
    try {
      await Repos.map.boost();
      if (!mounted) return;
      _toast('Boost active for 2 hours! Your profile appears first on the map.');
    } catch (_) {
      if (mounted) _toast('Could not activate boost.', type: SnackType.error);
    } finally {
      if (mounted) setState(() => _boosting = false);
    }
  }

  void _toast(String msg, {SnackType type = SnackType.info}) {
    if (!mounted) return;
    showSnack(context, msg, type: type);
  }

  /// Many users can share the exact same coordinate (same city centroid, or a
  /// privacy-rounded position). Stacked markers can't be tapped apart even at
  /// max zoom, so we fan co-located users out onto a small deterministic ring.
  /// Deterministic = the same user always lands in the same spot (no jitter on
  /// rebuild). The ~0.00018° radius (~20m) only becomes visible once you zoom
  /// in close, leaving the world view unchanged.
  Map<String, LatLng> _spreadPoints(List<SpeekUser> users) {
    final groups = <String, List<SpeekUser>>{};
    for (final u in users) {
      // Bucket by ~11m precision so genuinely co-located users group together.
      final key = '${u.lat.toStringAsFixed(4)},${u.lng.toStringAsFixed(4)}';
      (groups[key] ??= []).add(u);
    }
    final out = <String, LatLng>{};
    for (final group in groups.values) {
      if (group.length == 1) {
        out[group.first.id] = LatLng(group.first.lat, group.first.lng);
        continue;
      }
      // Stable order so positions don't shuffle between rebuilds.
      group.sort((a, b) => a.id.compareTo(b.id));
      const radius = 0.00018; // degrees (~20m)
      for (var i = 0; i < group.length; i++) {
        final u = group[i];
        final angle = (2 * math.pi / group.length) * i;
        // cos(lat) keeps the ring circular away from the equator.
        final latRad = u.lat * math.pi / 180;
        out[u.id] = LatLng(
          u.lat + radius * math.sin(angle),
          u.lng + radius * math.cos(angle) / math.max(0.2, math.cos(latRad)),
        );
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final onlineCount = _users.where((u) => u.online).length;
    final hasFilter = !_filter.isEmpty;
    final points = _spreadPoints(_users);

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
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(-85, -180),
                  const LatLng(85, 180),
                ),
              ),
              onPositionChanged: (pos, _) => _zoom = pos.zoom,
              interactionOptions: const InteractionOptions(
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
                tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    1.18, 0, 0, 0, 22,
                    0, 1.18, 0, 0, 22,
                    0, 0, 1.18, 0, 26,
                    0, 0, 0, 1, 0,
                  ]),
                  child: tileWidget,
                ),
              ),
              MarkerLayer(
                markers: [
                  for (final u in _users)
                    Marker(
                      point: points[u.id] ?? LatLng(u.lat, u.lng),
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
                  TextSourceAttribution('OpenStreetMap', onTap: () {}),
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
                _glassIcon(
                  Icons.tune_rounded,
                  _openFilter,
                  active: hasFilter,
                ),
              ],
            ),
          ),

          // Zoom controls + boost
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
                    _locating
                        ? Icons.hourglass_empty_rounded
                        : Icons.my_location_rounded,
                    _locateMe),
                const SizedBox(height: 8),
                _glassIcon(
                  _boosting ? Icons.hourglass_empty_rounded : Icons.rocket_launch_rounded,
                  _boost,
                  tooltip: 'Boost',
                ),
              ],
            ),
          ),

          // Online count pill
          Positioned(
            left: Insets.x4,
            bottom: 100 + MediaQuery.of(context).padding.bottom,
            child: Row(
              children: [
                Pill('🌐 $onlineCount online'),
                if (hasFilter) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _filter = const MapFilter());
                      _refreshNearby(_myLocation ?? _start);
                    },
                    child: Pill('✕ Filter active',
                        bg: AppColors.brand500.withValues(alpha: 0.2),
                        fg: AppColors.brand200,
                        border: AppColors.brand500.withValues(alpha: 0.4)),
                  ),
                ],
              ],
            ),
          ),

          // Creative full-screen location gate.
          if (_needsLocation)
            _LocationGate(onEnable: _enableLocation, busy: _locating),
        ],
      ),
    );
  }

  Widget _glassIcon(IconData icon, VoidCallback onTap,
      {bool active = false, String? tooltip}) {
    final child = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: active
              ? AppColors.brand500.withValues(alpha: 0.25)
              : const Color(0xFF12121A).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
              color: active
                  ? AppColors.brand500.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon,
            size: 20,
            color: active ? AppColors.brand200 : Colors.white),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
  }
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

/// Full-screen, premium location-permission gate with an animated radar pulse.
/// Replaces the OS-default-feeling banner with a branded, creative moment.
class _LocationGate extends StatefulWidget {
  final VoidCallback onEnable;
  final bool busy;
  const _LocationGate({required this.onEnable, required this.busy});

  @override
  State<_LocationGate> createState() => _LocationGateState();
}

class _LocationGateState extends State<_LocationGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: AppColors.n900.withValues(alpha: 0.82),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated radar
                SizedBox(
                  width: 200,
                  height: 200,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, __) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          for (int i = 0; i < 3; i++)
                            _ring((_c.value + i / 3) % 1),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.grad,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.brand500
                                        .withValues(alpha: 0.6),
                                    blurRadius: 34,
                                    offset: const Offset(0, 12)),
                              ],
                            ),
                            child: const Icon(Icons.explore_rounded,
                                color: Colors.white, size: 42),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 36),
                Text('Turn on your radar',
                    textAlign: TextAlign.center, style: AppText.h1),
                const SizedBox(height: 12),
                Text(
                  'Speek uses your location to put you on the live map and '
                  'find speakers near you. Your exact spot is never shared.',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMuted,
                ),
                const SizedBox(height: 22),
                _perk(Icons.public_rounded, 'Appear on the global live map'),
                const SizedBox(height: 10),
                _perk(Icons.bolt_rounded, 'Discover people online right now'),
                const SizedBox(height: 10),
                _perk(Icons.lock_outline_rounded, 'Private — only your region shows'),
                const SizedBox(height: 32),
                PrimaryButton(
                  widget.busy ? 'Enabling…' : '📍 Enable location',
                  onTap: widget.busy ? null : widget.onEnable,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ring(double t) {
    final size = 84 + t * 116;
    return Opacity(
      opacity: (1 - t) * 0.6,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.brand400.withValues(alpha: 0.7), width: 1.5),
        ),
      ),
    );
  }

  Widget _perk(IconData icon, String text) => Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brand500.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.brand300),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      );
}

/// Avatar marker with online dot and a small pointer below.
class _UserMarker extends StatelessWidget {
  final SpeekUser user;
  final VoidCallback onTap;
  const _UserMarker({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Friends stand out in green ("yes, this is my friend") regardless of state.
    final ringColor = user.isFriend
        ? AppColors.success
        : user.inCall
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
                  // Green-tinted backdrop for friends so they read as "my people".
                  color: user.isFriend
                      ? AppColors.success.withValues(alpha: 0.22)
                      : AppColors.n800,
                  border: Border.all(
                      color: ringColor, width: user.isFriend ? 2.5 : 2),
                  boxShadow: [
                    if (user.online || user.isFriend)
                      BoxShadow(
                          color: ringColor.withValues(alpha: 0.5),
                          blurRadius: 12),
                  ],
                ),
                child: ClipOval(
                  child: AppState.instance.isPremium
                      ? Avatar(user.photoUrl,
                          size: 40,
                          online: user.online && !user.inCall,
                          name: user.name)
                      : ImageFiltered(
                          imageFilter:
                              ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Avatar(user.photoUrl,
                              size: 40,
                              online: user.online && !user.inCall,
                              name: user.name),
                        ),
                ),
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
                )
              // Friend check-badge (skip when the call badge already occupies the
              // corner) so friends are instantly recognizable on the map.
              else if (user.isFriend)
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
                    child: const Icon(Icons.check_rounded,
                        size: 11, color: Colors.white),
                  ),
                ),
            ],
          ),
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
