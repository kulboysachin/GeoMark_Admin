import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child("user_locations");
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Marker> _userMarkers = [];
  LatLng _mapCenter = LatLng(20.5937, 78.9629);
  LatLng? _workLocation;
  double _workRadius = 500;
  double _currentZoom = 14.0;
  final double _minRadius = 10;
  final double _maxRadius = 10000;

  late final MapController _mapController;

  final List<Color> _markerColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.red,
    Colors.yellow
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchWorkLocation();
    _fetchUserLocations();
  }

  void _fetchWorkLocation() {
    _firestore.collection("settings").doc("work_location").get().then((doc) {
      if (doc.exists) {
        double lat = (doc["latitude"] as num?)?.toDouble() ?? 0.0;
        double lng = (doc["longitude"] as num?)?.toDouble() ?? 0.0;
        setState(() {
          _workLocation = LatLng(lat, lng);
          if (_userMarkers.isEmpty) {
            _mapCenter = LatLng(lat, lng);
            _mapController.move(_mapCenter, _currentZoom);
          }
        });
      }
    });

    _firestore.collection("settings").doc("work_radius").get().then((doc) {
      if (doc.exists) {
        double radius = (doc["radius"] as num?)?.toDouble() ?? 500.0;
        setState(() {
          _workRadius = radius;
        });
      }
    });
  }

  void _fetchUserLocations() {
    _dbRef.onValue.listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        List<Marker> markers = [];
        int colorIndex = 0;

        for (var userId in data.keys) {
          var userData = data[userId];
          double lat = (userData["latitude"] as num?)?.toDouble() ?? 0.0;
          double lng = (userData["longitude"] as num?)?.toDouble() ?? 0.0;

          if (lat == 0.0 || lng == 0.0) continue;

          bool isWithinRadius = _workLocation != null
              ? Distance().as(
                  LengthUnit.Meter,
                  _workLocation!,
                  LatLng(lat, lng),
                ) <= _workRadius
              : false;

          String userName = "User";
          try {
            DocumentSnapshot userDoc =
                await _firestore.collection("users").doc(userId).get();
            if (userDoc.exists) {
              userName = userDoc["name"] ?? "User";
            }
          } catch (e) {
            debugPrint("Error fetching user name: $e");
          }

          Color markerColor = _markerColors[colorIndex % _markerColors.length];
          colorIndex++;

          markers.add(
            Marker(
              width: 140,
              height: 90,
              point: LatLng(lat, lng),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isWithinRadius
                            ? Colors.black.withOpacity(0.7)
                            : Colors.grey.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.person_pin_circle,
                    color: isWithinRadius ? markerColor : Colors.grey,
                    size: 36,
                  ),
                ],
              ),
            ),
          );

          if (markers.length == 1 && _workLocation == null) {
            _mapCenter = LatLng(lat, lng);
            _mapController.move(_mapCenter, _currentZoom);
          }
        }

        setState(() {
          _userMarkers = markers;
        });
      }
    });
  }

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1).clamp(5.0, 18.0);
    _mapController.move(_mapCenter, _currentZoom);
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1).clamp(5.0, 18.0);
    _mapController.move(_mapCenter, _currentZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Locations"),
        actions: [
          if (_workLocation != null)
            IconButton(
              icon: Icon(Icons.my_location),
              onPressed: () {
                _mapController.move(_workLocation!, _currentZoom);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _currentZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              if (_workLocation != null) ...[
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _workLocation!,
                      color: Colors.blue.withOpacity(0.1),
                      borderColor: Colors.blue.withOpacity(0.5),
                      borderStrokeWidth: 1,
                      radius: _workRadius,
                      useRadiusInMeter: true,
                    ),
                    CircleMarker(
                      point: _workLocation!,
                      color: Colors.transparent,
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                      radius: _workRadius,
                      useRadiusInMeter: true,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _workLocation!,
                      width: 100,
                      height: 50,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 100,
                          maxHeight: 50,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Work Location",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.location_city,
                              color: Colors.red,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              MarkerLayer(markers: _userMarkers),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomIn,
                  child: Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomOut,
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
          if (_workLocation != null)
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Work Radius: ${_workRadius.round()}m',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 200,
                      height: 40,
                      child: Slider(
                        value: _workRadius,
                        min: _minRadius,
                        max: _maxRadius,
                        divisions: 19,
                        label: _workRadius.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _workRadius = value;
                          });
                        },
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