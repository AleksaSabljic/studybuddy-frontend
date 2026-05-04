import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _loading = false;
  bool _sharing = false;
  final Set<Marker> _markers = {};
  List<GroupLocation> _groupLocations = [];
  Timer? _shareTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _startPolling();
  }

  @override
  void dispose() {
    _shareTimer?.cancel();
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchGroup());
    _fetchGroup();
  }

  Future<void> _fetchGroup() async {
    final locations = await LocationService.getGroupLocations();
    if (!mounted) return;
    setState(() {
      _groupLocations = locations;
      _rebuildMarkers();
    });
  }

  void _rebuildMarkers() {
    _markers.clear();
    if (_currentPosition != null) {
      final user = context.read<AuthProvider>().user;
      _markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: InfoWindow(
          title: user?.username ?? 'Me',
          snippet: 'You',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }
    for (final loc in _groupLocations) {
      _markers.add(Marker(
        markerId: MarkerId('user_${loc.userId}'),
        position: LatLng(loc.lat, loc.lng),
        infoWindow: InfoWindow(title: loc.username),
      ));
    }
  }

  Future<void> _getLocation() async {
    setState(() => _loading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      setState(() => _loading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        setState(() => _loading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permissions permanently denied. Open settings.')),
        );
      }
      setState(() => _loading = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;

    setState(() {
      _currentPosition = pos;
      _loading = false;
      _rebuildMarkers();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
    );

    if (_sharing) {
      await LocationService.postLocation(pos.latitude, pos.longitude);
    }
  }

  Future<void> _toggleShare() async {
    if (_sharing) {
      _shareTimer?.cancel();
      _shareTimer = null;
      await LocationService.deleteLocation();
      if (mounted) {
        setState(() => _sharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stopped sharing location'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } else {
      if (_currentPosition == null) return;
      await LocationService.postLocation(
          _currentPosition!.latitude, _currentPosition!.longitude);
      _shareTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        if (mounted) setState(() => _currentPosition = pos);
        await LocationService.postLocation(pos.latitude, pos.longitude);
      });
      if (mounted) {
        setState(() => _sharing = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing your study location with the group'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(48.1486, 17.1077);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _getLocation();
              _fetchGroup();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (kIsWeb)
            Container(
              color: scheme.surfaceVariant,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined,
                        size: 64,
                        color: scheme.onSurfaceVariant.withOpacity(.4)),
                    const SizedBox(height: 12),
                    Text('Map view not available in browser',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant.withOpacity(.6))),
                  ],
                ),
              ),
            )
          else
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: initialPosition, zoom: 13),
              onMapCreated: (c) => _mapController = c,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),

          if (_loading)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),

          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_pin, color: scheme.primary),
                        const SizedBox(width: 8),
                        const Text('Your Study Location',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_currentPosition != null)
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, '
                        'Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      const Text('Location not available',
                          style: TextStyle(color: Colors.grey)),

                    if (_groupLocations.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text('Group members sharing location:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface.withOpacity(.7))),
                      const SizedBox(height: 6),
                      ..._groupLocations.map((loc) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.person_pin_circle_outlined,
                                    size: 14),
                                const SizedBox(width: 4),
                                Text(loc.username,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Text(
                                  '${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          )),
                    ],

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _getLocation();
                              _fetchGroup();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _currentPosition == null
                                ? null
                                : _toggleShare,
                            icon: Icon(_sharing
                                ? Icons.stop_circle_outlined
                                : Icons.share_location),
                            label: Text(_sharing ? 'Stop Sharing' : 'Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _sharing ? Colors.red : scheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
