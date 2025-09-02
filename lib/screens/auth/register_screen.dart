import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../constants/app_theme.dart';
import 'user_details_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!success && mounted) {
        final error = authProvider.error ?? '';
        String errorMessage;

        // Handle specific error codes from AuthProvider
        switch (error) {
          case 'EMAIL_ALREADY_EXISTS':
            errorMessage = 'An account with this email already exists. Please use a different email or try logging in.';
            break;
          case 'WEAK_PASSWORD':
            errorMessage = 'Password is too weak. Please choose a stronger password.';
            break;
          case 'INVALID_EMAIL':
            errorMessage = 'Invalid email format. Please enter a valid email address.';
            break;
          case 'NETWORK_ERROR':
            errorMessage = 'Internet issue. Please check your connection and try again.';
            break;
          case 'DATABASE_ERROR':
            errorMessage = 'Database error. Please try again or contact support if the problem persists.';
            break;
          default:
            errorMessage = error.startsWith('REGISTRATION_ERROR:') ? error.substring(19) : 'Registration failed. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please complete your profile.'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Attempt to sign in with the newly registered credentials
        final signInSuccess = await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (signInSuccess && mounted) {
          // Navigate to user details screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserDetailsScreen(isNewUser: true),
            ),
          );
        } else if (mounted) {
          // If auto sign-in fails, go back to login screen
          Navigator.pop(context);
        }
      }
    }
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
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),

                    // App Logo or Icon with shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withAlpha(76),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: size.width * 0.2,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Title
                    Text(
                      'Create Account',
                      style: AppTheme.headingStyle.copyWith(
                        fontSize: 28,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.extraLargeSpacing),
                    // Name Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: Validators.validateName,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          suffixIcon: IconButton(
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
                        ),
                        obscureText: _obscurePassword,
                        validator: Validators.validatePassword,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Confirm Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.largeSpacing),

                    // Register Button with shadow
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
                        onPressed: authProvider.isLoading ? null : _register,
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
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.largeSpacing),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                          child: const Text(
                            'Login',
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
