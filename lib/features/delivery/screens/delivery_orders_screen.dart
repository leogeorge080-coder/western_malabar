import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:western_malabar/core/feedback/scan_feedback.dart';
import 'package:western_malabar/features/admin/models/admin_order_model.dart';
import 'package:western_malabar/features/admin/screens/order_qr_scan_screen.dart';
import 'package:western_malabar/features/admin/services/admin_orders_service.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';

String buildFullAddress(AdminOrderModel order) {
  final parts = [
    order.addressLine1,
    order.addressLine2,
    order.city,
    order.postcode,
  ].where((e) => e != null && e.trim().isNotEmpty).toList();

  return parts.join(', ');
}

Future<void> openGoogleMaps(AdminOrderModel order) async {
  Uri uri;

  if (order.latitude != null && order.longitude != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${order.latitude},${order.longitude}',
    );
  } else {
    final address = buildFullAddress(order);
    final encoded = Uri.encodeComponent(address);
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
  }

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String _routeLocation(AdminOrderModel order) {
  if (order.latitude != null && order.longitude != null) {
    return '${order.latitude},${order.longitude}';
  }
  return buildFullAddress(order);
}

class _DriverStartPoint {
  const _DriverStartPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

List<AdminOrderModel> planDeliveryRoute(
  List<AdminOrderModel> orders, {
  _DriverStartPoint? startPoint,
}) {
  if (orders.length <= 1) return [...orders];

  final prioritized = [...orders];
  prioritized.sort((a, b) {
    final priorityCompare = a.statusPriority.compareTo(b.statusPriority);
    if (priorityCompare != 0) return priorityCompare;

    final aSlot = (a.deliverySlot ?? '').trim().toLowerCase();
    final bSlot = (b.deliverySlot ?? '').trim().toLowerCase();
    final slotCompare = aSlot.compareTo(bSlot);
    if (slotCompare != 0) return slotCompare;

    final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aCreated.compareTo(bCreated);
  });

  final pinned = prioritized.where((o) => o.hasPinnedLocation).toList();
  final unpinned = prioritized.where((o) => !o.hasPinnedLocation).toList();

  if (pinned.length <= 1) {
    return [...pinned, ...unpinned];
  }

  final seedIndex = _bestSeedIndex(pinned, startPoint: startPoint);
  final planned = <AdminOrderModel>[pinned[seedIndex]];
  final remaining = [...pinned]..removeAt(seedIndex);
  var current = planned.first;

  while (remaining.isNotEmpty) {
    remaining.sort((a, b) {
      final da = _distanceBetween(current, a);
      final db = _distanceBetween(current, b);
      return da.compareTo(db);
    });
    current = remaining.removeAt(0);
    planned.add(current);
  }

  final optimizedPinned = _twoOpt(planned);
  return [...optimizedPinned, ...unpinned];
}

double _distanceBetween(AdminOrderModel a, AdminOrderModel b) {
  if (!a.hasPinnedLocation || !b.hasPinnedLocation) {
    return double.infinity;
  }
  return _haversineKm(
    a.latitude!,
    a.longitude!,
    b.latitude!,
    b.longitude!,
  );
}

int _bestSeedIndex(
  List<AdminOrderModel> orders, {
  _DriverStartPoint? startPoint,
}) {
  if (orders.length <= 2) return 0;

  if (startPoint != null) {
    var bestIndex = 0;
    var bestDistance = double.infinity;

    for (var i = 0; i < orders.length; i++) {
      final order = orders[i];
      if (!order.hasPinnedLocation) continue;
      final distance = _haversineKm(
        startPoint.latitude,
        startPoint.longitude,
        order.latitude!,
        order.longitude!,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  var bestIndex = 0;
  var bestScore = double.infinity;

  for (var i = 0; i < orders.length; i++) {
    var score = 0.0;
    for (var j = 0; j < orders.length; j++) {
      if (i == j) continue;
      score += _distanceBetween(orders[i], orders[j]);
    }
    if (score < bestScore) {
      bestScore = score;
      bestIndex = i;
    }
  }

  return bestIndex;
}

List<AdminOrderModel> _twoOpt(List<AdminOrderModel> route) {
  if (route.length < 4) return [...route];

  final best = [...route];
  var improved = true;

  while (improved) {
    improved = false;
    for (var i = 1; i < best.length - 2; i++) {
      for (var k = i + 1; k < best.length - 1; k++) {
        final currentDistance = _edgeDistance(best[i - 1], best[i]) +
            _edgeDistance(best[k], best[k + 1]);
        final candidateDistance = _edgeDistance(best[i - 1], best[k]) +
            _edgeDistance(best[i], best[k + 1]);

        if (candidateDistance + 0.001 < currentDistance) {
          final reversed = best.sublist(i, k + 1).reversed.toList();
          best.replaceRange(i, k + 1, reversed);
          improved = true;
        }
      }
    }
  }

  return best;
}

double _edgeDistance(AdminOrderModel a, AdminOrderModel b) {
  final distance = _distanceBetween(a, b);
  return distance.isFinite ? distance : 0;
}

double _haversineKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusKm = 6371.0;
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_degreesToRadians(lat1)) *
          math.cos(_degreesToRadians(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a.toDouble()), math.sqrt(1 - a.toDouble()));
  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) {
  return degrees * (math.pi / 180.0);
}

double estimatePlannedRouteDistanceKm(
  List<AdminOrderModel> orders, {
  _DriverStartPoint? startPoint,
}) {
  if (orders.isEmpty) return 0;

  final pinned = orders.where((order) => order.hasPinnedLocation).toList();
  if (pinned.isEmpty) return 0;

  var totalDistance = 0.0;

  if (startPoint != null) {
    totalDistance += _haversineKm(
      startPoint.latitude,
      startPoint.longitude,
      pinned.first.latitude!,
      pinned.first.longitude!,
    );
  }

  for (var i = 0; i < pinned.length - 1; i++) {
    totalDistance += _distanceBetween(pinned[i], pinned[i + 1]);
  }

  return totalDistance;
}

Future<void> openPlannedRoute(
  List<AdminOrderModel> orders, {
  _DriverStartPoint? startPoint,
}) async {
  if (orders.isEmpty) return;

  final planned = planDeliveryRoute(orders, startPoint: startPoint);
  final usableStops = planned
      .where((order) => _routeLocation(order).trim().isNotEmpty)
      .take(9)
      .toList();

  if (usableStops.isEmpty) return;

  final origin = startPoint == null
      ? ''
      : '&origin=${Uri.encodeComponent('${startPoint.latitude},${startPoint.longitude}') }';
  final destination = Uri.encodeComponent(_routeLocation(usableStops.last));
  final waypoints = usableStops.length > 1
      ? usableStops
          .take(usableStops.length - 1)
          .map((order) => Uri.encodeComponent(_routeLocation(order)))
          .join('|')
      : '';

  final uri = Uri.parse(
    waypoints.isEmpty
        ? 'https://www.google.com/maps/dir/?api=1&destination=$destination$origin'
        : 'https://www.google.com/maps/dir/?api=1&destination=$destination&waypoints=$waypoints$origin',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final deliveryOrdersProvider =
    FutureProvider<List<AdminOrderModel>>((ref) async {
  final service = ref.read(adminOrdersServiceProvider);
  final all = await service.fetchRecentOrders();

  final filtered = all.where((order) => order.isActiveDeliveryOrder).toList();

  filtered.sort((a, b) {
    final aPriority = a.canDeliver ? 0 : 1;
    final bPriority = b.canDeliver ? 0 : 1;

    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }

    final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aCreated.compareTo(bCreated);
  });

  return filtered;
});

class DeliveryOrdersScreen extends ConsumerWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(deliveryOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Driver Mode',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(deliveryOrdersProvider),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: WMTheme.royalPurple,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: asyncOrders.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Center(
                        child: Text(
                          'No delivery orders right now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(deliveryOrdersProvider);
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          if (orders.length > 1) ...[
                            _RoutePlannerOverviewCard(
                              orders: orders,
                              onOpenPlanner: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => _RoutePlannerScreen(
                                      orders: orders,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          ...List.generate(orders.length, (index) {
                            final order = orders[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == orders.length - 1 ? 0 : 12,
                              ),
                              child: _DeliveryOrderCard(order: order),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: WMTheme.royalPurple,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load delivery orders\n$e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePlannerOverviewCard extends StatelessWidget {
  const _RoutePlannerOverviewCard({
    required this.orders,
    required this.onOpenPlanner,
  });

  final List<AdminOrderModel> orders;
  final VoidCallback onOpenPlanner;

  @override
  Widget build(BuildContext context) {
    final pinnedCount = orders.where((order) => order.hasPinnedLocation).length;
    final readyCount = orders.where((order) => order.canDeliver).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [WMTheme.royalPurple, Color(0xFF6D4AFF)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Route planner ready',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${orders.length} stops • $readyCount active deliveries • $pinnedCount pinned',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onOpenPlanner,
            style: ElevatedButton.styleFrom(
              backgroundColor: WMTheme.royalPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Plan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePlannerScreen extends StatelessWidget {
  const _RoutePlannerScreen({
    required this.orders,
  });

  final List<AdminOrderModel> orders;

  @override
  Widget build(BuildContext context) {
    return _RoutePlannerBody(orders: orders);
  }
}

class _RoutePlannerBody extends ConsumerStatefulWidget {
  const _RoutePlannerBody({
    required this.orders,
  });

  final List<AdminOrderModel> orders;

  @override
  ConsumerState<_RoutePlannerBody> createState() => _RoutePlannerBodyState();
}

class _RoutePlannerBodyState extends ConsumerState<_RoutePlannerBody> {
  _DriverStartPoint? _startPoint;
  bool _loadingLocation = true;
  String? _locationNote;

  @override
  void initState() {
    super.initState();
    _loadDriverLocation();
  }

  Future<void> _loadDriverLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationNote = 'Location is off. Using order coordinates only.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationNote = 'Location permission denied. Using order coordinates only.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _startPoint = _DriverStartPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _loadingLocation = false;
        _locationNote = 'Route starts from your live location.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _locationNote = 'Could not read your location. Using order coordinates only.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final planned = planDeliveryRoute(
      widget.orders,
      startPoint: _startPoint,
    );
    final mappedCount = planned.where((order) => order.hasPinnedLocation).length;
    final routeDistanceKm = estimatePlannedRouteDistanceKm(
      planned,
      startPoint: _startPoint,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Route Planner',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadingLocation ? null : _loadDriverLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      tooltip: 'Refresh live location',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Optimized stop order',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${planned.length} stops planned • $mappedCount pinned locations used for route ordering',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _loadingLocation
                                ? 'Getting your live location...'
                                : (_locationNote ??
                                    'Using order coordinates only.'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          if (routeDistanceKm > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Estimated mapped distance: ${routeDistanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: WMTheme.royalPurple,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => openPlannedRoute(
                                planned,
                                startPoint: _startPoint,
                              ),
                              icon: const Icon(Icons.navigation_rounded),
                              label: const Text(
                                'Open route in Google Maps',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WMTheme.royalPurple,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pinned stops are optimized first with live driver location when available. Stops without coordinates are appended after the optimized route.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(planned.length, (index) {
                      final order = planned[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == planned.length - 1 ? 0 : 12,
                        ),
                        child: _RouteStopCard(
                          stopNumber: index + 1,
                          order: order,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteStopCard extends StatelessWidget {
  const _RouteStopCard({
    required this.stopNumber,
    required this.order,
  });

  final int stopNumber;
  final AdminOrderModel order;

  @override
  Widget build(BuildContext context) {
    final orderNo = order.orderNumber ?? order.id;
    final customerName = order.customerName ?? 'Unknown customer';
    final slot = order.deliverySlot ?? 'No slot';
    final address = buildFullAddress(order);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDFF),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '$stopNumber',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: WMTheme.royalPurple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderNo,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: WMTheme.royalPurple,
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  text: slot,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  text: address.isEmpty ? 'No address available' : address,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PlannerPill(
                      label: order.displayStatusLabel,
                      foreground: WMTheme.royalPurple,
                      background: const Color(0xFFF3EDFF),
                    ),
                    _PlannerPill(
                      label: order.hasPinnedLocation ? 'Pinned' : 'Approximate',
                      foreground: order.hasPinnedLocation
                          ? Colors.green
                          : Colors.orange.shade800,
                      background: order.hasPinnedLocation
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => openGoogleMaps(order),
            icon: const Icon(
              Icons.navigation_rounded,
              color: WMTheme.royalPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerPill extends StatelessWidget {
  const _PlannerPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _DeliveryOrderCard extends ConsumerStatefulWidget {
  final AdminOrderModel order;

  const _DeliveryOrderCard({
    required this.order,
  });

  @override
  ConsumerState<_DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends ConsumerState<_DeliveryOrderCard> {
  bool _loading = false;
  Color? _flashColor;

  AdminOrderModel get order => widget.order;

  void _setFlash(Color color) {
    if (!mounted) return;
    setState(() => _flashColor = color);
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _flashColor = null);
    });
  }

  String _fullAddress() {
    final parts = [
      order.addressLine1,
      order.addressLine2,
      order.city,
      order.postcode,
    ].where((e) => (e ?? '').trim().isNotEmpty).cast<String>().toList();

    return parts.join(', ');
  }

  Future<void> _openMaps() async {
    await openGoogleMaps(order);
  }

  Future<void> _scanAndUpdate() async {
    if (_loading || order.isDelivered) return;

    setState(() => _loading = true);

    try {
      final requiredScans =
          order.printedLabelCount > 1 ? order.printedLabelCount : 1;
      final scannedSet = <String>{};

      final baseQr = 'WM|ORDER|${order.id}|${order.orderNumber}';
      final normalBagQr = '$baseQr-N';
      final frozenBagQr = '$baseQr-F';

      final validCodes = requiredScans > 1
          ? <String>{normalBagQr, frozenBagQr}
          : <String>{baseQr, normalBagQr, frozenBagQr};

      while (scannedSet.length < requiredScans) {
        final scannedValue = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => OrderQrScanScreen(
              title: order.canDeliver
                  ? 'Scan Delivery QR'
                  : 'Scan Dispatch QR',
              instruction: requiredScans > 1
                  ? 'Scan each printed bag label for this order'
                  : 'Align the printed order QR inside the frame',
              validator: (rawValue) {
                if (!validCodes.contains(rawValue)) {
                  return 'QR does not match this order';
                }
                if (scannedSet.contains(rawValue)) {
                  return 'This label is already scanned';
                }
                return null;
              },
            ),
          ),
        );

        if (scannedValue == null || scannedValue.trim().isEmpty) {
          return;
        }

        final scanned = scannedValue.trim();

        scannedSet.add(scanned);

        _setFlash(Colors.green);
        await ScanFeedback.success();

        if (!mounted) return;

        if (scannedSet.length < requiredScans) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scan next label (${scannedSet.length}/$requiredScans)',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      if (order.canDispatch) {
        await ref.read(adminOrdersServiceProvider).markOrderOutForDelivery(
              orderId: order.id,
            );

        _setFlash(Colors.green);
        await ScanFeedback.success();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as out for delivery'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (order.canDeliver) {
        await ref.read(adminOrdersServiceProvider).markOrderDelivered(
              orderId: order.id,
            );

        _setFlash(Colors.green);
        await ScanFeedback.success();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered'),
            backgroundColor: Colors.green,
          ),
        );
      }

      ref.invalidate(deliveryOrdersProvider);
    } catch (e) {
      _setFlash(Colors.red);
      await ScanFeedback.error();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderNo = order.orderNumber ?? order.id;
    final customerName = order.customerName ?? 'Unknown customer';
    final phone = order.phone ?? '';
    final slot = order.deliverySlot ?? 'No slot';
    final address = _fullAddress();
    final hasLocation = order.latitude != null && order.longitude != null;

    final statusLabel = order.displayStatusLabel;

    final nextAction = order.canDeliver
        ? 'Scan QR to Deliver'
        : order.canDispatch
            ? 'Scan QR to Dispatch'
            : 'Completed';

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: _flashColor == null
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _flashColor!.withOpacity(0.12),
                ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        orderNo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: WMTheme.royalPurple,
                        ),
                      ),
                    ),
                    _StatusChip(label: statusLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (phone.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  text: slot,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  text: address.isEmpty ? 'No address available' : address,
                ),
                if (hasLocation) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.my_location_rounded,
                    text:
                        'Pinned location: ${order.latitude}, ${order.longitude}',
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openMaps,
                        icon: const Icon(Icons.navigation_rounded),
                        label: Text(hasLocation ? 'Navigate' : 'Open Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_loading ||
                                (!order.canDispatch && !order.canDeliver))
                            ? null
                            : _scanAndUpdate,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                order.canDeliver
                                    ? Icons.qr_code_scanner_rounded
                                    : order.canDispatch
                                        ? Icons.local_shipping_rounded
                                        : Icons.check_circle_rounded,
                              ),
                        label: Text(
                          nextAction,
                          textAlign: TextAlign.center,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (order.canDispatch || order.canDeliver)
                                  ? WMTheme.royalPurple
                                  : Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (label) {
      case 'DELIVERED':
        bg = const Color(0xFFE8F5E9);
        fg = Colors.green;
        break;
      case 'OUT FOR DELIVERY':
        bg = const Color(0xFFEAF5FF);
        fg = const Color(0xFF1565C0);
        break;
      default:
        bg = const Color(0xFFF6F0FB);
        fg = WMTheme.royalPurple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: WMTheme.royalPurple,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
