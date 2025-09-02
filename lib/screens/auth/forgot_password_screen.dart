import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../constants/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPassword(
        _emailController.text.trim(),
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Password reset failed'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } else if (mounted) {
        setState(() {
          _resetSent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.mediumSpacing),
            child: _resetSent ? _buildSuccessMessage() : _buildResetForm(authProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: AppTheme.mediumSpacing),
          
          const Text(
            'Forgot your password?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.smallSpacing),
          
          const Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.largeSpacing),
          
          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
          ),
          const SizedBox(height: AppTheme.largeSpacing),
          
          // Reset Button
          ElevatedButton(
            onPressed: authProvider.isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: AppTheme.successColor,
        ),
        const SizedBox(height: AppTheme.mediumSpacing),
        
        const Text(
          'Reset Link Sent!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.smallSpacing),
        
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}. Please check your email and follow the instructions to reset your password.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.largeSpacing),
        
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}
