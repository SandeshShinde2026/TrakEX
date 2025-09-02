import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/currency_constants.dart';
import '../../models/currency_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/currency_preferences_service.dart';
import '../../services/currency_exchange_service.dart';
import '../../widgets/currency_selector.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  final CurrencyPreferencesService _preferencesService = CurrencyPreferencesService();
  final CurrencyExchangeService _exchangeService = CurrencyExchangeService();
  
  CurrencyModel _defaultCurrency = CurrencyConstants.defaultCurrency;
  bool _autoConvertEnabled = true;
  bool _showOriginalAmount = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _preferencesService.getAllPreferences();
      setState(() {
        _defaultCurrency = preferences['defaultCurrency'];
        _autoConvertEnabled = preferences['autoConvertEnabled'];
        _showOriginalAmount = preferences['showOriginalAmount'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id;

      await _preferencesService.setDefaultCurrency(_defaultCurrency, userId: userId);
      await _preferencesService.setAutoConvertEnabled(_autoConvertEnabled, userId: userId);
      await _preferencesService.setShowOriginalAmount(_showOriginalAmount, userId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Currency preferences saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _refreshExchangeRates() async {
    try {
      await _exchangeService.clearCache();
      await _exchangeService.getExchangeRates('USD'); // Refresh rates
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exchange rates refreshed successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing rates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _savePreferences,
              icon: const Icon(Icons.save),
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default Currency Section
                  _buildSectionHeader('Default Currency'),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildInfoCard(
                    'Your default currency is used for tracking and analytics. All expenses will be converted to this currency for consistent reporting.',
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  CurrencySelector(
                    selectedCurrency: _defaultCurrency,
                    onCurrencySelected: (currency) {
                      setState(() {
                        _defaultCurrency = currency;
                      });
                    },
                    showPopularOnly: false,
                  ),
                  const SizedBox(height: AppTheme.largeSpacing),

                  // Auto-Convert Section
                  _buildSectionHeader('Auto-Convert'),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildInfoCard(
                    'When enabled, expenses in foreign currencies will be automatically converted to your default currency using current exchange rates.',
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildSwitchTile(
                    title: 'Auto-Convert Expenses',
                    subtitle: 'Convert foreign currency expenses automatically',
                    value: _autoConvertEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoConvertEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.largeSpacing),

                  // Display Options Section
                  _buildSectionHeader('Display Options'),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildInfoCard(
                    'Choose how converted amounts are displayed in your expense lists and reports.',
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildSwitchTile(
                    title: 'Show Original Amount',
                    subtitle: 'Display both original and converted amounts',
                    value: _showOriginalAmount,
                    onChanged: (value) {
                      setState(() {
                        _showOriginalAmount = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.largeSpacing),

                  // Exchange Rates Section
                  _buildSectionHeader('Exchange Rates'),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildInfoCard(
                    'Exchange rates are updated automatically every hour. You can manually refresh them if needed.',
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildActionCard(
                    title: 'Refresh Exchange Rates',
                    subtitle: 'Get the latest currency exchange rates',
                    icon: Icons.refresh,
                    onTap: _refreshExchangeRates,
                  ),
                  const SizedBox(height: AppTheme.largeSpacing),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Currency Settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: AppTheme.smallSpacing),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
        ),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
