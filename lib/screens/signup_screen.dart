import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pending_approval_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _prnController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // New Controllers for Student Details
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _divisionController = TextEditingController();
  
  String _selectedRole = 'Student';
  String _selectedFacultyType = 'Class Teacher';
  bool _isLoading = false;

  final List<String> _facultyTypes = [
    'Sports Faculty',
    'Event Faculty',
    'Academic Faculty',
    'Class Teacher'
  ];
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Prepare data
      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'prn': _prnController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole.toLowerCase(),
        'isApproved': _selectedRole == 'Student' ? true : false, // Faculty needs approval
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add Class and Division if student
      if (_selectedRole == 'Student') {
        userData['class'] = _classController.text.trim().toUpperCase();
        userData['division'] = _divisionController.text.trim().toUpperCase();
      } else if (_selectedRole == 'Faculty') {
        userData['facultyType'] = _selectedFacultyType.toLowerCase().replaceAll(' ', '_');
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      if (!mounted) return;
      
      if (_selectedRole == 'Faculty') {
        _showSuccessDialog();
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/student_dashboard', 
          (route) => false
        );
      }

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'An error occurred.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text('Success!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your faculty registration request has been submitted successfully. Please wait for the admin to approve your account.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B91),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to Login', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF006B91);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.auto_stories, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primaryColor)),
                const Text('Sign up to continue', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 32),
                
                // Role Selection
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      _buildRoleButton('Student'),
                      _buildRoleButton('Faculty'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(label: 'Full Name', controller: _nameController, icon: Icons.person_outline, hint: 'e.g. Awantika Patil'),
                const SizedBox(height: 20),
                
                _buildTextField(label: _selectedRole == 'Student' ? 'PRN Number' : 'Staff ID', controller: _prnController, icon: Icons.badge_outlined, hint: _selectedRole == 'Student' ? 'e.g. 2303065' : 'e.g. EN1'),
                const SizedBox(height: 20),

                // Show Class and Division only for Students
                if (_selectedRole == 'Student') ...[
                  Row(
                    children: [
                      Expanded(child: _buildTextField(label: 'Class', controller: _classController, icon: Icons.school_outlined, hint: 'e.g. TY')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(label: 'Division', controller: _divisionController, icon: Icons.grid_view, hint: 'e.g. A')),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                if (_selectedRole == 'Faculty') ...[
                  const Text('Faculty Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      prefixIcon: const Icon(Icons.assignment_ind_outlined),
                    ),
                    value: _selectedFacultyType,
                    items: _facultyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _selectedFacultyType = val!),
                  ),
                  const SizedBox(height: 20),
                ],

                _buildTextField(label: 'Email', controller: _emailController, icon: Icons.mail_outline, hint: 'email@example.com', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),

                _buildTextField(label: 'Password', controller: _passwordController, icon: Icons.lock_outline, hint: '••••••••', isPassword: true, obscureText: _obscurePassword, onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword)),
                const SizedBox(height: 20),

                _buildTextField(label: 'Confirm Password', controller: _confirmPasswordController, icon: Icons.lock_reset, hint: '••••••••', isPassword: true, obscureText: _obscureConfirmPassword, onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(onTap: () => Navigator.pop(context), child: const Text('Login', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(role, style: TextStyle(color: isSelected ? const Color(0xFF006B91) : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon, required String hint, bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: (val) => val!.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility), onPressed: onToggleVisibility) : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
