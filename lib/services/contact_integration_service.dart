import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';

class ContactIntegrationService {
  static final ContactIntegrationService _instance = ContactIntegrationService._internal();
  factory ContactIntegrationService() => _instance;
  ContactIntegrationService._internal();

  // Request contacts permission
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // Check if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  // Check if contacts permission is permanently denied
  Future<bool> isContactsPermissionPermanentlyDenied() async {
    final status = await Permission.contacts.status;
    return status.isPermanentlyDenied;
  }

  // Request contacts permission with proper dialog handling
  Future<bool> requestContactsPermissionWithDialog(BuildContext context) async {
    // First check current status
    final currentStatus = await Permission.contacts.status;

    debugPrint('ContactIntegrationService: Current permission status: $currentStatus');

    if (currentStatus.isGranted) {
      debugPrint('ContactIntegrationService: Permission already granted');
      return true;
    }

    // Store context validity check
    if (!context.mounted) return false;

    // If permanently denied, show settings dialog
    if (currentStatus.isPermanentlyDenied) {
      debugPrint('ContactIntegrationService: Permission permanently denied, showing settings dialog');
      return await _showPermissionPermanentlyDeniedDialog(context);
    }

    // Show permission explanation dialog first
    debugPrint('ContactIntegrationService: Showing permission explanation dialog');
    final shouldRequest = await _showPermissionExplanationDialog(context);
    if (!shouldRequest) {
      debugPrint('ContactIntegrationService: User declined permission explanation');
      return false;
    }

    // Check context validity before requesting permission
    if (!context.mounted) return false;

    // Request permission
    debugPrint('ContactIntegrationService: Requesting contacts permission');
    final status = await Permission.contacts.request();

    debugPrint('ContactIntegrationService: Permission request result: $status');

    // Check context validity again after async operation
    if (!context.mounted) return false;

    if (status.isGranted) {
      debugPrint('ContactIntegrationService: Permission granted successfully');
      return true;
    } else if (status.isPermanentlyDenied) {
      // User denied and selected "Don't ask again"
      debugPrint('ContactIntegrationService: Permission permanently denied after request');
      return await _showPermissionPermanentlyDeniedDialog(context);
    } else if (status.isDenied) {
      // User denied but can ask again
      debugPrint('ContactIntegrationService: Permission denied, showing retry dialog');
      _showPermissionDeniedDialog(context);
      return false;
    } else {
      // Handle other statuses (restricted, limited, etc.)
      debugPrint('ContactIntegrationService: Unexpected permission status: $status');
      _showPermissionDeniedDialog(context);
      return false;
    }
  }

  // Get all contacts
  Future<List<Contact>> getAllContacts() async {
    if (!await hasContactsPermission()) {
      throw Exception('Contacts permission not granted');
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filter contacts with phone numbers or emails
      return contacts.where((contact) =>
        contact.phones.isNotEmpty || contact.emails.isNotEmpty
      ).toList();
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      return [];
    }
  }

  // Search contacts by name
  Future<List<Contact>> searchContacts(String query) async {
    if (query.isEmpty) return [];

    final allContacts = await getAllContacts();
    return allContacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
  }

  // Convert contact to potential friend
  ContactFriend contactToFriend(Contact contact) {
    return ContactFriend(
      name: contact.displayName,
      phoneNumber: contact.phones.isNotEmpty
          ? contact.phones.first.number
          : null,
      email: contact.emails.isNotEmpty
          ? contact.emails.first.address
          : null,
      avatar: contact.photo,
    );
  }

  // Get contacts that might be app users (by phone/email)
  Future<List<ContactFriend>> getPotentialAppUsers(List<UserModel> appUsers) async {
    final contacts = await getAllContacts();
    final potentialFriends = <ContactFriend>[];

    for (final contact in contacts) {
      final contactFriend = contactToFriend(contact);

      // Check if this contact matches any app user
      final matchingUser = appUsers.firstWhere(
        (user) =>
          (contactFriend.phoneNumber != null &&
           user.email == contactFriend.phoneNumber) ||
          (contactFriend.email != null &&
           user.email == contactFriend.email),
        orElse: () => UserModel(
          id: '',
          name: '',
          email: '',
        ),
      );

      if (matchingUser.id.isNotEmpty) {
        contactFriend.isAppUser = true;
        contactFriend.userId = matchingUser.id;
        potentialFriends.add(contactFriend);
      }
    }

    return potentialFriends;
  }

