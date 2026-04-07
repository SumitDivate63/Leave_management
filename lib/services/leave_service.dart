import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveService {
  static const String collectionName = 'leave_requests';

  static final List<String> leaveTypes = [
    'Medical',
    'Personal',
    'Academic',
    'Event',
    'Sports'
  ];

  static String getFacultyTypeForLeave(String leaveType) {
    switch (leaveType) {
      case 'Medical':
      case 'Personal':
        return 'class_teacher';
      case 'Academic':
        return 'academic_faculty';
      case 'Event':
        return 'event_faculty';
      case 'Sports':
        return 'sports_faculty';
      default:
        return 'class_teacher';
    }
  }

  static Future<String?> findApproverId(String leaveType) async {
    String facultyType = getFacultyTypeForLeave(leaveType);
    
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'faculty')
        .where('facultyType', isEqualTo: facultyType)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    return null;
  }
}
