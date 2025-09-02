 import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../constants/currency_constants.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../../models/currency_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../utils/validators.dart';
import '../../utils/auth_helper.dart';
import '../../widgets/currency_selector.dart';
import '../../providers/currency_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String? _selectedCategory;
  bool _isCustomCategory = false;
  DateTime _selectedDate = DateTime.now();
  String? _selectedMood;
  bool _isGroupExpense = false;
  List<Map<String, dynamic>> _participants = [];
  final List<File> _selectedImages = [];

  // Currency selection
  CurrencyModel _selectedCurrency = CurrencyConstants.defaultCurrency;

  // Flag to prevent duplicate submissions
  bool _isSubmitting = false;

  // Split type: 'equal' or 'custom'
  String _splitType = 'equal';

  // Selected friends for splitting
  final List<UserModel> _selectedFriends = [];

  // Selected groups for splitting
  final List<GroupModel> _selectedGroups = [];

  // Custom amounts for each friend
  final Map<String, double> _customAmounts = {};

  @override
  void initState() {
    super.initState();
    // Set default category
    _selectedCategory = AppConstants.expenseCategories[0]['name'];

    // Check authentication status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
      _loadFriends();
      _loadGroups();
    });

    // Also load groups when the screen is first built
    _loadGroupsOnInit();
  }

  // Load friends list
  Future<void> _loadFriends() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      await friendProvider.loadFriends(authProvider.userModel!.id);
    }
  }

  // Load groups list
  Future<void> _loadGroups() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      debugPrint('AddExpenseScreen: Loading groups for user: ${authProvider.userModel!.id}');
      await groupProvider.loadUserGroups(authProvider.userModel!.id);
      debugPrint('AddExpenseScreen: Groups loaded: ${groupProvider.groups.length}');
    } else {
      debugPrint('AddExpenseScreen: Cannot load groups - user not authenticated');
    }
  }

  // Load groups on init (with delay to ensure auth is ready)
  Future<void> _loadGroupsOnInit() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      debugPrint('AddExpenseScreen Init: Loading groups for user: ${authProvider.userModel!.id}');
      await groupProvider.loadUserGroups(authProvider.userModel!.id);
      debugPrint('AddExpenseScreen Init: Groups loaded: ${groupProvider.groups.length}');
      if (mounted) {
        setState(() {}); // Force rebuild to show groups
      }
    } else {
      debugPrint('AddExpenseScreen Init: Cannot load groups - user not authenticated');
    }
  }

  Future<void> _checkAuthStatus() async {
    debugPrint('AddExpenseScreen: Checking auth status');

    // Use the AuthHelper to check authentication
    final isAuthenticated = await AuthHelper.checkAuthenticated(context);

    if (isAuthenticated) {
      debugPrint('AddExpenseScreen: User authenticated successfully');
    } else {
      debugPrint('AddExpenseScreen: User not authenticated');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Toggle friend selection
  void _toggleFriendSelection(UserModel friend) {
    setState(() {
      if (_selectedFriends.any((f) => f.id == friend.id)) {
        _selectedFriends.removeWhere((f) => f.id == friend.id);
        _customAmounts.remove(friend.id);
      } else {
        _selectedFriends.add(friend);
        // Initialize custom amount to equal split
        if (_splitType == 'custom') {
          final totalParticipants = _getTotalParticipants();
          final equalShare = double.parse(_amountController.text) / totalParticipants;
          _customAmounts[friend.id] = equalShare;
        }
      }
      _updateParticipants();
    });
  }

  // Toggle group selection
  void _toggleGroupSelection(GroupModel group) {
    setState(() {
      if (_selectedGroups.any((g) => g.id == group.id)) {
        _selectedGroups.removeWhere((g) => g.id == group.id);
        // Remove custom amounts for group members
        for (final memberId in group.memberIds) {
          _customAmounts.remove(memberId);
        }
      } else {
        _selectedGroups.add(group);
        // Initialize custom amounts for group members
        if (_splitType == 'custom') {
          final totalParticipants = _getTotalParticipants();
          final equalShare = double.parse(_amountController.text) / totalParticipants;
          for (final memberId in group.memberIds) {
            _customAmounts[memberId] = equalShare;
          }
        }
      }
      _updateParticipants();
    });
  }

  // Get total number of participants (including current user)
  int _getTotalParticipants() {
    final Set<String> allParticipants = {};

    // Add current user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userModel != null) {
      allParticipants.add(authProvider.userModel!.id);
    }

    // Add selected friends
    for (final friend in _selectedFriends) {
      allParticipants.add(friend.id);
    }

    // Add group members
    for (final group in _selectedGroups) {
      allParticipants.addAll(group.memberIds);
    }

    return allParticipants.length;
  }

  // Helper method to get member name
  String _getMemberName(String memberId, AuthProvider authProvider, FriendProvider friendProvider) {
    if (memberId == authProvider.userModel?.id) {
      return 'You (${authProvider.userModel?.name ?? 'Unknown'})';
    }

    // Try to find the member in friends list
    try {
      final friend = friendProvider.friends.firstWhere((f) => f.id == memberId);
      return friend.name;
    } catch (e) {
      // If not found in friends, return a placeholder
      return 'Group Member';
    }
  }

  // Update split type
  void _updateSplitType(String type) {
    setState(() {
      _splitType = type;
      _updateParticipants();
    });
  }

  // Update custom amount for a friend
  void _updateCustomAmount(String friendId, double amount) {
    setState(() {
      _customAmounts[friendId] = amount;
      _updateParticipants();
    });
  }

  // Update participants list based on selected friends, groups and split type
  void _updateParticipants() {
    if (!_isGroupExpense || (_selectedFriends.isEmpty && _selectedGroups.isEmpty) || _amountController.text.isEmpty) {
      _participants = [];
      return;
    }

    final totalAmount = double.parse(_amountController.text);
    _participants = [];

    // Get all unique participants
    final Set<String> allParticipantIds = {};
    final Map<String, String> participantNames = {};

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    if (authProvider.userModel != null) {
      final userId = authProvider.userModel!.id;

      // Add current user
      allParticipantIds.add(userId);
      participantNames[userId] = authProvider.userModel!.name;

      // Add selected friends
      for (var friend in _selectedFriends) {
        allParticipantIds.add(friend.id);
        participantNames[friend.id] = friend.name;
      }

      // Add group members
      for (var group in _selectedGroups) {
        for (var memberId in group.memberIds) {
          allParticipantIds.add(memberId);

          // Get member name
          if (memberId == userId) {
            participantNames[memberId] = authProvider.userModel!.name;
          } else {
            final friend = friendProvider.friends.firstWhere(
              (f) => f.id == memberId,
              orElse: () => UserModel(
                id: memberId,
                name: 'Unknown User',
                email: '',
              ),
            );
            participantNames[memberId] = friend.name;
          }
        }
      }

      if (_splitType == 'equal') {
        // Equal split among all participants
        final equalShare = totalAmount / allParticipantIds.length;

        for (var participantId in allParticipantIds) {
          _participants.add({
            'userId': participantId,
            'name': participantNames[participantId] ?? 'Unknown',
            'share': equalShare,
            'isPayer': participantId == userId,
          });
        }
      } else {
        // Custom split
        // Calculate how much the current user pays
        double othersTotal = 0;
        for (var participantId in allParticipantIds) {
          if (participantId != userId) {
            othersTotal += _customAmounts[participantId] ?? 0;
          }
        }
        final userShare = totalAmount - othersTotal;

        // Add current user
        _participants.add({
          'userId': userId,
          'name': authProvider.userModel!.name,
          'share': userShare,
          'isPayer': true,
        });

        // Add other participants
        for (var participantId in allParticipantIds) {
          if (participantId != userId) {
            _participants.add({
              'userId': participantId,
              'name': participantNames[participantId] ?? 'Unknown',
              'share': _customAmounts[participantId] ?? 0,
              'isPayer': false,
            });
          }
        }
      }
    }
  }



  Future<void> _saveExpense() async {
    debugPrint('Save expense button pressed');

    // Prevent duplicate submissions
    if (_isSubmitting) {
      debugPrint('Preventing duplicate submission');
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Set flag to prevent duplicate submissions
      setState(() {
        _isSubmitting = true;
      });

      debugPrint('Form validation passed');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);

      debugPrint('AddExpenseScreen: Checking authentication before saving expense');

      // Use the AuthHelper to check authentication
      final isAuthenticated = await AuthHelper.checkAuthenticated(context);

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      // If not authenticated, return early
      if (!isAuthenticated || authProvider.userModel == null) {
        debugPrint('AddExpenseScreen: Error: User not authenticated or user model is null');
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Force refresh the token to ensure it's valid
      await AuthHelper.refreshToken(context);

      debugPrint('AddExpenseScreen: User authenticated, proceeding to save expense');

      final userId = authProvider.userModel!.id;
      final amount = double.parse(_amountController.text);

      // Determine the actual category
      final String category;
      if (_isCustomCategory) {
        // Use custom category name
        category = _customCategoryController.text.trim();
        if (category.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a custom category name'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        // Use selected standard category
        if (_selectedCategory == null || _selectedCategory!.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a category'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        category = _selectedCategory!;
      }

      debugPrint('Creating expense for user: $userId with category: $category');
      // Update participants if it's a group expense
      if (_isGroupExpense) {
        _updateParticipants();
      }

      // Determine groupId if this is a group expense with exactly one group selected
      String? groupId;
      if (_isGroupExpense && _selectedGroups.length == 1) {
        groupId = _selectedGroups.first.id;
      }

      // Get currency conversion data using CurrencyProvider
      double? convertedAmount;
      String? convertedCurrencyCode;
      double? exchangeRate;

      // Convert currency if needed and auto-convert is enabled
      final conversionData = await currencyProvider.convertExpenseAmount(
        amount: amount,
        currencyCode: _selectedCurrency.code,
      );

      if (conversionData != null) {
        convertedAmount = conversionData['convertedAmount'];
        convertedCurrencyCode = conversionData['convertedCurrencyCode'];
        exchangeRate = conversionData['exchangeRate'];
        debugPrint('Currency converted: ${_selectedCurrency.code} $amount -> $convertedCurrencyCode $convertedAmount (rate: $exchangeRate)');
      }

      final expense = ExpenseModel(
        id: '', // Will be set by the service
        userId: userId,
        category: category,
        description: _descriptionController.text,
        amount: amount,
        currencyCode: _selectedCurrency.code,
        convertedAmount: convertedAmount,
        convertedCurrencyCode: convertedCurrencyCode,
        exchangeRate: exchangeRate,
        date: _selectedDate,
        mood: _selectedMood,
        isGroupExpense: _isGroupExpense,
        groupId: groupId,
        participants: _participants,
      );

      debugPrint('Calling expenseProvider.addExpense');

      // Save the expense without passing context
      final success = await expenseProvider.addExpense(
        expense,
        _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      // Check for budget alerts separately if still mounted
      if (success && mounted) {
        // Check if there's a budget alert for this category
        final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
        budgetProvider.showBudgetAlertDialog(context, expense.category);
      }

      if (success && mounted) {
        debugPrint('Expense added successfully');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );

        // Reset submission flag (though we're navigating away)
        setState(() {
          _isSubmitting = false;
        });

        // Pop with a result to indicate success
        // The true value will prevent unnecessary reloading in the expense screen
        Navigator.pop(context, true);
      } else if (mounted) {
        debugPrint('Failed to add expense: ${expenseProvider.error}');

        // Reset submission flag so user can try again
        setState(() {
          _isSubmitting = false;
        });

        // Check if it's a permission error
        if (expenseProvider.error != null &&
            expenseProvider.error!.contains('permission-denied')) {
          // Show a more detailed error message for permission issues
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Firebase Permission Error'),
              content: const Text(
                'Your Firebase security rules are preventing write access to the expenses collection.\n\n'
                'Please go to the Firebase Console and update your Firestore security rules to allow authenticated users to write to the expenses collection.\n\n'
                'Example rule:\n'
                'match /expenses/{expenseId} {\n'
                '  allow read, write: if request.auth != null;\n'
                '}'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Show regular error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(expenseProvider.error ?? 'Failed to add expense'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      debugPrint('Form validation failed');
      // Reset submission flag in case of validation failure
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroupExpense ? 'Add Group Expense' : 'Add Expense'),
        actions: [
          // Temporary debug button to refresh groups
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              if (authProvider.userModel != null) {
                debugPrint('Manual refresh: Loading groups for user: ${authProvider.userModel!.id}');
                await groupProvider.loadUserGroups(authProvider.userModel!.id);
                debugPrint('Manual refresh: Groups loaded: ${groupProvider.groups.length}');
                for (var group in groupProvider.groups) {
                  debugPrint('Group: ${group.name} (${group.memberCount} members)');
                }
              }
            },
          ),
        ],
      ),
      body: expenseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Currency Selection
                    const Text('Currency', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppTheme.smallSpacing),
                    CurrencySelector(
                      selectedCurrency: _selectedCurrency,
                      onCurrencySelected: (currency) {
                        setState(() {
                          _selectedCurrency = currency;
                        });
                      },
                      showPopularOnly: false,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (${_selectedCurrency.symbol})',
                        prefixIcon: Icon(Icons.attach_money),
                        helperText: 'Enter amount in ${_selectedCurrency.name}',
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAmount,
                      onChanged: (value) {
                        // Update participants when amount changes (for custom splits)
                        if (_isGroupExpense && value.isNotEmpty) {
                          _updateParticipants();
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Category Selection
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppTheme.smallSpacing),

                    // Two options: Standard Category or Custom Category
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.list),
                            label: const Text('Standard Category'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isCustomCategory
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Theme.of(context).primaryColor)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300),
                              foregroundColor: !_isCustomCategory
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black87
                                      : Colors.white)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade300
                                      : Colors.black87),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: !_isCustomCategory ? 2 : 0,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCustomCategory = false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Custom Category'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCustomCategory
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Theme.of(context).primaryColor)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade300),
                              foregroundColor: _isCustomCategory
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black87
                                      : Colors.white)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade300
                                      : Colors.black87),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: _isCustomCategory ? 2 : 0,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCustomCategory = true;
                                _selectedCategory = null; // Clear standard category selection
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Show either standard category dropdown or custom category input
                    if (!_isCustomCategory) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        value: _selectedCategory,
                        items: AppConstants.expenseCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['name'],
                            child: Row(
                              children: [
                                Icon(category['icon'], size: 20),
                                const SizedBox(width: 8),
                                Text(category['name']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (!_isCustomCategory && (value == null || value.isEmpty)) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _customCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Custom Category Name',
                          hintText: 'e.g., Vacation, Pet Care, etc.',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (_isCustomCategory && (value == null || value.trim().isEmpty)) {
                            return 'Please enter a custom category name';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: Validators.validateDescription,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat(AppConstants.dateFormat).format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Mood Selection
                    const Text(
                      'How did you feel about this expense?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),

                    Wrap(
                      spacing: AppTheme.smallSpacing,
                      children: AppConstants.moodOptions.map((mood) {
                        final isSelected = _selectedMood == mood['name'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMood = mood['name'];
                            });
                          },
                          child: Chip(
                            avatar: Icon(
                              mood['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            label: Text(mood['name']),
                            backgroundColor: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withAlpha(50),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Group Expense Toggle - More prominent
                    Container(
                      decoration: BoxDecoration(
                        color: _isGroupExpense
                            ? Theme.of(context).primaryColor.withAlpha(30)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                        border: Border.all(
                          color: _isGroupExpense
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Row(
                          children: [
                            Icon(
                              Icons.group,
                              color: _isGroupExpense
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).iconTheme.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Group Expense',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isGroupExpense
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text('Split this expense with friends'),
                        value: _isGroupExpense,
                        onChanged: (value) {
                          setState(() {
                            _isGroupExpense = value;
                            if (!value) {
                              _selectedFriends.clear();
                              _selectedGroups.clear();
                              _customAmounts.clear();
                              _participants.clear();
                            }
                          });
                        },
                      ),
                    ),

                    // Friends selection and split options (only shown when group expense is enabled)
                    if (_isGroupExpense) ...[
                      const SizedBox(height: AppTheme.mediumSpacing),
                      const Text(
                        'Split with Friends',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.smallSpacing),

                      // Split type selection
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Equal Split'),
                              value: 'equal',
                              groupValue: _splitType,
                              onChanged: (value) {
                                if (value != null) {
                                  _updateSplitType(value);
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Custom Split'),
                              value: 'custom',
                              groupValue: _splitType,
                              onChanged: (value) {
                                if (value != null) {
                                  _updateSplitType(value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      // Friends and Groups list
                      Consumer2<FriendProvider, GroupProvider>(
                        builder: (context, friendProvider, groupProvider, child) {
                          debugPrint('AddExpenseScreen UI: Friends: ${friendProvider.friends.length}, Groups: ${groupProvider.groups.length}');
                          debugPrint('AddExpenseScreen UI: Loading states - Friends: ${friendProvider.isLoading}, Groups: ${groupProvider.isLoading}');

                          if (friendProvider.isLoading || groupProvider.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final hasContent = friendProvider.friends.isNotEmpty || groupProvider.groups.isNotEmpty;

                          if (!hasContent) {
                            return const Padding(
                              padding: EdgeInsets.all(AppTheme.mediumSpacing),
                              child: Text('No friends or groups found. Add friends and create groups to split expenses.'),
                            );
                          }

                          return Column(
                            children: [
                              // Groups Section
                              if (groupProvider.groups.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppTheme.smallSpacing),
                                  child: Row(
                                    children: [
                                      Icon(Icons.group, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Groups',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                for (var group in groupProvider.groups)
                                  Builder(
                                    builder: (context) {
                                      final isSelected = _selectedGroups.any((g) => g.id == group.id);

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                                        child: CheckboxListTile(
                                          value: isSelected,
                                          onChanged: (_) => _toggleGroupSelection(group),
                                          title: Text(group.name),
                                          subtitle: Text('${group.memberCount} members'),
                                          secondary: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.group,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  ),

                                const SizedBox(height: AppTheme.mediumSpacing),
                              ],

                              // Group Members Custom Split Section (only shown when custom split is selected and groups are selected)
                              if (_splitType == 'custom' && _selectedGroups.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppTheme.smallSpacing),
                                  child: Row(
                                    children: [
                                      Icon(Icons.group, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Group Members Custom Amounts',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Show custom amount inputs for each group member
                                for (var group in _selectedGroups) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                                    child: Text(
                                      '${group.name} Members:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                  // Get group members and show custom amount inputs
                                  Consumer2<AuthProvider, FriendProvider>(
                                    builder: (context, authProvider, friendProvider, _) {
                                      return Column(
                                        children: group.memberIds.map((memberId) {
                                          // Get member name using helper method
                                          final memberName = _getMemberName(memberId, authProvider, friendProvider);

                                          return Card(
                                            margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    memberName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextFormField(
                                                    initialValue: (_customAmounts[memberId] ?? 0).toString(),
                                                    decoration: InputDecoration(
                                                      labelText: 'Amount (${_selectedCurrency.symbol})',
                                                      prefixIcon: Icon(Icons.attach_money),
                                                      border: OutlineInputBorder(),
                                                      helperText: 'Amount in ${_selectedCurrency.code}',
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (value) {
                                                      final amount = double.tryParse(value) ?? 0;
                                                      _updateCustomAmount(memberId, amount);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: AppTheme.smallSpacing),
                                ],

                                const SizedBox(height: AppTheme.mediumSpacing),
                              ],

                              // Individual Friends Section
                              if (friendProvider.friends.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppTheme.smallSpacing),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Individual Friends',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                for (var friend in friendProvider.friends)
                                  Builder(
                                    builder: (context) {
                                      final isSelected = _selectedFriends.any((f) => f.id == friend.id);

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
                                        child: Column(
                                          children: [
                                            CheckboxListTile(
                                              value: isSelected,
                                              onChanged: (_) => _toggleFriendSelection(friend),
                                              title: Text(friend.name),
                                              subtitle: Text(friend.email),
                                              secondary: CircleAvatar(
                                                backgroundColor: Theme.of(context).primaryColor,
                                                child: friend.photoUrl != null
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(20),
                                                        child: Image.network(
                                                          friend.photoUrl!,
                                                          width: 40,
                                                          height: 40,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                                        ),
                                                      )
                                                    : const Icon(Icons.person, color: Colors.white),
                                              ),
                                            ),

                                            // Custom amount input (only shown for selected friends in custom split mode)
                                            if (isSelected && _splitType == 'custom')
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                                child: TextFormField(
                                                  initialValue: (_customAmounts[friend.id] ?? 0).toString(),
                                                  decoration: InputDecoration(
                                                    labelText: 'Amount (${_selectedCurrency.symbol})',
                                                    prefixIcon: Icon(Icons.attach_money),
                                                    helperText: 'Amount in ${_selectedCurrency.code}',
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (value) {
                                                    final amount = double.tryParse(value) ?? 0;
                                                    _updateCustomAmount(friend.id, amount);
                                                  },
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }
                                  ),
                              ],

                              // Summary of split
                              if ((_selectedFriends.isNotEmpty || _selectedGroups.isNotEmpty) && _amountController.text.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.mediumSpacing),
                                const Text(
                                  'Split Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.smallSpacing),

                                // Display the split summary
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                                    child: Column(
                                      children: [
                                        // Total amount
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Total Amount:'),
                                            Text(
                                              '${_selectedCurrency.symbol}${_amountController.text}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const Divider(),

                                        // Your share
                                        Consumer<AuthProvider>(
                                          builder: (context, authProvider, child) {
                                            if (!authProvider.isAuthenticated) return const SizedBox();

                                            final yourShare = _participants.isEmpty ? 0.0 :
                                                _participants.firstWhere(
                                                  (p) => p['userId'] == authProvider.userModel!.id,
                                                  orElse: () => {'share': 0.0},
                                                )['share'];

                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Your share:'),
                                                Text(
                                                  '${_selectedCurrency.symbol}${yourShare.toStringAsFixed(2)}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            );
                                          },
                                        ),

                                        // All participants' shares (excluding current user)
                                        for (var participant in _participants)
                                          if (!participant['isPayer'])
                                            Builder(
                                              builder: (context) {
                                                final participantShare = participant['share'] ?? 0.0;
                                                final participantName = participant['name'] ?? 'Unknown';

                                                return Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text('$participantName\'s share:'),
                                                    Text(
                                                      '${_selectedCurrency.symbol}${participantShare.toStringAsFixed(2)}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                );
                                              }
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],

                    // Image Selection
                    const SizedBox(height: AppTheme.smallSpacing),
                    const Text(
                      'Add Receipt Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),

                    Row(
                      children: [
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_photo_alternate, size: 40),
                          ),
                        ),
                        const SizedBox(width: AppTheme.smallSpacing),

                        Expanded(
                          child: SizedBox(
                            height: 80,
                            child: _selectedImages.isEmpty
                                ? const Center(
                                    child: Text('No images selected'),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImages.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: FileImage(_selectedImages[index]),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 8,
                                            child: InkWell(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.largeSpacing),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: expenseProvider.isLoading ? null : _saveExpense,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: expenseProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isGroupExpense ? 'Save Group Expense' : 'Save Expense'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
