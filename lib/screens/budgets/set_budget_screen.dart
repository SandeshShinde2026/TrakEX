import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/auth_helper.dart';
import '../../utils/validators.dart';

class SetBudgetScreen extends StatefulWidget {
  final BudgetModel? existingBudget;

  const SetBudgetScreen({super.key, this.existingBudget});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String _selectedCategory = AppConstants.expenseCategories[0]['name'];
  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _alertEnabled = true;
  double _alertThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    
    // If editing an existing budget, populate the form
    if (widget.existingBudget != null) {
      _amountController.text = widget.existingBudget!.amount.toString();
      _selectedCategory = widget.existingBudget!.category;
      _selectedPeriod = widget.existingBudget!.period;
      _startDate = widget.existingBudget!.startDate;
      _endDate = widget.existingBudget!.endDate;
      _alertEnabled = widget.existingBudget!.alertEnabled;
      _alertThreshold = widget.existingBudget!.alertThreshold;
    }
    
    // Check authentication status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthHelper.checkAuthenticated(context);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Adjust end date if needed
        if (_endDate.isBefore(_startDate)) {
          if (_selectedPeriod == 'monthly') {
            _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day - 1);
          } else {
            _endDate = _startDate.add(const Duration(days: 6));
          }
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _updatePeriod(String? period) {
    if (period == null) return;
    
    setState(() {
      _selectedPeriod = period;
      
      // Update end date based on period
      if (period == 'monthly') {
        _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day - 1);
      } else if (period == 'weekly') {
        _endDate = _startDate.add(const Duration(days: 6));
      }
    });
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      
      // Check authentication
      final isAuthenticated = await AuthHelper.checkAuthenticated(context);
      
      if (!mounted) return;
      
      if (!isAuthenticated || authProvider.userModel == null) {
        return;
      }
      
      final userId = authProvider.userModel!.id;
      final amount = double.parse(_amountController.text);
      
      final budget = BudgetModel(
        id: widget.existingBudget?.id ?? '', // Will be set by service if new
        userId: userId,
        category: _selectedCategory,
        amount: amount,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        spent: widget.existingBudget?.spent ?? 0.0,
        alertEnabled: _alertEnabled,
        alertThreshold: _alertThreshold,
      );
      
      bool success;
      if (widget.existingBudget != null) {
        success = await budgetProvider.updateBudget(budget);
      } else {
        success = await budgetProvider.addBudget(budget);
      }
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(budgetProvider.error ?? 'Failed to save budget'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingBudget != null ? 'Edit Budget' : 'Set Budget'),
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Budget Amount',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.validateAmount,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
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
                      validator: Validators.validateCategory,
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    
                    // Period Selection
                    const Text('Budget Period', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'monthly',
                          groupValue: _selectedPeriod,
                          onChanged: _updatePeriod,
                        ),
                        const Text('Monthly'),
                        const SizedBox(width: AppTheme.mediumSpacing),
                        Radio<String>(
                          value: 'weekly',
                          groupValue: _selectedPeriod,
                          onChanged: _updatePeriod,
                        ),
                        const Text('Weekly'),
                      ],
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    
                    // Date Range
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectStartDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat(AppConstants.dateFormat).format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.smallSpacing),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectEndDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat(AppConstants.dateFormat).format(_endDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    
                    // Alert Settings
                    SwitchListTile(
                      title: const Text('Enable Budget Alerts'),
                      subtitle: const Text('Get notified when you approach your budget limit'),
                      value: _alertEnabled,
                      onChanged: (value) {
                        setState(() {
                          _alertEnabled = value;
                        });
                      },
                    ),
                    
                    if (_alertEnabled) ...[
                      const Text('Alert Threshold', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppTheme.smallSpacing),
                      Text('Alert me when I\'ve spent ${_alertThreshold.toInt()}% of my budget'),
                      Slider(
                        value: _alertThreshold,
                        min: 50,
                        max: 100,
                        divisions: 10,
                        label: '${_alertThreshold.toInt()}%',
                        onChanged: (value) {
                          setState(() {
                            _alertThreshold = value;
                          });
                        },
                      ),
                    ],
                    
                    const SizedBox(height: AppTheme.largeSpacing),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: budgetProvider.isLoading ? null : _saveBudget,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: budgetProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(widget.existingBudget != null ? 'Update Budget' : 'Save Budget'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
