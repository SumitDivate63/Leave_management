import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/leave_status_card.dart';
import '../widgets/leave_history_tile.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = "Loading...";
  String userEmail = "";
  String userPRN = "---";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          userName = userDoc.get('name') ?? "No Name";
          userEmail = userDoc.get('email') ?? "";
          userPRN = userDoc.get('prn') ?? "---";
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showLeavesDialog(String statusFilter) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${statusFilter[0].toUpperCase()}${statusFilter.substring(1)} Leaves', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaves')
                  .where('studentUid', isEqualTo: user?.uid)
                  .where('status', isEqualTo: statusFilter)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No leaves found.');

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    DateTime from = (data['fromDate'] as Timestamp).toDate();
                    DateTime appliedAt = (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                    
                    return ListTile(
                      title: Text(data['leaveType'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Applied on: ${DateFormat('MMM dd, yyyy').format(appliedAt)}'),
                      trailing: Text(DateFormat('MMM dd').format(from), style: const TextStyle(color: Colors.blue)),
                    );
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF006B91);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Student Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35, backgroundColor: primaryColor,
                    child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('PRN: $userPRN', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(context, Icons.edit_document, 'Apply Leave', '/leave_application'),
                _buildActionButton(context, Icons.person_outline, 'My Profile', '/profile'),
                _buildActionButton(context, Icons.lock_outline, 'Password', '/change_password'),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Leave Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaves')
                  .where('studentUid', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int pending = 0; int approved = 0; int rejected = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    String status = doc.get('status').toString().toLowerCase();
                    if (status == 'pending') pending++;
                    else if (status == 'approved') approved++;
                    else if (status == 'rejected') rejected++;
                  }
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LeaveStatusCard(title: 'Pending', count: pending.toString().padLeft(2, '0'), color: Colors.orange, onTap: () => _showLeavesDialog('pending')),
                    LeaveStatusCard(title: 'Approved', count: approved.toString().padLeft(2, '0'), color: Colors.green, onTap: () => _showLeavesDialog('approved')),
                    LeaveStatusCard(title: 'Rejected', count: rejected.toString().padLeft(2, '0'), color: Colors.red, onTap: () => _showLeavesDialog('rejected')),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('Recent Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('leaves')
                  .where('studentUid', isEqualTo: user?.uid)
                  .orderBy('appliedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No recent leave requests found.', style: TextStyle(color: Colors.grey))));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    String status = data['status'];
                    DateTime fromDate = (data['fromDate'] as Timestamp).toDate();
                    DateTime toDate = (data['toDate'] as Timestamp).toDate();
                    String dateRange = "${DateFormat('MMM dd').format(fromDate)} - ${DateFormat('MMM dd').format(toDate)}";
                    return LeaveHistoryTile(
                      leaveType: data['leaveType'],
                      date: dateRange,
                      status: status.toUpperCase(),
                      statusColor: _getStatusColor(status),
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

  Widget _buildActionButton(BuildContext context, IconData icon, String label, String? route) {
    return GestureDetector(
      onTap: () { if (route != null) Navigator.pushNamed(context, route); },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(icon, color: const Color(0xFF006B91), size: 30),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
