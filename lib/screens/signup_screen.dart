import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _prnController = TextEditingController(); // Added PRN
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user details including PRN
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'prn': _prnController.text.trim(), // Save PRN
        'email': _emailController.text.trim(),
        'role': _selectedRole.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      Navigator.pushNamedAndRemoveUntil(
        context, 
        _selectedRole == 'Faculty' ? '/faculty_dashboard' : '/student_dashboard', 
        (route) => false
      );

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

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF006B91);

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
                Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primaryColor)),
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
                
                // PRN Field
                _buildTextField(label: 'PRN / ID', controller: _prnController, icon: Icons.badge_outlined, hint: 'e.g. 2021BCS0123'),
                const SizedBox(height: 20),

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
                    GestureDetector(onTap: () => Navigator.pop(context), child: Text('Login', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
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
          validator: (val) => val!.isEmpty ? 'Field required' : null,
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
