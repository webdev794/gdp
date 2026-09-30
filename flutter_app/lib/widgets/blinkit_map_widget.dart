import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class BlinkitMapWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String locationTitle;
  final String fullAddress;
  final Function(double lat, double lng) onPinDragEnd;

  const BlinkitMapWidget({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.locationTitle,
    required this.fullAddress,
    required this.onPinDragEnd,
  });

  @override
  State<BlinkitMapWidget> createState() => _BlinkitMapWidgetState();
}

class _BlinkitMapWidgetState extends State<BlinkitMapWidget> {
  late MapController _mapController;
  late double _currentLat;
  late double _currentLng;
  bool _isDraggingMap = false;
  Timer? _dragEndTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
  }

  @override
  void didUpdateWidget(covariant BlinkitMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.initialLat != widget.initialLat || oldWidget.initialLng != widget.initialLng) && !_isDraggingMap) {
      _currentLat = widget.initialLat;
      _currentLng = widget.initialLng;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(LatLng(_currentLat, _currentLng), 16.0);
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _dragEndTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentLat = widget.initialLat;
      _currentLng = widget.initialLng;
    });
    try {
      _mapController.move(LatLng(_currentLat, _currentLng), 16.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // REAL ORIGINAL MAP ENGINE (OpenStreetMap Tile Layer)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_currentLat, _currentLng),
                initialZoom: 16.0,
                maxZoom: 19.0,
                minZoom: 3.0,
                onMapReady: () {
                  try {
                    _mapController.move(LatLng(widget.initialLat, widget.initialLng), 16.0);
                  } catch (_) {}
                },
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture && position.center != null) {
                    setState(() {
                      _isDraggingMap = true;
                      _currentLat = position.center!.latitude;
                      _currentLng = position.center!.longitude;
                    });

                    if (_dragEndTimer?.isActive ?? false) _dragEndTimer!.cancel();
                    _dragEndTimer = Timer(const Duration(milliseconds: 350), () {
                      if (!mounted) return;
                      HapticFeedback.selectionClick();
                      setState(() => _isDraggingMap = false);
                      widget.onPinDragEnd(_currentLat, _currentLng);
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.supermarket',
                ),
              ],
            ),

            // Pin Drop Target Shadow
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 42),
                width: 20,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Center Red Pin Indicator (Fixed at Center of Real Map)
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                transform: Matrix4.translationValues(0, _isDraggingMap ? -20 : -10, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.slateDark,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location, color: AppTheme.emeraldPrimary, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _isDraggingMap ? 'Dragging Map...' : 'Order Delivered Here',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.location_on,
                      size: 46,
                      color: AppTheme.errorRed,
                    ),
                  ],
                ),
              ),
            ),

            // Top Left Instruction Badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(235),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, size: 14, color: AppTheme.emeraldPrimary),
                    SizedBox(width: 4),
                    Text(
                      'Drag & zoom real map to set exact door pin 📍',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
                    ),
                  ],
                ),
              ),
            ),

            // Re-center Map Button (Bottom Left)
            Positioned(
              bottom: 12,
              left: 12,
              child: FloatingActionButton.extended(
                heroTag: 'recenter_btn',
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.emeraldPrimary,
                onPressed: _recenterMap,
                icon: const Icon(Icons.center_focus_strong, size: 18),
                label: const Text('Center Pin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                elevation: 3,
              ),
            ),

            // Zoom In / Out Controls (Bottom Right)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.slateDark,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
                    },
                    child: const Icon(Icons.add, size: 20),
                  ),
                  const SizedBox(height: 6),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.slateDark,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
                    },
                    child: const Icon(Icons.remove, size: 20),
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
