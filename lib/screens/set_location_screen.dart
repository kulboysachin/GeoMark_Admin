import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetLocationScreen extends StatefulWidget {
  @override
  _SetLocationScreenState createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  double? _currentLatitude;
  double? _currentLongitude;
  double _workRadius = 500;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _fetchWorkRadius();
  }

  Future<void> _fetchCurrentLocation() async {
    DocumentSnapshot snapshot =
        await _firestore.collection('settings').doc('work_location').get();
    if (snapshot.exists) {
      setState(() {
        _currentLatitude = snapshot['latitude'];
        _currentLongitude = snapshot['longitude'];
        _latitudeController.text = _currentLatitude.toString();
        _longitudeController.text = _currentLongitude.toString();
      });
    }
  }

  Future<void> _fetchWorkRadius() async {
    DocumentSnapshot snapshot =
        await _firestore.collection('settings').doc('work_radius').get();
    if (snapshot.exists) {
      setState(() {
        _workRadius = snapshot['radius'];
        _radiusController.text = _workRadius.toString();
      });
    }
  }

  Future<void> _saveWorkLocation() async {
    try {
      double latitude = double.parse(_latitudeController.text.trim());
      double longitude = double.parse(_longitudeController.text.trim());

      await _firestore.collection('settings').doc('work_location').set({
        'latitude': latitude,
        'longitude': longitude,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Work location updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating work location: $e")),
      );
    }
  }

  Future<void> _saveWorkRadius() async {
    try {
      double radius = double.parse(_radiusController.text.trim());

      await _firestore.collection('settings').doc('work_radius').set({
        'radius': radius,
      });

      setState(() {
        _workRadius = radius;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Work radius updated to $radius meters")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating work radius: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Set Work Location & Radius"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard("📍 Current Work Location", "Latitude: ${_currentLatitude ?? 'Not set'}\nLongitude: ${_currentLongitude ?? 'Not set'}"),
            SizedBox(height: 20),
            _buildInputCard("🌎 Update Work Location", _latitudeController, _longitudeController, _saveWorkLocation),
            SizedBox(height: 20),
            _buildInfoCard("📏 Current Work Radius", "Radius: $_workRadius meters"),
            SizedBox(height: 20),
            _buildRadiusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(content, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(String title, TextEditingController latController, TextEditingController longController, Function onSave) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: latController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "New Latitude", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            TextField(
              controller: longController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "New Longitude", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            _buildButton("Update Work Location", onSave),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📏 Update Work Radius", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "New Radius (in meters)", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            _buildButton("Update Work Radius", _saveWorkRadius),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Function onPressed) {
    return ElevatedButton(
      onPressed: () => onPressed(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: TextStyle(fontSize: 16)),
    );
  }
}
