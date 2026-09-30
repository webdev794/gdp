import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/address_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/mock_auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../orders/order_history_screen.dart';
import '../support/support_screen.dart';
import '../checkout/setup_card_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Profile Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSavingProfile = false;

  // Password Form Controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUpdatingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Addresses State
  List<AddressModel> _addresses = [];
  bool _isLoadingAddresses = false;
  bool _isEditingAddress = false;
  AddressModel? _editingAddressTarget;

  // Payment methods (saved Stripe cards)
  List<Map<String, dynamic>> _cards = [];
  bool _isLoadingCards = false;
  bool _isAddingCard = false;

  // Address Form Controllers
  final _addrLabelController = TextEditingController();
  final _addrNameController = TextEditingController();
  final _addrLine1Controller = TextEditingController();
  final _addrLine2Controller = TextEditingController();
  final _addrCityController = TextEditingController();
  final _addrStateController = TextEditingController();
  final _addrZipController = TextEditingController();
  bool _addrIsDefault = false;
  bool _isSavingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
    _tabController = TabController(length: 3, vsync: this);
    _initUserData();
    _loadAddresses();
  }

  void _initUserData() {
    final user = MockAuthService.currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone;
    }
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoadingAddresses = true);
    final list = await ApiService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _isLoadingAddresses = false;
      });
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.emeraldPrimary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _addrLabelController.dispose();
    _addrNameController.dispose();
    _addrLine1Controller.dispose();
    _addrLine2Controller.dispose();
    _addrCityController.dispose();
    _addrStateController.dispose();
    _addrZipController.dispose();
    super.dispose();
  }

  // --- Profile Actions ---
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      _showMessage('Name cannot be empty', isError: true);
      return;
    }

    setState(() => _isSavingProfile = true);
    final res = await ApiService.updateProfile(name: name, phone: phone);
    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (res['success'] == true) {
        _showMessage(res['message'] ?? 'Profile updated successfully!');
      } else {
        _showMessage(
          res['message'] ?? 'Failed to update profile.',
          isError: true,
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _showMessage('Please fill in all password fields.', isError: true);
      return;
    }
    if (next != confirm) {
      _showMessage('The two new passwords do not match.', isError: true);
      return;
    }
    if (next.length < 8) {
      _showMessage(
        'New password must be at least 8 characters.',
        isError: true,
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);
    final res = await ApiService.changePassword(
      currentPassword: current,
      newPassword: next,
      confirmPassword: confirm,
    );
    if (mounted) {
      setState(() => _isUpdatingPassword = false);
      if (res['success'] == true) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showMessage(res['message'] ?? 'Password changed.');
      } else {
        _showMessage(
          res['message'] ?? 'Could not change password.',
          isError: true,
        );
      }
    }
  }

  // --- Address Actions ---
  void _startAddAddress() {
    final user = MockAuthService.currentUser;
    _editingAddressTarget = null;
    _addrLabelController.text = 'Home';
    _addrNameController.text = user?.fullName ?? '';
    _addrLine1Controller.clear();
    _addrLine2Controller.clear();
    _addrCityController.text = 'Miami';
    _addrStateController.text = 'FL';
    _addrZipController.text = '33131';
    _addrIsDefault = _addresses.isEmpty;
    setState(() => _isEditingAddress = true);
  }

  void _startEditAddress(AddressModel addr) {
    _editingAddressTarget = addr;
    _addrLabelController.text = addr.label;
    _addrNameController.text =
        addr.name ?? MockAuthService.currentUser?.fullName ?? '';
    _addrLine1Controller.text = addr.line1 ?? addr.fullAddress;
    _addrLine2Controller.text = addr.line2 ?? '';
    _addrCityController.text = addr.city;
    _addrStateController.text = addr.state;
    _addrZipController.text = addr.zipCode;
    _addrIsDefault = addr.isDefault;
    setState(() => _isEditingAddress = true);
  }

  void _cancelAddressEdit() {
    setState(() {
      _isEditingAddress = false;
      _editingAddressTarget = null;
    });
  }

  Future<void> _saveAddressForm() async {
    final label = _addrLabelController.text.trim();
    final name = _addrNameController.text.trim();
    final line1 = _addrLine1Controller.text.trim();
    final line2 = _addrLine2Controller.text.trim();
    final city = _addrCityController.text.trim();
    final state = _addrStateController.text.trim();
    final postalCode = _addrZipController.text.trim();

    if (name.isEmpty || line1.isEmpty) {
      _showMessage('Full name and Address Line 1 are required.', isError: true);
      return;
    }

    final payload = {
      'label': label.isNotEmpty ? label : 'Home',
      'name': name,
      'line1': line1,
      if (line2.isNotEmpty) 'line2': line2,
      'city': city.isNotEmpty ? city : 'City',
      'state': state.isNotEmpty ? state : 'State',
      'postal_code': postalCode.isNotEmpty ? postalCode : '000000',
      'is_default': _addrIsDefault,
    };

    setState(() => _isSavingAddress = true);
    if (_editingAddressTarget != null) {
      final res = await ApiService.updateAddress(
        _editingAddressTarget!.id,
        payload,
      );
      if (mounted) {
        setState(() => _isSavingAddress = false);
        if (res['success'] == true) {
          _cancelAddressEdit();
          _loadAddresses();
          _showMessage('Address updated successfully!');
        } else {
          _showMessage(
            res['message'] ?? 'Could not update address.',
            isError: true,
          );
        }
      }
    } else {
      final res = await ApiService.createAddress(payload);
      if (mounted) {
        setState(() => _isSavingAddress = false);
        if (res['success'] == true) {
          _cancelAddressEdit();
          _loadAddresses();
          _showMessage('Address added successfully!');
        } else {
          _showMessage(
            res['message'] ?? 'Could not save address.',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _deleteAddress(AddressModel addr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address?'),
        content: Text('Are you sure you want to delete "${addr.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.deleteAddress(addr.id);
      if (ok) {
        _loadAddresses();
        _showMessage('Address deleted.');
      } else {
        _showMessage('Could not delete address.', isError: true);
      }
    }
  }

  Future<void> _makeDefaultAddress(AddressModel addr) async {
    final ok = await ApiService.setDefaultAddress(addr.id);
    if (ok) {
      _loadAddresses();
      _showMessage('Default address updated.');
    } else {
      _showMessage('Could not update default address.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = MockAuthService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Account')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 80,
                  color: AppTheme.slateMuted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please sign in to view and manage your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.slateDark),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('SIGN IN NOW'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          'Your Account',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.slateDark,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            onPressed: () async {
              final nav = Navigator.of(context);
              await ApiService.logout();
              if (!mounted) return;
              nav.pop();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.emeraldPrimary,
              indicatorWeight: 3,
              labelColor: AppTheme.emeraldPrimary,
              unselectedLabelColor: AppTheme.slateMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.person_outline, size: 18),
                  text: 'Profile',
                ),
                Tab(
                  icon: Icon(Icons.location_on_outlined, size: 18),
                  text: 'Addresses',
                ),
                Tab(
                  icon: Icon(Icons.credit_card_outlined, size: 18),
                  text: 'Payments',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Signed in Eyebrow Banner (matching web)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.emeraldPrimary.withAlpha(20),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.emeraldPrimary.withAlpha(38),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.emeraldPrimary,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signed in as ${user.email}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.emeraldPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.slateDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(user),
                _buildAddressesTab(user),
                _buildPaymentMethodsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: PROFILE
  // ==========================================
  Widget _buildProfileTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Personal Details Card
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slateDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: AppTheme.emeraldPrimary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+1 555 987 6543',
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppTheme.emeraldPrimary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Web matching email note
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Email (${user.email}) is used to sign in and cannot be changed here — contact support to update it.",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSavingProfile
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save profile',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Change Password Card (matching web)
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slateDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppTheme.slateMuted,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      hintText: 'min 8 characters',
                      prefixIcon: const Icon(
                        Icons.lock_reset,
                        color: AppTheme.emeraldPrimary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: const Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.emeraldPrimary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUpdatingPassword ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUpdatingPassword
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update password',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Navigation Links
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            leading: const Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.emeraldPrimary,
            ),
            title: const Text(
              'Order History',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('View receipts and reorder items'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            leading: const Icon(
              Icons.support_agent,
              color: AppTheme.coralAccent,
            ),
            title: const Text(
              'Customer Care & Support',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('24/7 Live chat resolution'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: ADDRESSES
  // ==========================================
  Widget _buildAddressesTab(UserModel user) {
    if (_isEditingAddress) {
      return _buildAddressForm();
    }

    if (_isLoadingAddresses) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.emeraldPrimary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAddresses,
      color: AppTheme.emeraldPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Addresses (${_addresses.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.slateDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _startAddAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Add address',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_addresses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 60,
                      color: AppTheme.slateMuted,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No saved addresses yet.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.slateMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _startAddAddress,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add your first address'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.emeraldPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._addresses.map((addr) => _buildAddressCard(addr)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressModel addr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: addr.isDefault
            ? const BorderSide(color: AppTheme.emeraldPrimary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(addr.tagIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  addr.label.isNotEmpty ? addr.label : 'Address',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.slateDark,
                  ),
                ),
                if (addr.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldPrimary.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: AppTheme.emeraldPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (addr.name != null && addr.name!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                addr.name!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slateDark,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              addr.fullAddress,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!addr.isDefault)
                  TextButton(
                    onPressed: () => _makeDefaultAddress(addr),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.emeraldPrimary,
                    ),
                    child: const Text(
                      'Make default',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => _startEditAddress(addr),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.slateDark,
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => _deleteAddress(addr),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                  ),
                  child: const Text('Delete', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm() {
    final isEditing = _editingAddressTarget != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit address' : 'New address',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slateDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _cancelAddressEdit,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addrLabelController,
                decoration: InputDecoration(
                  labelText: 'Label',
                  hintText: 'Home, Work...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addrNameController,
                decoration: InputDecoration(
                  labelText: 'Full name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addrLine1Controller,
                decoration: InputDecoration(
                  labelText: 'Address line 1 *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addrLine2Controller,
                decoration: InputDecoration(
                  labelText: 'Address line 2 (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _addrCityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _addrStateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _addrZipController,
                      decoration: InputDecoration(
                        labelText: 'ZIP code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _addrIsDefault,
                onChanged: (val) =>
                    setState(() => _addrIsDefault = val ?? false),
                title: const Text(
                  'Use as my default address',
                  style: TextStyle(fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.emeraldPrimary,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSavingAddress ? null : _saveAddressForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSavingAddress
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'Save address' : 'Add address',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _cancelAddressEdit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCards() async {
    if (ApiService.stripePublishableKey.isEmpty) {
      if (mounted) {
        setState(() {
          _cards = [];
          _isLoadingCards = false;
        });
      }
      return;
    }
    setState(() => _isLoadingCards = true);
    try {
      final cards = await ApiService.getPaymentMethods();
      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoadingCards = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCards = false;
        });
      }
    }
  }

  Future<void> _addCard() async {
    // The Stripe card form runs in a phone web view; not available in the browser preview.
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adding a card works in the Android / iPhone app, or on the website.')),
      );
      return;
    }
    if (ApiService.stripePublishableKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card payments are not configured.')),
      );
      return;
    }
    setState(() => _isAddingCard = true);
    try {
      final secret = await ApiService.createSetupIntent();
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SetupCardScreen(
            clientSecret: secret,
            publishableKey: ApiService.stripePublishableKey,
          ),
        ),
      );
      if (saved == true && mounted) {
        await _loadCards();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card saved to your account.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isAddingCard = false);
    }
  }

  Future<void> _setDefaultCard(String id) async {
    try {
      await ApiService.setDefaultPaymentMethod(id);
      await _loadCards();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Default card updated.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteCard(String id, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove card?'),
        content: Text('Remove $label from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deletePaymentMethod(id);
      await _loadCards();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Card removed.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ==========================================
  // TAB 3: PAYMENT METHODS
  // ==========================================
  Widget _buildPaymentMethodsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.emeraldPrimary, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldPrimary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppTheme.emeraldPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Cash on Delivery (COD)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.slateDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldPrimary.withAlpha(38),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: AppTheme.emeraldPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pay via Cash, UPI, or QR code when your order is delivered.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Saved cards',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.slateDark,
                ),
              ),
            ),
            if (_isLoadingCards)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadCards,
                icon: const Icon(Icons.refresh, size: 20),
              ),
          ],
        ),
        if (ApiService.stripePublishableKey.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Card payments are not configured on this store yet.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          )
        else if (!_isLoadingCards && _cards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No saved cards yet. Add one below or at checkout.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        ..._cards.map((c) {
          final brand = (c['brand'] ?? 'Card').toString();
          final last4 = (c['last4'] ?? '****').toString();
          final exp = '${c['exp_month']}/${c['exp_year']}';
          final isDefault = c['is_default'] == true;
          final id = c['id']?.toString() ?? '';
          final label = '$brand ···· $last4';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDefault
                    ? AppTheme.emeraldPrimary
                    : Colors.grey.shade300,
                width: isDefault ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Expires $exp${isDefault ? ' · Default' : ''}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'default') _setDefaultCard(id);
                  if (v == 'delete') _deleteCard(id, label);
                },
                itemBuilder: (_) => [
                  if (!isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Make default'),
                    ),
                  const PopupMenuItem(value: 'delete', child: Text('Remove')),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isAddingCard ? null : _addCard,
            icon: _isAddingCard
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_card),
            label: Text(_isAddingCard ? 'Opening card form…' : 'Add new card'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppTheme.slateDark,
              side: const BorderSide(color: AppTheme.slateDark),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppTheme.emeraldPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '256-Bit SSL Encrypted',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.slateDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Card details are entered in Stripe’s secure form and never stored on our servers.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
