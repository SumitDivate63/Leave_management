import 'package:flutter/material.dart';
import '../widgets/leave_status_card.dart';
import '../widgets/leave_history_tile.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Alex Johnson',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('PRN: 2021BCS0123', style: TextStyle(color: Colors.grey)),
                    Text('3rd Year (Junior)', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(context, Icons.person, 'Profile', '/profile'),
                _buildActionButton(context, Icons.description, 'Apply Leave', '/leave_application'),
                _buildActionButton(context, Icons.lock, 'Password', '/change_password'),
              ],
            ),
            const SizedBox(height: 32),

            // Leave Status
            const Text(
              'Leave Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                LeaveStatusCard(title: 'Pending', count: '02', color: Colors.orange),
                LeaveStatusCard(title: 'Approved', count: '05', color: Colors.green),
                LeaveStatusCard(title: 'Rejected', count: '01', color: Colors.red),
              ],
            ),
            const SizedBox(height: 32),

            // Leave History
            const Text(
              'Leave History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const LeaveHistoryTile(
              leaveType: 'Medical Leave',
              date: 'Dec 01 - Dec 02',
              status: 'PENDING',
              statusColor: Colors.orange,
            ),
            const LeaveHistoryTile(
              leaveType: 'Personal Leave',
              date: 'Nov 12 - Nov 15',
              status: 'APPROVED',
              statusColor: Colors.green,
            ),
            const LeaveHistoryTile(
              leaveType: 'Annual Leave',
              date: 'Aug 10 - Aug 20',
              status: 'APPROVED',
              statusColor: Colors.green,
            ),
            const LeaveHistoryTile(
              leaveType: 'Casual Leave',
              date: 'Jul 05 - Jul 05',
              status: 'REJECTED',
              statusColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, String route) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, route);
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.blue.withOpacity(0.1),
            foregroundColor: Colors.blue,
            elevation: 0,
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
