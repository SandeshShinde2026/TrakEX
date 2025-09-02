import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class UpiApp {
  final String name;
  final String packageName;
  final IconData iconData;

  UpiApp({
    required this.name,
    required this.packageName,
    required this.iconData,
  });
}

class UpiAppSelectionDialog extends StatelessWidget {
  const UpiAppSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final List<UpiApp> commonUpiApps = [
      UpiApp(
        name: 'Google Pay',
        packageName: 'com.google.android.apps.nbu.paisa.user',
        iconData: Icons.account_balance_wallet,
      ),
      UpiApp(
        name: 'PhonePe',
        packageName: 'com.phonepe.app',
        iconData: Icons.payment,
      ),
      UpiApp(
        name: 'Paytm',
        packageName: 'net.one97.paytm',
        iconData: Icons.payment,
      ),
      UpiApp(
        name: 'Amazon Pay',
        packageName: 'in.amazon.mShop.android.shopping',
        iconData: Icons.shopping_cart,
      ),
      UpiApp(
        name: 'BHIM UPI',
        packageName: 'in.org.npci.upiapp',
        iconData: Icons.account_balance,
      ),
      UpiApp(
        name: 'WhatsApp Pay',
        packageName: 'com.whatsapp',
        iconData: Icons.chat,
      ),
      UpiApp(
        name: 'ICICI iMobile',
        packageName: 'com.csam.icici.bank.imobile',
        iconData: Icons.account_balance,
      ),
      UpiApp(
        name: 'HDFC PayZapp',
        packageName: 'com.hdfc.payzapp',
        iconData: Icons.account_balance,
      ),
      UpiApp(
        name: 'SBI Pay',
        packageName: 'com.sbi.upi',
        iconData: Icons.account_balance,
      ),
      UpiApp(
        name: 'Axis Mobile',
        packageName: 'com.axis.mobile',
        iconData: Icons.account_balance,
      ),
    ];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select UPI App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a UPI app to complete your payment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: commonUpiApps.length,
                itemBuilder: (context, index) {
                  final app = commonUpiApps[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withAlpha(25),
                      child: Icon(
                        app.iconData,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(app.name),
                    onTap: () {
                      Navigator.pop(context, app.packageName);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
