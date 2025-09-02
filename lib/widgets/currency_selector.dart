import 'package:flutter/material.dart';
import '../models/currency_model.dart';
import '../constants/currency_constants.dart';

class CurrencySelector extends StatefulWidget {
  final CurrencyModel selectedCurrency;
  final Function(CurrencyModel) onCurrencySelected;
  final bool showPopularOnly;

  const CurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
    this.showPopularOnly = false,
  });

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCurrencyPicker(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Currency flag and symbol
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.selectedCurrency.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Currency details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.selectedCurrency.symbol} ${widget.selectedCurrency.code}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.selectedCurrency.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Dropdown arrow
              Icon(
                Icons.keyboard_arrow_down,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CurrencyPickerSheet(
        selectedCurrency: widget.selectedCurrency,
        onCurrencySelected: widget.onCurrencySelected,
        showPopularOnly: widget.showPopularOnly,
      ),
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final CurrencyModel selectedCurrency;
  final Function(CurrencyModel) onCurrencySelected;
  final bool showPopularOnly;

  const _CurrencyPickerSheet({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.showPopularOnly,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currencies = widget.showPopularOnly 
        ? CurrencyConstants.getPopularCurrencies()
        : CurrencyConstants.searchCurrencies(_searchQuery);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Select Currency',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar (only show if not popular only)
          if (!widget.showPopularOnly) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ],
          
          // Currency list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final isSelected = currency.code == widget.selectedCurrency.code;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA)),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected 
                        ? Border.all(color: Theme.of(context).primaryColor)
                        : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          currency.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      '${currency.symbol} ${currency.code}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      currency.name,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                    trailing: isSelected 
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                    onTap: () {
                      widget.onCurrencySelected(currency);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
