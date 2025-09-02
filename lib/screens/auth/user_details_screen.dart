import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../constants/app_theme.dart';
import '../home/home_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final bool isNewUser;

  const UserDetailsScreen({
    super.key,
    this.isNewUser = true,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();
  final _upiIdController = TextEditingController();

  String? _selectedGender;
  bool _upiVisible = true;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      // If user already has these fields, populate them
      final userData = user.additionalData;
      if (userData != null) {
        _usernameController.text = userData['username'] ?? '';
        _ageController.text = userData['age']?.toString() ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _occupationController.text = userData['occupation'] ?? '';
        _selectedGender = userData['gender'];
      }

      // Set UPI ID if available
      if (user.upiId != null && user.upiId!.isNotEmpty) {
        _upiIdController.text = user.upiId!;
        _upiVisible = user.upiVisible;
      }
    }
  }

  Future<void> _saveUserDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.userModel;

        if (user != null) {
          // Create a map of additional data
          final Map<String, dynamic> additionalData = {
            'username': _usernameController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()) ?? 0,
            'phone': _phoneController.text.trim(),
            'occupation': _occupationController.text.trim(),
            'gender': _selectedGender,
          };

          // Get UPI ID
          final String upiId = _upiIdController.text.trim();

          // Update the user model with additional data and UPI ID
          final updatedUser = user.copyWith(
            additionalData: additionalData,
            upiId: upiId,
            upiVisible: _upiVisible,
          );

          final success = await authProvider.updateProfile(updatedUser);

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.error ?? 'Failed to save user details'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile details saved successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );

              // Navigate to home screen if this is a new user
              if (widget.isNewUser && mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              } else if (mounted) {
                Navigator.of(context).pop();
              }
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !widget.isNewUser,
      child: Scaffold(
        appBar: widget.isNewUser ? null : AppBar(
          title: const Text('Edit Profile Details'),
        ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isNewUser) ...[
                      // App Icon
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
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),

                      Text(
                        'Complete Your Profile',
                        style: AppTheme.headingStyle.copyWith(
                          fontSize: 28,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.smallSpacing),
                      Text(
                        'Please provide the required details to complete your registration.',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.extraLargeSpacing),
                    ],

                    // Username field (mandatory for new users)
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: widget.isNewUser ? 'Username *' : 'Username',
                        prefixIcon: const Icon(Icons.person),
                        hintText: 'Choose a username',
                        helperText: 'Username must be unique and 3-20 characters long',
                      ),
                      validator: (value) {
                        if (widget.isNewUser && (value == null || value.isEmpty)) {
                          return 'Please enter a username';
                        }
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (value.length > 20) {
                            return 'Username must be less than 20 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Username can only contain letters, numbers, and underscores';
                          }
                          if (value.startsWith('_') || value.endsWith('_')) {
                            return 'Username cannot start or end with underscore';
                          }
                          if (value.contains('__')) {
                            return 'Username cannot contain consecutive underscores';
                          }
                          // Check for reserved usernames
                          final reservedUsernames = [
                            'admin', 'administrator', 'root', 'system', 'user', 'guest',
                            'support', 'help', 'info', 'contact', 'about', 'privacy',
                            'terms', 'api', 'www', 'mail', 'email', 'ftp', 'blog',
                            'mujjarfunds', 'mujjar', 'funds', 'expense', 'budget'
                          ];
                          if (reservedUsernames.contains(value.toLowerCase())) {
                            return 'This username is reserved and cannot be used';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Age field (mandatory for new users)
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: widget.isNewUser ? 'Age *' : 'Age',
                        prefixIcon: const Icon(Icons.calendar_today),
                        hintText: 'Enter your age',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (widget.isNewUser && (value == null || value.isEmpty)) {
                          return 'Please enter your age';
                        }
                        if (value != null && value.isNotEmpty) {
                          final age = int.tryParse(value);
                          if (age == null) {
                            return 'Please enter a valid number';
                          }
                          if (age < 13) {
                            return 'You must be at least 13 years old';
                          }
                          if (age > 120) {
                            return 'Please enter a valid age';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Gender dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.people),
                        hintText: 'Select your gender',
                      ),
                      items: _genderOptions.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        hintText: 'Enter your phone number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Occupation field
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation',
                        prefixIcon: Icon(Icons.work),
                        hintText: 'Enter your occupation',
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // UPI ID field
                    TextFormField(
                      controller: _upiIdController,
                      decoration: const InputDecoration(
                        labelText: 'UPI ID',
                        prefixIcon: Icon(Icons.payment),
                        hintText: 'Enter your UPI ID (e.g., 9876543210@upi)',
                      ),
                      validator: (value) {
                        if (widget.isNewUser && (value == null || value.isEmpty)) {
                          return 'Please enter your UPI ID for payments';
                        }
                        if (value != null && value.isNotEmpty && !value.contains('@')) {
                          return 'Please enter a valid UPI ID (e.g., 9876543210@upi)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),

                    // UPI Visibility toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _upiVisible,
                          onChanged: (value) {
                            setState(() {
                              _upiVisible = value ?? true;
                            });
                          },
                        ),
                        const Text('Make my UPI ID visible to friends'),
                      ],
                    ),
                    const SizedBox(height: AppTheme.largeSpacing),

                    // Save button with modern styling
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
                        onPressed: _isLoading ? null : _saveUserDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                widget.isNewUser ? 'Complete Registration' : 'Save Changes',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // Note for new users
                    if (widget.isNewUser) ...[
                      const SizedBox(height: AppTheme.mediumSpacing),
                      Text(
                        'All fields marked with * are required to complete your registration.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
