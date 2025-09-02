import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/debt_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_provider.dart';

class AddDebtScreen extends StatefulWidget {
  final UserModel friend;
  final DebtModel? existingDebt; // Optional, for editing existing debt

  const AddDebtScreen({
    super.key,
    required this.friend,
    this.existingDebt,
  });

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // For UI purposes only - to determine if the user owes the friend or vice versa
  bool _userOwesFriend = true;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  PaymentStatus _paymentStatus = PaymentStatus.pending;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If editing existing debt, populate the form
    if (widget.existingDebt != null) {
      final debt = widget.existingDebt!;
      _descriptionController.text = debt.description;
      _amountController.text = debt.amount.toString();

      // Determine if user owes friend or vice versa
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (debt.creditorId == authProvider.userModel!.id) {
        // Friend owes user
        _userOwesFriend = false;
      } else {
        // User owes friend
        _userOwesFriend = true;
      }

      _paymentMethod = debt.paymentMethod;
      _paymentStatus = debt.status;
      _date = debt.createdAt;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);

      final currentUser = authProvider.userModel!;
      final amount = double.parse(_amountController.text);

      // Determine creditor and debtor based on who owes whom
      final String creditorId = _userOwesFriend
          ? widget.friend.id  // If user owes friend, friend is creditor
          : currentUser.id;   // If friend owes user, user is creditor

      final String debtorId = _userOwesFriend
          ? currentUser.id    // If user owes friend, user is debtor
          : widget.friend.id; // If friend owes user, friend is debtor

      if (widget.existingDebt == null) {
        // Create new debt
        debugPrint('AddDebtScreen: Creating new debt');
        debugPrint('Creditor: $creditorId, Debtor: $debtorId, Amount: $amount');

        final result = await debtProvider.addDebtWithParams(
          creditorId: creditorId,
          debtorId: debtorId,
          amount: amount,
          description: _descriptionController.text,
          paymentMethod: _paymentMethod,
          status: _paymentStatus,
          createdAt: _date,
          debtType: DebtType.direct, // Explicitly set as direct debt
        );

        debugPrint('AddDebtScreen: Debt created successfully: $result');
      } else {
        // Update existing debt
        debugPrint('AddDebtScreen: Updating existing debt: ${widget.existingDebt!.id}');

        final result = await debtProvider.updateDebtWithParams(
          debtId: widget.existingDebt!.id,
          creditorId: creditorId,
          debtorId: debtorId,
          amount: amount,
          description: _descriptionController.text,
          paymentMethod: _paymentMethod,
          status: _paymentStatus,
          createdAt: _date,
          debtType: widget.existingDebt!.debtType, // Preserve existing debt type
        );

        debugPrint('AddDebtScreen: Debt updated successfully: $result');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving debt: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDebt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Friend info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 24,
                              child: widget.friend.photoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(
                                        widget.friend.photoUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 24),
                                      ),
                                    )
                                  : const Icon(Icons.person, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: AppTheme.mediumSpacing),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.friend.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Transaction with ${widget.friend.name}',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Debt type selector
                    const Text(
                      'Transaction Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            label: 'You owe ${widget.friend.name}',
                            icon: Icons.arrow_upward,
                            color: Colors.red,
                            isSelected: _userOwesFriend,
                            onTap: () {
                              setState(() {
                                _userOwesFriend = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.smallSpacing),
                        Expanded(
                          child: _buildTypeButton(
                            label: '${widget.friend.name} owes you',
                            icon: Icons.arrow_downward,
                            color: Colors.green,
                            isSelected: !_userOwesFriend,
                            onTap: () {
                              setState(() {
                                _userOwesFriend = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Amount field
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: AppConstants.currencySymbol,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }

                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Date picker
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_date),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Payment method
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Wrap(
                      spacing: AppTheme.smallSpacing,
                      children: [
                        _buildChip(
                          label: 'Cash',
                          isSelected: _paymentMethod == PaymentMethod.cash,
                          onTap: () {
                            setState(() {
                              _paymentMethod = PaymentMethod.cash;
                            });
                          },
                        ),
                        _buildChip(
                          label: 'UPI',
                          isSelected: _paymentMethod == PaymentMethod.upi,
                          onTap: () {
                            setState(() {
                              _paymentMethod = PaymentMethod.upi;
                            });
                          },
                        ),
                        _buildChip(
                          label: 'Bank Transfer',
                          isSelected: _paymentMethod == PaymentMethod.bankTransfer,
                          onTap: () {
                            setState(() {
                              _paymentMethod = PaymentMethod.bankTransfer;
                            });
                          },
                        ),
                        _buildChip(
                          label: 'Other',
                          isSelected: _paymentMethod == PaymentMethod.other,
                          onTap: () {
                            setState(() {
                              _paymentMethod = PaymentMethod.other;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.mediumSpacing),

                    // Payment status
                    const Text(
                      'Payment Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppTheme.smallSpacing),
                    Wrap(
                      spacing: AppTheme.smallSpacing,
                      children: [
                        _buildChip(
                          label: 'Pending',
                          isSelected: _paymentStatus == PaymentStatus.pending,
                          onTap: () {
                            setState(() {
                              _paymentStatus = PaymentStatus.pending;
                            });
                          },
                        ),
                        _buildChip(
                          label: 'Paid',
                          isSelected: _paymentStatus == PaymentStatus.paid,
                          onTap: () {
                            setState(() {
                              _paymentStatus = PaymentStatus.paid;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.largeSpacing),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveDebt,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(isEditing ? 'Update' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withAlpha(50),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onTap();
        }
      },
    );
  }
}
