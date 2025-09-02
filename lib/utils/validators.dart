class Validators {
  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  // Validate amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Enter a valid amount';
    }

    if (doubleValue <= 0) {
      return 'Amount must be greater than zero';
    }

    return null;
  }

  // Validate description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }

    if (value.length < 3) {
      return 'Description must be at least 3 characters';
    }

    return null;
  }

  // Validate category
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category is required';
    }

    return null;
  }

  // Validate date
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }

    return null;
  }

  // Validate budget
  static String? validateBudget(String? value) {
    if (value == null || value.isEmpty) {
      return 'Budget amount is required';
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Enter a valid budget amount';
    }

    if (doubleValue <= 0) {
      return 'Budget amount must be greater than zero';
    }

    return null;
  }

  // Validate threshold
  static String? validateThreshold(String? value) {
    if (value == null || value.isEmpty) {
      return 'Threshold is required';
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Enter a valid threshold';
    }

    if (doubleValue < 0 || doubleValue > 100) {
      return 'Threshold must be between 0 and 100';
    }

    return null;
  }

  // Validate trust score
  static String? validateTrustScore(String? value) {
    if (value == null || value.isEmpty) {
      return 'Trust score is required';
    }

    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Enter a valid trust score';
    }

    if (doubleValue < 0 || doubleValue > 100) {
      return 'Trust score must be between 0 and 100';
    }

    return null;
  }

  // Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

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
      'trakex', 'trak', 'ex', 'expense', 'budget', 'tracker'
    ];

    if (reservedUsernames.contains(value.toLowerCase())) {
      return 'This username is reserved and cannot be used';
    }

    return null;
  }

  // Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number must be less than 15 digits';
    }

    return null;
  }

  // Validate age
  static String? validateAge(String? value, {bool isRequired = false}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Age is required' : null;
    }

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

    return null;
  }
}
