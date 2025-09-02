import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_theme.dart';
import '../../services/upi_payment_service.dart';
import '../../models/debt_model.dart';
import '../../providers/payment_provider.dart';
import 'package:provider/provider.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final String? referenceId;
  final String? upiId;
  final String? payeeName;
  final double? amount;

  const PaymentVerificationScreen({
    super.key,
    this.referenceId,
    this.upiId,
    this.payeeName,
    this.amount,
  });

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  final UpiPaymentService _upiPaymentService = UpiPaymentService();
  final TextEditingController _referenceIdController = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _verificationResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.referenceId != null) {
      _referenceIdController.text = widget.referenceId!;
      _verifyPayment();
    }
  }

  @override
  void dispose() {
    _referenceIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyPayment() async {
    final referenceId = _referenceIdController.text.trim();
    if (referenceId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a reference ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationResult = null;
    });

    try {
      final result = await _upiPaymentService.verifyPaymentStatus(referenceId);
      
      if (mounted) {
        setState(() {
          _verificationResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error verifying payment: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markPaymentAsCompleted() async {
    if (_verificationResult == null || _referenceIdController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _upiPaymentService.manuallyVerifyPayment(
        _referenceIdController.text,
        PaymentStatus.completed,
      );

      if (mounted) {
        if (success) {
          // Refresh the verification result
          await _verifyPayment();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment marked as completed successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to mark payment as completed';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error marking payment as completed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment details section
            if (widget.upiId != null || widget.payeeName != null || widget.amount != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.mediumSpacing),
                      if (widget.payeeName != null)
                        _buildDetailRow('Payee', widget.payeeName!),
                      if (widget.upiId != null)
                        _buildDetailRow('UPI ID', widget.upiId!),
                      if (widget.amount != null)
                        _buildDetailRow(
                          'Amount',
                          '₹${widget.amount!.toStringAsFixed(2)}',
                          valueColor: AppTheme.primaryColor,
                          valueFontWeight: FontWeight.bold,
                        ),
                    ],
                  ),
                ),
              ),
            
            if (widget.upiId != null || widget.payeeName != null || widget.amount != null)
              const SizedBox(height: AppTheme.mediumSpacing),
            
            // Reference ID input
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Reference ID',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the reference ID from your UPI payment to verify the status',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    TextField(
                      controller: _referenceIdController,
                      decoration: InputDecoration(
                        labelText: 'Reference ID',
                        hintText: 'Enter UPI reference ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste),
                          onPressed: () async {
                            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                            if (clipboardData?.text != null) {
                              _referenceIdController.text = clipboardData!.text!;
                            }
                          },
                          tooltip: 'Paste from clipboard',
                        ),
                      ),
                      onSubmitted: (_) => _verifyPayment(),
                    ),
                    const SizedBox(height: AppTheme.mediumSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Verify Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.mediumSpacing),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            // Verification result
            if (_verificationResult != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.mediumSpacing),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: _getStatusColor(_verificationResult!['status']).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(_verificationResult!['status']),
                              color: _getStatusColor(_verificationResult!['status']),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _verificationResult!['message'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.mediumSpacing),
                        _buildDetailRow(
                          'Status',
                          _getStatusDisplayText(_verificationResult!['status']),
                          valueColor: _getStatusColor(_verificationResult!['status']),
                          valueFontWeight: FontWeight.bold,
                        ),
                        _buildDetailRow(
                          'Verified',
                          _verificationResult!['verified'] ? 'Yes' : 'No',
                        ),
                        
                        // Show manual verification button if payment is pending verification
                        if (_verificationResult!['status'] == 'pending_verification')
                          Padding(
                            padding: const EdgeInsets.only(top: AppTheme.mediumSpacing),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _markPaymentAsCompleted,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Mark as Completed'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueFontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'paid':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'pending_verification':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      case 'cancelled':
        return AppTheme.errorColor;
      case 'unknown':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'pending_verification':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'unknown':
        return Icons.help;
      default:
        return Icons.help;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'pending_verification':
        return 'Pending Verification';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      case 'unknown':
        return 'Unknown';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }
}
