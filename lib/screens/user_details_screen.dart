import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userId;
  UserDetailsScreen({required this.userId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserAttendanceHistoryScreen(userId: userId),
                ),
              );
            },
            icon: const Icon(Icons.history),
            tooltip: "View Attendance History",
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget("Error: ${snapshot.error}");
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorWidget("User not found");
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(userData),
                _buildDetailsSection(userData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blueAccent.withOpacity(0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              userData['name']?.substring(0, 1) ?? 'U',
              style: const TextStyle(fontSize: 40, color: Colors.blueAccent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userData['name'] ?? 'Unknown User',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userData['department'] ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(Map<String, dynamic> userData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Details",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),
          ...userData.entries.map((entry) => _userDetailCard(
            capitalizeFirstLetter(entry.key),
            entry.value.toString(),
            icon: _getIconForKey(entry.key),
          )).toList(),
        ],
      ),
    );
  }

  Widget _userDetailCard(String title, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon ?? Icons.info_outline, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  IconData _getIconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'name': return Icons.person;
      case 'department': return Icons.work;
      case 'rollno': return Icons.badge;
      default: return Icons.info_outline;
    }
  }
}

class UserAttendanceHistoryScreen extends StatelessWidget {
  final String userId;
  UserAttendanceHistoryScreen({required this.userId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('attendance')
            .doc(userId)
            .collection('records')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget("Error: ${snapshot.error}");
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildErrorWidget("No attendance records found");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var record = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildAttendanceCard(record);
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
        title: Text(
          record['date'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.login, "Login", record['loginTime'] ?? 'Not logged in'),
                _buildInfoRow(Icons.logout, "Logout", record['logoutTime'] ?? 'Not logged out'),
                _buildInfoRow(Icons.timer, "Hours Worked", record['totalHoursWorked'] ?? '--'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}