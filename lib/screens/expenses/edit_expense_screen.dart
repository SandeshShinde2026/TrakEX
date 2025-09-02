import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../utils/validators.dart';

class EditExpenseScreen extends StatefulWidget {
  final ExpenseModel expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late String _selectedCategory;
  late DateTime _selectedDate;
  String? _selectedMood;
  late bool _isGroupExpense;
  late List<Map<String, dynamic>> _participants;
  List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _descriptionController = TextEditingController(text: widget.expense.description);
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
    _selectedMood = widget.expense.mood;
    _isGroupExpense = widget.expense.isGroupExpense;
    _participants = List<Map<String, dynamic>>.from(widget.expense.participants);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
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
        _newImages.add(File(image.path));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _updateExpense() async {
    if (_formKey.currentState!.validate()) {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      final updatedExpense = widget.expense.copyWith(
        category: _selectedCategory,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        mood: _selectedMood,
        isGroupExpense: _isGroupExpense,
        participants: _participants,
      );

      // Check if context is still valid
      final currentContext = mounted ? context : null;

      final success = await expenseProvider.updateExpense(
        updatedExpense,
        _newImages.isNotEmpty ? _newImages : null,
        context: currentContext,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(expenseProvider.error ?? 'Failed to update expense'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroupExpense ? 'Edit Group Expense' : 'Edit Expense'),
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
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
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
                                : Colors.grey.withOpacity(0.2),
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
                          });
                        },
                      ),
                    ),

                    // Existing Images
                    if (widget.expense.imageUrls != null &&
                        widget.expense.imageUrls!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.smallSpacing),
                      const Text(
                        'Existing Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.smallSpacing),

                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.expense.imageUrls!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(widget.expense.imageUrls![index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // New Images
                    const SizedBox(height: AppTheme.mediumSpacing),
                    const Text(
                      'Add More Images',
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
                            child: _newImages.isEmpty
                                ? const Center(
                                    child: Text('No new images selected'),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _newImages.length,
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
                                                image: FileImage(_newImages[index]),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 8,
                                            child: InkWell(
                                              onTap: () => _removeNewImage(index),
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

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: expenseProvider.isLoading ? null : _updateExpense,
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
                            : Text(_isGroupExpense ? 'Update Group Expense' : 'Update Expense'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
