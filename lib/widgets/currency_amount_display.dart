import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/currency_provider.dart';
import '../constants/currency_constants.dart';

class CurrencyAmountDisplay extends StatelessWidget {
  final ExpenseModel expense;
  final TextStyle? style;
  final TextStyle? secondaryStyle;
  final bool showConversionInfo;
  final bool showExchangeRate;

  const CurrencyAmountDisplay({
    super.key,
    required this.expense,
    this.style,
    this.secondaryStyle,
    this.showConversionInfo = true,
    this.showExchangeRate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        // Get display text based on user preferences
        final displayText = currencyProvider.getExpenseDisplayText(
          originalAmount: expense.amount,
          originalCurrency: expense.currencyCode,
          convertedAmount: expense.convertedAmount,
          convertedCurrency: expense.convertedCurrencyCode,
        );

        // Check if we should show conversion info
        final shouldShowConversion = showConversionInfo && 
                                   expense.isConverted && 
                                   currencyProvider.showOriginalAmount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main amount display
            Text(
              displayText,
              style: style ?? const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            
            // Exchange rate info (if requested and available)
            if (showExchangeRate && expense.exchangeRateText != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  expense.exchangeRateText!,
                  style: secondaryStyle ?? TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SimpleCurrencyDisplay extends StatelessWidget {
  final double amount;
  final String currencyCode;
  final TextStyle? style;
  final bool showFlag;

  const SimpleCurrencyDisplay({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.style,
    this.showFlag = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyConstants.getCurrencyByCode(currencyCode);
    final formattedAmount = currency?.formatAmount(amount) ?? '$amount $currencyCode';

    if (!showFlag || currency == null) {
      return Text(
        formattedAmount,
        style: style,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currency.flag,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          formattedAmount,
          style: style,
        ),
      ],
    );
  }
}

class CurrencyConversionCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;

  const CurrencyConversionCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!expense.isConverted) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final originalCurrency = CurrencyConstants.getCurrencyByCode(expense.currencyCode);
    final convertedCurrency = CurrencyConstants.getCurrencyByCode(expense.convertedCurrencyCode!);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.currency_exchange,
                    size: 16,
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Currency Conversion',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Original amount
              Row(
                children: [
                  if (originalCurrency != null) ...[
                    Text(
                      originalCurrency.flag,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Original: ${originalCurrency?.formatAmount(expense.amount) ?? '${expense.amount} ${expense.currencyCode}'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Converted amount
              Row(
                children: [
                  if (convertedCurrency != null) ...[
                    Text(
                      convertedCurrency.flag,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Converted: ${convertedCurrency?.formatAmount(expense.convertedAmount!) ?? '${expense.convertedAmount} ${expense.convertedCurrencyCode}'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              // Exchange rate
              if (expense.exchangeRateText != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Rate: ${expense.exchangeRateText}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CurrencyQuickConverter extends StatefulWidget {
  final String fromCurrency;
  final String toCurrency;
  final double initialAmount;
  final Function(double)? onAmountChanged;

  const CurrencyQuickConverter({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    this.initialAmount = 100,
    this.onAmountChanged,
  });

  @override
  State<CurrencyQuickConverter> createState() => _CurrencyQuickConverterState();
}

class _CurrencyQuickConverterState extends State<CurrencyQuickConverter> {
  late TextEditingController _controller;
  double _convertedAmount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAmount.toString());
    _convertAmount();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _convertAmount() async {
    final amount = double.tryParse(_controller.text) ?? 0;
    if (amount <= 0) {
      setState(() {
        _convertedAmount = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final converted = await currencyProvider.convertCurrency(
        amount: amount,
        fromCurrency: widget.fromCurrency,
        toCurrency: widget.toCurrency,
      );

      setState(() {
        _convertedAmount = converted;
        _isLoading = false;
      });

      widget.onAmountChanged?.call(converted);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromCurrency = CurrencyConstants.getCurrencyByCode(widget.fromCurrency);
    final toCurrency = CurrencyConstants.getCurrencyByCode(widget.toCurrency);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Converter',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Input amount
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Amount (${fromCurrency?.code ?? widget.fromCurrency})',
                prefixText: fromCurrency?.symbol ?? '',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _convertAmount(),
            ),
            
            const SizedBox(height: 16),
            
            // Conversion result
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (toCurrency != null) ...[
                    Text(
                      toCurrency.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            toCurrency?.formatAmount(_convertedAmount) ?? '$_convertedAmount ${widget.toCurrency}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
