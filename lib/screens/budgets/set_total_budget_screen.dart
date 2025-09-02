import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/total_budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/auth_helper.dart';
import '../../utils/validators.dart';

class SetTotalBudgetScreen extends StatefulWidget {
  final TotalBudgetModel? existingBudget;

  const SetTotalBudgetScreen({super.key, this.existingBudget});

  @override
  State<SetTotalBudgetScreen> createState() => _SetTotalBudgetScreenState();
}

class _SetTotalBudgetScreenState extends State<SetTotalBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

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

  // Update end date based on period
  void _updateEndDate() {
    setState(() {
      switch (_selectedPeriod) {
        case 'daily':
          _endDate = _startDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          _endDate = _startDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          // Calculate end of month
          final nextMonth = _startDate.month < 12
              ? DateTime(_startDate.year, _startDate.month + 1, 1)
              : DateTime(_startDate.year + 1, 1, 1);
          _endDate = nextMonth.subtract(const Duration(days: 1));
          break;
      }
    });
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _updateEndDate();
      });
    }
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

      final budget = TotalBudgetModel(
        id: widget.existingBudget?.id ?? '', // Will be set by service if new
        userId: userId,
        amount: amount,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        spent: widget.existingBudget?.spent ?? 0.0, // Preserve spent amount when updating
        alertEnabled: _alertEnabled,
        alertThreshold: _alertThreshold,
      );

      bool success;
      if (widget.existingBudget != null) {
        success = await budgetProvider.updateTotalBudget(budget);
      } else {
        success = await budgetProvider.addTotalBudget(budget);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Total budget saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(budgetProvider.error ?? 'Failed to save total budget'),
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
        title: Text(widget.existingBudget != null ? 'Edit Total Budget' : 'Set Total Budget'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget amount
                const Text('Total Budget Amount', style: TextStyle(fontWeight: FontWeight.bold)),
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

                const SizedBox(height: AppTheme.mediumSpacing),

                // Budget period
                const Text('Budget Period', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.smallSpacing),
                DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                        _updateEndDate();
                      });
                    }
                  },
                ),

                const SizedBox(height: AppTheme.mediumSpacing),

                // Start date
                const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.smallSpacing),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                  ),
                ),

                const SizedBox(height: AppTheme.smallSpacing),
                Text(
                  'End Date: ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                  style: const TextStyle(color: Colors.grey),
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
                        : Text(widget.existingBudget != null ? 'Update Total Budget' : 'Save Total Budget'),
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
