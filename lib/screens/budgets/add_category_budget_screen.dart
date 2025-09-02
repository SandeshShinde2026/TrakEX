import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/auth_helper.dart';
import '../../utils/validators.dart';

class AddCategoryBudgetScreen extends StatefulWidget {
  final BudgetModel? existingBudget;

  const AddCategoryBudgetScreen({super.key, this.existingBudget});

  @override
  State<AddCategoryBudgetScreen> createState() => _AddCategoryBudgetScreenState();
}

class _AddCategoryBudgetScreenState extends State<AddCategoryBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String? _selectedCategory;
  bool _isCustomCategory = false;
  bool _isLoading = false;
  String? _errorMessage;

  // List of all available categories
  final List<Map<String, dynamic>> _allCategories = [
    ...AppConstants.expenseCategories,
    {'name': 'Friend', 'icon': Icons.people},
    {'name': 'Miscellaneous', 'icon': Icons.category},
  ];

  @override
  void initState() {
    super.initState();

    // If editing an existing budget, populate the form
    if (widget.existingBudget != null) {
      _amountController.text = widget.existingBudget!.amount.toString();

      // Check if it's a custom category
      final isStandardCategory = _allCategories.any((c) => c['name'] == widget.existingBudget!.category);
      if (!isStandardCategory) {
        // It's a custom category
        _isCustomCategory = true;
        _customCategoryController.text = widget.existingBudget!.category;
        _selectedCategory = null; // No standard category selected
      } else {
        // It's a standard category
        _isCustomCategory = false;
        _selectedCategory = widget.existingBudget!.category;
      }
    } else {
      // New budget - default to standard category
      _isCustomCategory = false;

      // Set default category if available
      if (_allCategories.isNotEmpty) {
        _selectedCategory = _allCategories[0]['name'];
      }
    }

    // Check authentication status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthHelper.checkAuthenticated(context);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

      // Check authentication
      final isAuthenticated = await AuthHelper.checkAuthenticated(context);

      if (!mounted) return;

      if (!isAuthenticated || authProvider.userModel == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = authProvider.userModel!.id;
      final amount = double.parse(_amountController.text);

      // Determine the actual category
      final String category;
      if (_isCustomCategory) {
        // Use custom category name
        category = _customCategoryController.text.trim();
        if (category.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please enter a custom category name';
          });
          return;
        }
      } else {
        // Use selected standard category
        if (_selectedCategory == null || _selectedCategory!.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please select a category';
          });
          return;
        }
        category = _selectedCategory!;
      }

      // Check if the category budget exceeds the total budget
      final isValid = await budgetProvider.validateCategoryBudget(
        userId,
        widget.existingBudget?.id ?? '',
        amount
      );

      if (!isValid) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This category budget would exceed your total budget limit';
        });
        return;
      }

      // Get period and dates from total budget
      final totalBudget = budgetProvider.totalBudget;
      if (totalBudget == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please set a total budget first';
        });
        return;
      }

      final budget = BudgetModel(
        id: widget.existingBudget?.id ?? '', // Will be set by service if new
        userId: userId,
        category: category,
        amount: amount,
        period: totalBudget.period,
        startDate: totalBudget.startDate,
        endDate: totalBudget.endDate,
        spent: widget.existingBudget?.spent ?? 0.0,
        alertEnabled: true,
        alertThreshold: 80.0,
      );

      bool success;
      if (widget.existingBudget != null) {
        success = await budgetProvider.updateBudget(budget);
      } else {
        success = await budgetProvider.addBudget(budget);
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category budget saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = budgetProvider.error ?? 'Failed to save category budget';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingBudget != null ? 'Edit Category Budget' : 'Add Category Budget'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category selection
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
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Select Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _allCategories.map((category) {
                      final name = category['name'] as String;
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Row(
                          children: [
                            Icon(category['icon'] as IconData),
                            const SizedBox(width: 8),
                            Text(name),
                          ],
                        ),
                      );
                    }).toList(),
                    validator: (value) {
                      if (!_isCustomCategory && (value == null || value.isEmpty)) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
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
                    onChanged: (value) {
                      // Force form validation on change
                      _formKey.currentState?.validate();
                    },
                  ),
                ],

                const SizedBox(height: AppTheme.mediumSpacing),

                // Budget amount
                const Text('Budget Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.smallSpacing),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: AppConstants.currencySymbol,
                    border: const OutlineInputBorder(),
                  ),
                  validator: Validators.validateAmount,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppTheme.mediumSpacing),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.smallSpacing),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.largeSpacing),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveBudget,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(widget.existingBudget != null ? 'Update Category Budget' : 'Save Category Budget'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
