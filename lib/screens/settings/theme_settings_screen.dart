import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Theme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to Default',
            onPressed: () {
              _showResetConfirmation(context, themeProvider);
            },
          ),
        ],
      ),
      body: themeProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.mediumSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Mode Section
                  const Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  _buildThemeModeCard(
                    context,
                    title: 'System Default',
                    subtitle: 'Follow system theme settings',
                    icon: Icons.brightness_auto,
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                  _buildThemeModeCard(
                    context,
                    title: 'Light Theme',
                    subtitle: 'Always use light theme',
                    icon: Icons.brightness_5,
                    isSelected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  _buildThemeModeCard(
                    context,
                    title: 'Dark Theme',
                    subtitle: 'Always use dark theme',
                    icon: Icons.brightness_4,
                    isSelected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                  
                  const SizedBox(height: AppTheme.mediumSpacing),
                  const Divider(),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  
                  // Primary Color Section
                  const Text(
                    'Primary Color',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.smallSpacing),
                  const Text(
                    'Choose a color for app accents and highlights',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: AppTheme.mediumSpacing),
                  
                  // Color Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: ThemeProvider.availableColors.length,
                    itemBuilder: (context, index) {
                      final color = ThemeProvider.availableColors[index];
                      final isSelected = themeProvider.primaryColor.value == color.value;
                      
                      return InkWell(
                        onTap: () => themeProvider.setPrimaryColor(color),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.mediumSpacing),
                  
                  // Current Theme Info
                  Card(
                    margin: const EdgeInsets.only(top: AppTheme.mediumSpacing),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.smallSpacing),
                          Row(
                            children: [
                              const Text('Mode: '),
                              Text(
                                themeProvider.getThemeModeName(themeProvider.themeMode),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('Color: '),
                              Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: themeProvider.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                themeProvider.getColorName(themeProvider.primaryColor),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildThemeModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.smallSpacing),
      elevation: isSelected ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.withAlpha(50),
          width: isSelected ? 2 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.mediumSpacing),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: AppTheme.mediumSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResetConfirmation(BuildContext context, ThemeProvider themeProvider) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Theme Settings'),
          content: const Text('Are you sure you want to reset all theme settings to default?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset'),
              onPressed: () {
                themeProvider.resetToDefault();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme settings reset to default'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
