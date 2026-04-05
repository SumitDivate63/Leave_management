import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> leaveData;
  final String docId;

  const LeaveDetailsScreen({super.key, required this.leaveData, required this.docId});

  @override
  State<LeaveDetailsScreen> createState() => _LeaveDetailsScreenState();
}

class _LeaveDetailsScreenState extends State<LeaveDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('leaves').doc(widget.docId).update({
        'status': status,
        'processedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave $status successfully'), backgroundColor: status == 'approved' ? Colors.green : Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _viewFile(String url, String? type) async {
    if (type == 'image' || url.contains('.jpg') || url.contains('.png') || url.contains('.jpeg')) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Proof Image', style: TextStyle(fontSize: 16)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006B91);
    final data = widget.leaveData;
    DateTime from = (data['fromDate'] as Timestamp).toDate();
    DateTime to = (data['toDate'] as Timestamp).toDate();
    String status = data['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Leave Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    child: Text(data['studentName']?[0] ?? "S", 
                         style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['studentName'] ?? "Student", 
                             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('PRN: ${data['prn']}', 
                             style: TextStyle(color: Colors.grey[600])),
                        Text('${data['studentClass']} - Div ${data['studentDiv']}', 
                             style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Request Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 16),

            _buildDetailItem(Icons.category, 'Leave Type', data['leaveType'] ?? 'General'),
            _buildDetailItem(Icons.calendar_today, 'Duration', 
                '${DateFormat('MMM dd, yyyy').format(from)} to ${DateFormat('MMM dd, yyyy').format(to)}'),
            _buildDetailItem(Icons.info_outline, 'Reason', data['reason'] ?? 'No reason provided', isLongText: true),
            
            const SizedBox(height: 24),
            const Text('Attachments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 12),
            
            if (data['fileUrl'] != null)
              InkWell(
                onTap: () => _viewFile(data['fileUrl'], data['fileType']),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blue[50],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: primaryColor),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('View Attached Proof', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
                      const Icon(Icons.open_in_new, size: 18, color: primaryColor),
                    ],
                  ),
                ),
              )
            else
              const Text('No attachments uploaded.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

            const SizedBox(height: 48),

            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => _updateStatus('rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _updateStatus('approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isProcessing 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Approve Leave', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: isLongText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF006B91)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: isLongText ? FontWeight.normal : FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
