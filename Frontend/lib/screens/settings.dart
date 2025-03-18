import 'package:flutter/material.dart';
import 'package:rise/screens/login_&_signup.dart';
import 'package:rise/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  double _textSize = 16.0;
  final ScrollController _scrollController = ScrollController();

  // User info state variables
  String _userEmail = '';
  String _userRole = '';
  String _displayName = '';
  String _avatarLetter = 'U';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final userData = await AuthService.getUserData();
    final email = userData['email'] ?? '';
    final displayName = userData['displayName'];

    if (mounted) {
      setState(() {
        _userEmail = email;
        _userRole = userData['role'] ?? 'user';

        // Use provided display name or extract from email
        if (displayName != null && displayName.isNotEmpty) {
          _displayName = displayName;
        } else {
          _displayName = _extractNameFromEmail(email);
        }

        // Get first letter for avatar
        _avatarLetter =
            _displayName.isNotEmpty
                ? _displayName[0].toUpperCase()
                : email.isNotEmpty
                ? email[0].toUpperCase()
                : 'U';

        _isLoading = false;
      });
    }
  }

  // Helper method to extract a display name from email
  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return '';

    // Split by @ and get the first part
    final parts = email.split('@');
    if (parts.isEmpty) return '';

    String name = parts[0];

    // Convert to title case (capitalize first letter of each word)
    name = name
        .split('.')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');

    return name;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'TenorSans',
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader('Account'),
            _buildProfileTile(),
            const Divider(color: Color(0xFF333333)),

            _buildSectionHeader('Preferences'),
            _buildSettingsSwitchTile(
              title: 'Notifications',
              subtitle: 'Enable push notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              icon: Icons.notifications_outlined,
            ),
            _buildSettingsSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Enable dark theme',
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
              icon: Icons.dark_mode_outlined,
            ),

            _buildTextSizeSlider(),
            const Divider(color: Color(0xFF333333)),

            _buildSectionHeader('About'),
            _buildSettingsActionTile(
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              icon: Icons.privacy_tip_outlined,
              onTap: () {
                _showComingSoonSnackbar();
              },
            ),
            _buildSettingsActionTile(
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              icon: Icons.description_outlined,
              onTap: () {
                _showComingSoonSnackbar();
              },
            ),
            _buildSettingsActionTile(
              title: 'App Version',
              subtitle: '1.0.0',
              icon: Icons.info_outline,
              onTap: null,
            ),

            // Logout button
            const Divider(color: Color(0xFF333333)),
            _buildLogoutTile(),

            // Add some padding at the bottom to ensure everything is easily scrollable
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'TenorSans',
          color: Colors.grey,
          fontSize: 14.0,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileTile() {
    if (_isLoading) {
      return const ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.yellow,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          ),
        ),
        title: Text(
          'Loading profile...',
          style: TextStyle(fontFamily: 'TenorSans', color: Colors.white),
        ),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.yellow,
        child: Text(
          _avatarLetter,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'TenorSans',
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        _displayName,
        style: const TextStyle(fontFamily: 'TenorSans', color: Colors.white),
      ),
      subtitle: Text(
        _userEmail.isEmpty ? 'No email available' : _userEmail,
        style: const TextStyle(fontFamily: 'TenorSans', color: Colors.grey),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        onPressed: () {
          _showEditProfileDialog();
        },
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _displayName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontFamily: 'TenorSans', color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'TenorSans',
                ),
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'TenorSans',
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellow),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userEmail,
                style: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'TenorSans',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'TenorSans', color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await AuthService.saveUserDisplayName(newName);
                  Navigator.of(context).pop();
                  _loadUserData(); // Reload data to update UI
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(fontFamily: 'TenorSans', color: Colors.yellow),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoutTile() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'Logout',
        style: TextStyle(
          fontFamily: 'TenorSans',
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        _showLogoutConfirmationDialog();
      },
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text(
            'Logout Confirmation',
            style: TextStyle(fontFamily: 'TenorSans', color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontFamily: 'TenorSans', color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'TenorSans', color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _performLogout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(fontFamily: 'TenorSans', color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF333333),
        content: Text(
          'Logging out...',
          style: TextStyle(fontFamily: 'TenorSans'),
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // Perform actual logout logic
    await AuthService.logout();

    // Navigate to login screen and clear navigation stack
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
        (route) => false, // This removes all routes from the stack
      );
    }
  }

  Widget _buildSettingsSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'TenorSans', color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'TenorSans',
          fontSize: 12.0,
          color: Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.yellow,
      ),
    );
  }

  Widget _buildSettingsActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'TenorSans', color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'TenorSans',
          fontSize: 12.0,
          color: Colors.grey,
        ),
      ),
      trailing:
          onTap != null
              ? const Icon(
                Icons.arrow_forward_ios,
                size: 16.0,
                color: Colors.white,
              )
              : null,
      onTap: onTap,
    );
  }

  Widget _buildTextSizeSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Text Size',
            style: TextStyle(
              fontFamily: 'TenorSans',
              fontSize: 16.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              const Text(
                'A',
                style: TextStyle(fontFamily: 'TenorSans', color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: _textSize,
                  min: 12.0,
                  max: 24.0,
                  divisions: 6,
                  label: _textSize.round().toString(),
                  activeColor: Colors.yellow,
                  thumbColor: Colors.yellow,
                  onChanged: (value) {
                    setState(() {
                      _textSize = value;
                    });
                  },
                ),
              ),
              const Text(
                'A',
                style: TextStyle(
                  fontFamily: 'TenorSans',
                  fontSize: 24.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF333333),
        content: Text(
          'Coming soon!',
          style: TextStyle(fontFamily: 'TenorSans'),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
