import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = "Loading...";
  String staffID = "---";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc.get('name') ?? "No Name";
          staffID = userDoc.get('prn') ?? "---";
        });
      }
    }
  }

  Future<void> _updateLeaveStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
      'status': newStatus,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Leave $newStatus'), backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF006B91);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Faculty Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card (Matches your screenshot)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: primaryColor,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : "?",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Staff ID: $staffID', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Pending Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Live Stream of Pending Leaves
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaves')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No pending requests', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    DateTime from = (data['fromDate'] as Timestamp).toDate();
                    DateTime to = (data['toDate'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(child: Text(data['studentName'][0])),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['studentName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('PRN: ${data['prn']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                const Spacer(),
                                Chip(label: Text(data['leaveType']), backgroundColor: primaryColor.withOpacity(0.1)),
                              ],
                            ),
                            const Divider(),
                            Text('Duration: ${DateFormat('MMM dd').format(from)} - ${DateFormat('MMM dd').format(to)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Reason: ${data['reason']}', style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateLeaveStatus(data.id, 'rejected'),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateLeaveStatus(data.id, 'approved'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
