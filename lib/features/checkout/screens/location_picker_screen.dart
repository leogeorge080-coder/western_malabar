import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:western_malabar/theme.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String label;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final String initialAddressLabel;

  const LocationPickerScreen({
    super.key,
    required this.initialAddressLabel,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _ukDefault = LatLng(53.5511, -0.4828);

  late LatLng _selectedLatLng;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = _ukDefault;
  }

  void _confirmSelection() {
    Navigator.of(context).pop(
      PickedLocation(
        latitude: _selectedLatLng.latitude,
        longitude: _selectedLatLng.longitude,
        label: widget.initialAddressLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marker = Marker(
      markerId: const MarkerId('delivery_pin'),
      position: _selectedLatLng,
      draggable: true,
      onDragEnd: (value) {
        setState(() {
          _selectedLatLng = value;
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Drop Delivery Pin',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0D98D)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Color(0xFF8A6700),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap on the map or drag the pin to the exact delivery location.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B5400),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _ukDefault,
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: (latLng) {
                  setState(() {
                    _selectedLatLng = latLng;
                  });
                },
                markers: {marker},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Lat: ${_selectedLatLng.latitude.toStringAsFixed(6)}\nLng: ${_selectedLatLng.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmSelection,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        'Confirm Delivery Pin',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WMTheme.royalPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
