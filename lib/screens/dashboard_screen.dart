import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../auth_service.dart';
import 'user_details_screen.dart';

// New Attendance History Screen
class UserAttendanceHistoryScreen extends StatelessWidget {
  final String userId;
  UserAttendanceHistoryScreen({required this.userId});

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("attendance");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance History"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.orderByKey().onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No attendance records found"));
          }

          Map<dynamic, dynamic> attendanceData = 
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          
          List<Widget> historyWidgets = [];
          
          attendanceData.forEach((date, users) {
            Map<dynamic, dynamic> userRecords = users as Map<dynamic, dynamic>;
            if (userRecords.containsKey(userId)) {
              var record = userRecords[userId];
              historyWidgets.add(
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(
                      date,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${record['status']}"),
                        Text("Timestamp: ${record['timestamp']}"),
                      ],
                    ),
                  ),
                ),
              );
            }
          });

          return ListView(
            children: historyWidgets.isEmpty 
                ? [const Center(child: Text("No records for this user"))]
                : historyWidgets,
          );
        },
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("attendance");
  final AuthService _authService = AuthService();

  void _logout() async {
    try {
      await _authService.logout();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to logout: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/set_location');
            },
            icon: const Icon(Icons.location_on),
            tooltip: "Set Work Location and Radius",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            var users = snapshot.data!.docs;
            var regularUsers = users
                .where((user) => (user.data() as Map<String, dynamic>)['role'] != 'admin')
                .toList();
            var admins = users
                .where((user) => (user.data() as Map<String, dynamic>)['role'] == 'admin')
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("👨‍💼 Admins"),
                _buildUserGrid(admins, isAdmin: true),
                const SizedBox(height: 20),
                _sectionTitle("👥 Users"),
                Expanded(child: _buildUserList(regularUsers)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUserGrid(List<QueryDocumentSnapshot> users, {bool isAdmin = false}) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        itemBuilder: (context, index) {
          var admin = users[index];
          var adminData = admin.data() as Map<String, dynamic>;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 5,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.blueAccent,
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    adminData['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    adminData['email'] ?? 'No Email',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserList(List<QueryDocumentSnapshot> users) {
    String today = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        var user = users[index];
        var userData = user.data() as Map<String, dynamic>;

        return StreamBuilder(
          stream: _dbRef.child(today).child(user.id).onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            bool isPresent = false;

            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final record = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map,
              );
              if (record['status'] == 'Present') {
                isPresent = true;
              }
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  Icons.circle,
                  color: isPresent ? Colors.green : Colors.red,
                  size: 16,
                ),
                title: Text(
                  userData['name'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Status: ${isPresent ? '✅ Present' : '❌ Absent'}",
                  style: TextStyle(
                    color: isPresent ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text("Details"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailsScreen(userId: user.id),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text("History"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserAttendanceHistoryScreen(userId: user.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}