import 'package:flutter/material.dart';
import 'package:cmit/config/routes.dart';
import 'package:cmit/features/auth/model/login_model.dart';
import 'package:cmit/features/auth/presenter/auth_presenter.dart';
import 'package:cmit/config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthPresenter _authPresenter = AuthPresenter();

  bool _isEmailLogin = true;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ✅ Handle Login with AuthPresenter
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final loginModel = LoginModel(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        isEmailLogin: _isEmailLogin,
      );

      final response = await _authPresenter.login(
        loginModel,
        rememberMe: _rememberMe,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (response['success'] == true) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.home,
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Login successful!"),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Login failed. Please try again."),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access current theme
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.white, // Explicit Pure White
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo with subtle glow or improved spacing
                Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/splash/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Welcome Text
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to continue to your workspace",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // Toggle Buttons (Email / CNIC)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6), // Modern Light Grey
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildToggleButton("Email", Icons.alternate_email_rounded, true)),
                      Expanded(child: _buildToggleButton("CNIC", Icons.badge_rounded, false)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildModernTextField(
                        controller: _emailController,
                        label: _isEmailLogin ? "Email Address" : "CNIC Number",
                        hint: _isEmailLogin ? "name@company.com" : "12345-1234567-1",
                        icon: _isEmailLogin ? Icons.email_outlined : Icons.badge_outlined,
                        keyboardType: _isEmailLogin ? TextInputType.emailAddress : TextInputType.number,
                        validator: (value) {
                           if (value == null || value.isEmpty) {
                            return _isEmailLogin
                                ? "Please enter your email"
                                : "Please enter your CNIC";
                          }
                          if (_isEmailLogin && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return "Please enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildModernTextField(
                        controller: _passwordController,
                        label: "Password",
                        hint: "••••••••",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isObscure: _obscurePassword,
                        onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter your password";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            activeColor: AppTheme.primaryColor,
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("Remember me", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Forgot Password feature coming soon!"))
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text("Forgot Password?", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Login Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Sign In",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Footer
                Center(
                  child: Text(
                    "CMIT Mobile v1.0.0",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB), // Very subtle grey
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF3F4F6), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool isEmail) {
    final isSelected = _isEmailLogin == isEmail;
    return GestureDetector(
      onTap: () => setState(() => _isEmailLogin = isEmail),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.textPrimary : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}