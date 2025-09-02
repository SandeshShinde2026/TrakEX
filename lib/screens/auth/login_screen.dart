import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../constants/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    final error = Validators.validateEmail(value);
    setState(() {
      _emailError = error;
      _isEmailValid = error == null;
    });
  }

  void _validatePassword(String value) {
    final error = Validators.validatePassword(value);
    setState(() {
      _passwordError = error;
      _isPasswordValid = error == null;
    });
  }

  Future<void> _login() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      debugPrint('LoginScreen: Attempting login with email: ${_emailController.text.trim()}');

      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      debugPrint('LoginScreen: Login success: $success');
      debugPrint('LoginScreen: Auth error: ${authProvider.error}');

      if (!success && mounted) {
        final error = authProvider.error ?? '';

        // Handle specific error codes from AuthProvider
        switch (error) {
          case 'USER_NOT_FOUND':
            setState(() {
              _emailError = 'No account found with this email';
              _passwordError = null;
            });
            break;
          case 'WRONG_PASSWORD':
            setState(() {
              _emailError = null;
              _passwordError = 'Wrong password';
            });
            break;
          case 'INVALID_EMAIL':
            setState(() {
              _emailError = 'Invalid email format';
              _passwordError = null;
            });
            break;
          case 'USER_DISABLED':
            _showErrorDialog(
              'Account Disabled',
              'Your account has been disabled. Please contact support for assistance.'
            );
            break;
          case 'TOO_MANY_REQUESTS':
            _showErrorDialog(
              'Too Many Attempts',
              'Too many failed login attempts. Please try again later or reset your password.'
            );
            break;
          case 'NETWORK_ERROR':
            _showErrorDialog(
              'Internet Issue',
              'Please check your internet connection and try again.'
            );
            break;
          case 'DATABASE_ERROR':
            _showErrorDialog(
              'Database Error',
              'There was an issue accessing the database. Please try again or contact support if the problem persists.'
            );
            break;
          default:
            _showErrorDialog(
              'Login Failed',
              error.startsWith('UNKNOWN_ERROR:') ? error.substring(14) : 'An unexpected error occurred. Please try again.'
            );
        }
      } else if (success) {
        debugPrint('LoginScreen: Login successful, user should be redirected');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1F1F1F), Color(0xFF121212)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF5F5F5), Colors.white],
                  ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo with better background and shadow
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2C2C2C), // Dark gray
                            const Color(0xFF1A1A1A), // Darker gray
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withAlpha(76),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icons/TrakEX Logo Transparent.png',
                        width: size.width * 0.35,
                        height: size.width * 0.35,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppTheme.extraLargeSpacing),

                    // Email Field with validation
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          errorText: _emailError,
                          suffixIcon: _isEmailValid
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                        onChanged: _validateEmail,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Password Field with validation
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          errorText: _passwordError,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isPasswordValid)
                                const Icon(Icons.check_circle, color: Colors.green),
                              IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: Validators.validatePassword,
                        onChanged: _validatePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Login Button with shadow
                    Container(
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withAlpha(76),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.largeSpacing),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
