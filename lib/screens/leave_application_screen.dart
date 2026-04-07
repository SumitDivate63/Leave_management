import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/google_drive_service.dart';
import '../services/leave_service.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final GoogleDriveService _driveService = GoogleDriveService();
  
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedLeaveType;
  bool _isLoading = false;
  File? _selectedFile;
  String? _fileName;

  final List<String> _leaveTypes = ['Medical', 'Personal', 'Academic', 'Event', 'Sports'];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedLeaveType == null || _fromDate == null || _toDate == null || !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('To Date cannot be before From Date'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception("User profile not found");

      // Feature 2: Find Approver
      String? approverId = await LeaveService.findApproverId(_selectedLeaveType!);

      String? fileUrl;
      String? fileType;

      if (_selectedFile != null) {
        // UPLOAD TO GOOGLE DRIVE
        fileUrl = await _driveService.uploadFile(_selectedFile!);
        if (fileUrl == null) {
          throw Exception("Google Drive upload failed. Please check folder permissions.");
        }
        
        String ext = _fileName!.toLowerCase();
        fileType = ext.endsWith('.pdf') ? 'pdf' : 'image';
      }

      await FirebaseFirestore.instance.collection(LeaveService.collectionName).add({
        'studentUid': user.uid,
        'studentName': userDoc.get('name') ?? "Unknown",
        'prn': userDoc.get('prn') ?? "---",
        'studentClass': userDoc.get('class') ?? "N/A",
        'studentDiv': userDoc.get('division') ?? "N/A",
        'leaveType': _selectedLeaveType,
        'fromDate': Timestamp.fromDate(_fromDate!),
        'toDate': Timestamp.fromDate(_toDate!),
        'reason': _reasonController.text.trim(),
        'fileUrl': fileUrl,
        'fileType': fileType,
        'status': 'pending',
        'approverId': approverId, // Assigned approver
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application Submitted Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);

    } catch (e) {
      debugPrint('SUBMIT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
          ? (_fromDate ?? now) 
          : (_toDate ?? (_fromDate ?? now)),
      // Allow any date for From Date (past or future)
      firstDate: isFromDate ? DateTime(2000) : (_fromDate ?? now),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _fromDateController.text = DateFormat('MM/dd/yyyy').format(picked);
          
          // If toDate is now before the new fromDate, reset it
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = _fromDate;
            _toDateController.text = DateFormat('MM/dd/yyyy').format(_toDate!);
          }
        } else {
          _toDate = picked;
          _toDateController.text = DateFormat('MM/dd/yyyy').format(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006B91);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Apply for Leave'), foregroundColor: primaryColor, backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Leave Portal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              const Text('Leave Type', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                value: _selectedLeaveType,
                items: _leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedLeaveType = val),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildDateField('From Date', _fromDateController, () => _selectDate(context, true))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateField('To Date', _toDateController, () => _selectDate(context, false))),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Attach Proof (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_fileName ?? 'Upload PDF or Image', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? 'Reason required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, VoidCallback onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextFormField(controller: controller, readOnly: true, onTap: onTap, decoration: InputDecoration(hintText: 'mm/dd/yyyy', suffixIcon: const Icon(Icons.calendar_today), filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    ]);
  }
}