  // Show contact picker dialog
  Future<ContactFriend?> showContactPicker(BuildContext context) async {
    // Use the new permission dialog method
    if (!await requestContactsPermissionWithDialog(context)) {
      return null;
    }

    final contacts = await getAllContacts();

    // Check context validity after async operation
    if (!context.mounted) return null;

    if (contacts.isEmpty) {
      _showNoContactsDialog(context);
      return null;
    }

    return showDialog<ContactFriend>(
      context: context,
      builder: (context) => ContactPickerDialog(contacts: contacts),
    );
  }

  // Show permission explanation dialog (before requesting permission)
  Future<bool> _showPermissionExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.contacts,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Contacts Access',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TrakEX would like to access your contacts to help you:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildPermissionBenefit(
              Icons.person_add,
              'Find friends',
              'Easily find and add friends who are already using the app',
            ),
            const SizedBox(height: 12),
            _buildPermissionBenefit(
              Icons.search,
              'Quick search',
              'Search for friends by name or phone number from your contacts',
            ),
            const SizedBox(height: 12),
            _buildPermissionBenefit(
              Icons.security,
              'Privacy protected',
              'Your contact data stays on your device and is never uploaded',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can change this permission anytime in your device settings.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Not Now',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Allow Access'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Show dialog when permission is permanently denied
  Future<bool> _showPermissionPermanentlyDeniedDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.block,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Permission Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contacts permission is required to add friends from your contacts.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'To enable contacts access:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Tap "Open Settings" below'),
                  const Text('2. Find "Permissions" or "App permissions"'),
                  const Text('3. Enable "Contacts" permission'),
                  const Text('4. Return to TrakEX'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Show dialog when permission is denied (but not permanently)
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Permission Needed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contacts permission was not granted. To add friends from your contacts, we need access to your contacts.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tip: When the system dialog appears, tap "Allow" to grant permission.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Try requesting permission again
              await requestContactsPermissionWithDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Helper method to build permission benefit items
  Widget _buildPermissionBenefit(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: Colors.green.shade700,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNoContactsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Contacts Found'),
        content: const Text('No contacts were found on your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ContactFriend {
  final String name;
  final String? phoneNumber;
  final String? email;
  final Uint8List? avatar;
  bool isAppUser;
  String? userId;

  ContactFriend({
    required this.name,
    this.phoneNumber,
    this.email,
    this.avatar,
    this.isAppUser = false,
    this.userId,
  });
}

class ContactPickerDialog extends StatefulWidget {
  final List<Contact> contacts;

  const ContactPickerDialog({
    super.key,
    required this.contacts,
  });

  @override
  State<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<ContactPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.contacts),
                const SizedBox(width: 8),
                const Text(
                  'Select Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),

            // Contacts list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return _buildContactItem(contact);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    final contactFriend = ContactIntegrationService().contactToFriend(contact);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: contact.photo != null
            ? MemoryImage(contact.photo!)
            : null,
        child: contact.photo == null
            ? Text(
                contact.displayName.isNotEmpty
                    ? contact.displayName[0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Text(
        contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contactFriend.phoneNumber != null)
            Text(contactFriend.phoneNumber!),
          if (contactFriend.email != null)
            Text(contactFriend.email!),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.of(context).pop(contactFriend);
      },
    );
  }
}

// Widget for showing contact suggestions
class ContactSuggestionsWidget extends StatefulWidget {
  final Function(ContactFriend) onContactSelected;
  final List<UserModel> appUsers;

  const ContactSuggestionsWidget({
    super.key,
    required this.onContactSelected,
    required this.appUsers,
  });

  @override
  State<ContactSuggestionsWidget> createState() => _ContactSuggestionsWidgetState();
}

class _ContactSuggestionsWidgetState extends State<ContactSuggestionsWidget> {
  List<ContactFriend> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await ContactIntegrationService()
          .getPotentialAppUsers(widget.appUsers);
      setState(() {
        _suggestions = suggestions.take(5).toList(); // Show top 5 suggestions
      });
    } catch (e) {
      debugPrint('Error loading contact suggestions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contacts, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'From Your Contacts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_suggestions.map((suggestion) => _buildSuggestionItem(suggestion))),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(ContactFriend suggestion) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: suggestion.avatar != null
            ? MemoryImage(suggestion.avatar!)
            : null,
        child: suggestion.avatar == null
            ? Text(suggestion.name.isNotEmpty ? suggestion.name[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(
        suggestion.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(suggestion.phoneNumber ?? suggestion.email ?? ''),
      trailing: ElevatedButton(
        onPressed: () => widget.onContactSelected(suggestion),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Add'),
      ),
    );
  }
}
