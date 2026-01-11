import 'package:emergency_alert/screens/emergency/emergency_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import '../../services/profile_service.dart';
import '../../models/user_profile.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  // static const route = '/register';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _agree = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_agree) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = response.user;
      if (user != null) {
        // Save name and phone to profile table
        final profileService = ProfileService(Supabase.instance.client);
        final profile = UserProfile(
          id: user.id,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        await profileService.upsertCurrentUserProfile(profile);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful. Please check your email if confirmation is required, then login.',
          ),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const EmergencyListScreen(),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unexpected error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final headingColor = isDark ? Colors.white : Colors.black;
    final subheadingColor = isDark ? Colors.white70 : Colors.black54;
    final fieldFillColor = isDark ? Colors.grey[850] : Colors.grey[100];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By Creating A Free Account.',
                    style: TextStyle(fontSize: 16, color: subheadingColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Enter your name',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your name' : null,
                    fillColor: fieldFillColor,
                    iconColor: iconColor,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Enter your E-mail',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : 'Enter a valid email',
                    fillColor: fieldFillColor,
                    iconColor: iconColor,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    hint: 'Enter Phone number',
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter phone number' : null,
                    fillColor: fieldFillColor,
                    iconColor: iconColor,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Enter Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : 'Min 6 characters',
                    fillColor: fieldFillColor,
                    iconColor: iconColor,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Theme(
                        data: theme.copyWith(
                          unselectedWidgetColor: isDark ? Colors.white70 : null,
                        ),
                        child: Checkbox(
                          value: _agree,
                          onChanged: (val) {
                            setState(() {
                              _agree = val ?? false;
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          checkColor: isDark ? Colors.black : Colors.white,
                          activeColor: Colors.redAccent,
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'By checking the box you agree to our ',
                              style: TextStyle(color: textColor),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Terms ',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text('and ', style: TextStyle(color: textColor)),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Conditions.',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading || !_agree ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already A Member? ',
                        style: TextStyle(color: textColor),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Color? fillColor,
    Color? iconColor,
    Color? textColor,
    Color? borderColor,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor?.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor ?? Colors.transparent,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: borderColor ?? Colors.transparent,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
