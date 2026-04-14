import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/admin/screens/admin_finance_screen.dart';
import 'package:western_malabar/features/admin/screens/admin_orders_screen.dart';
import 'package:western_malabar/features/admin/screens/admin_products_screen.dart';
import 'package:western_malabar/features/delivery/screens/delivery_orders_screen.dart';
import 'package:western_malabar/features/admin_product_requests/screens/admin_product_requests_screen.dart';
import 'package:western_malabar/features/auth/providers/access_provider.dart';
import 'package:western_malabar/features/auth/providers/auth_provider.dart';
import 'package:western_malabar/features/auth/widgets/access_guards.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';
import 'package:western_malabar/features/checkout/providers/address_provider.dart';
import 'package:western_malabar/features/checkout/providers/checkout_provider.dart';
import 'package:western_malabar/features/checkout/screens/saved_addresses_screen.dart';
import 'package:western_malabar/features/orders/screens/my_orders_screen.dart';
import 'package:western_malabar/features/profile/models/profile_model.dart';
import 'package:western_malabar/features/profile/providers/profile_provider.dart';
import 'package:western_malabar/features/seller/providers/seller_session_provider.dart';
import 'package:western_malabar/features/seller/screens/seller_products_screen.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';

final profileAuthBusyProvider = StateProvider<bool>((ref) => false);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? authUser = ref.watch(authUserProvider);

    final bool isActuallySignedIn = authUser != null && !(authUser.isAnonymous);
    final access = ref.watch(accessStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: !isActuallySignedIn
              ? const _SignedOutProfileView()
              : Column(
                  children: [
                    _ProfileTopBar(
                      title: 'My Profile',
                      onSettingsTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings coming soon'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ref.watch(profileProvider).when(
                            loading: () => const _ProfileLoadingView(),
                            error: (Object error, StackTrace _) =>
                                _ProfileErrorView(
                              message: error.toString(),
                              onRetry: () => ref.invalidate(profileProvider),
                            ),
                            data: (ProfileModel? profile) {
                              if (profile == null) {
                                return _ProfileErrorView(
                                  message:
                                      'Profile not found for this account.',
                                  onRetry: () =>
                                      ref.invalidate(profileProvider),
                                );
                              }

                              return _SignedInProfileContent(
                                profile: profile,
                                authUser: authUser,
                                isAdmin: access.isAdmin,
                                canAccessAdmin: access.canAccessAdmin,
                                canAccessDelivery: access.canAccessDelivery,
                                roleLabel: access.effectiveRoleLabel,
                                onSignOut: () async {
                                  final container = ProviderScope.containerOf(
                                      context,
                                      listen: false);
                                  final messenger =
                                      ScaffoldMessenger.of(context);

                                  final busy =
                                      container.read(profileAuthBusyProvider);
                                  if (busy) return;

                                  final busyNotifier = container
                                      .read(profileAuthBusyProvider.notifier);

                                  busyNotifier.state = true;

                                  try {
                                    container
                                        .read(cartProvider.notifier)
                                        .reset();
                                    container
                                        .read(checkoutProvider.notifier)
                                        .reset();

                                    await container
                                        .read(authServiceProvider)
                                        .signOut();

                                    container.invalidate(cartProvider);
                                    container.invalidate(checkoutProvider);
                                    container.invalidate(addressesProvider);
                                    container
                                        .invalidate(defaultAddressProvider);
                                    container.invalidate(profileProvider);
                                    container.invalidate(accessStateProvider);
                                    container.invalidate(authUserProvider);
                                    container.invalidate(sellerSessionProvider);

                                    if (!context.mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Signed out successfully'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Sign out failed: $e'),
                                      ),
                                    );
                                  } finally {
                                    busyNotifier.state = false;
                                  }
                                },
                              );
                            },
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onSettingsTap;

  const _ProfileTopBar({
    required this.title,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onSettingsTap,
              icon: const Icon(
                Icons.settings_outlined,
                color: WMTheme.royalPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutProfileView extends ConsumerWidget {
  const _SignedOutProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(profileAuthBusyProvider);

    return Column(
      children: [
        _ProfileTopBar(
          title: 'My Profile',
          onSettingsTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings coming soon')),
            );
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        WMTheme.royalPurple,
                        Color(0xFF8753C4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sign in for faster checkout',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save addresses, view order history, track deliveries, and access rewards with one tap.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isBusy
                              ? null
                              : () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final container = ProviderScope.containerOf(
                                      context,
                                      listen: false);
                                  final busyNotifier = container
                                      .read(profileAuthBusyProvider.notifier);
                                  final authService =
                                      container.read(authServiceProvider);

                                  busyNotifier.state = true;

                                  try {
                                    await authService.signInWithGoogle();

                                    if (!context.mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Signed in successfully'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Google sign-in failed: $e',
                                        ),
                                      ),
                                    );
                                  } finally {
                                    busyNotifier.state = false;
                                  }
                                },
                          icon: isBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: WMTheme.royalPurple,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            isBusy ? 'Signing in...' : 'Continue with Google',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: WMTheme.royalPurple,
                            minimumSize: const Size.fromHeight(54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SignedOutBenefitsCard(),
                const SizedBox(height: 16),
                const _InfoSectionCard(
                  title: 'Support',
                  child: Column(
                    children: [
                      _ProfileMenuTile(
                        icon: Icons.headset_mic_outlined,
                        title: 'Help & Support',
                        subtitle: 'Need help with an order or delivery?',
                      ),
                      SizedBox(height: 10),
                      _ProfileMenuTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About Western Malabar',
                        subtitle: 'Learn more about our store',
                      ),
                      SizedBox(height: 10),
                      _ProfileMenuTile(
                        icon: Icons.policy_outlined,
                        title: 'Privacy & Terms',
                        subtitle: 'Read our store policies',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Western Malabar • UK Kerala Grocery',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignedOutBenefitsCard extends StatelessWidget {
  const _SignedOutBenefitsCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoSectionCard(
      title: 'Why sign in?',
      child: Column(
        children: [
          _ProfileMenuTile(
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            subtitle: 'Checkout faster with saved delivery locations',
          ),
          SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.receipt_long_rounded,
            title: 'Order History',
            subtitle: 'Track current and previous orders easily',
          ),
          SizedBox(height: 10),
          _ProfileMenuTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Rewards',
            subtitle: 'Earn and redeem points on your purchases',
          ),
        ],
      ),
    );
  }
}

class _SignedInProfileContent extends ConsumerWidget {
  final ProfileModel profile;
  final User authUser;
  final bool isAdmin;
  final bool canAccessAdmin;
  final bool canAccessDelivery;
  final String roleLabel;
  final Future<void> Function() onSignOut;

  const _SignedInProfileContent({
    required this.profile,
    required this.authUser,
    required this.isAdmin,
    required this.canAccessAdmin,
    required this.canAccessDelivery,
    required this.roleLabel,
    required this.onSignOut,
  });

  bool get _showAdminAccess => canAccessAdmin || canAccessDelivery;

  String get _displayName {
    final authName =
        (authUser.userMetadata?['full_name'] ?? authUser.userMetadata?['name'])
            ?.toString()
            .trim();
    if (authName != null && authName.isNotEmpty) return authName;
    if (profile.fullName.trim().isNotEmpty) return profile.fullName.trim();
    return 'User';
  }

  String get _displayEmail {
    final email = (authUser.email ?? '').trim();
    if (email.isNotEmpty) return email;
    return profile.email;
  }

  String get _displayPhone {
    final phone = profile.phone.trim();
    return phone;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(profileAuthBusyProvider);
    final sellerSessionAsync = ref.watch(sellerSessionProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        children: [
          _ProfileHeroCard(
            initials: _initialsFromName(_displayName),
            fullName: _displayName,
            email: _displayEmail,
            phone: _displayPhone,
            rewardPoints: profile.rewardPoints,
            totalOrders: profile.totalOrders,
            roleLabel: _showAdminAccess ? roleLabel : null,
          ),
          if (_showAdminAccess) ...[
            const SizedBox(height: 14),
            _OperationsAccessCard(
              isAdmin: isAdmin,
              canAccessAdmin: canAccessAdmin,
              canAccessDelivery: canAccessDelivery,
              roleLabel: roleLabel,
            ),
          ],
          const SizedBox(height: 14),
          _InfoSectionCard(
            title: 'Account',
            child: Column(
              children: [
                _ProfileMenuTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  subtitle: '${profile.totalOrders} orders placed',
                  onTap: isBusy
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MyOrdersScreen(),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final addressesAsync = ref.watch(addressesProvider);

                    final subtitle = addressesAsync.when(
                      loading: () => 'Loading saved addresses...',
                      error: (_, __) => 'Saved addresses',
                      data: (List<AddressModel> addresses) =>
                          '${addresses.length} saved address(es)',
                    ) as String;

                    return _ProfileMenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Addresses',
                      subtitle: subtitle,
                      onTap: isBusy
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SavedAddressesScreen(),
                                ),
                              );

                              ref.invalidate(addressesProvider);
                              ref.invalidate(defaultAddressProvider);
                              ref.invalidate(profileProvider);
                            },
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ProfileMenuTile(
                  icon: Icons.access_time_rounded,
                  title: 'Delivery Slots',
                  subtitle: 'Manage preferred delivery timings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery slots screen coming soon'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _ProfileMenuTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Malabar Rewards',
                  subtitle: profile.rewardWalletFormatted == '£0.00'
                      ? 'Track points and unlock offers'
                      : '${profile.rewardWalletFormatted} available',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Open the Rewards tab below'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                sellerSessionAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (session) {
                    if (!session.isSeller || !session.isActive) {
                      return const SizedBox.shrink();
                    }

                    return _ProfileMenuTile(
                      icon: Icons.storefront_outlined,
                      title: 'Seller Dashboard',
                      subtitle:
                          'Manage products, stock, visibility, and requests',
                      onTap: isBusy
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SellerProductsScreen(),
                                ),
                              );
                            },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _InfoSectionCard(
            title: 'Support',
            child: Column(
              children: [
                _ProfileMenuTile(
                  icon: Icons.headset_mic_outlined,
                  title: 'Help & Support',
                  subtitle: 'Need help with an order or delivery?',
                ),
                SizedBox(height: 10),
                _ProfileMenuTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Western Malabar',
                  subtitle: 'Learn more about our store',
                ),
                SizedBox(height: 10),
                _ProfileMenuTile(
                  icon: Icons.policy_outlined,
                  title: 'Privacy & Terms',
                  subtitle: 'Read our store policies',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onSignOut,
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: WMTheme.royalPurple,
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(
                isBusy ? 'Signing out...' : 'Sign Out',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: WMTheme.royalPurple,
                side: const BorderSide(color: WMTheme.royalPurple),
                minimumSize: const Size.fromHeight(54),
                backgroundColor: Colors.white.withValues(alpha: 0.94),
                disabledForegroundColor:
                    WMTheme.royalPurple.withValues(alpha: 0.65),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Western Malabar • UK Kerala Grocery',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'App Version 1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _initialsFromName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _OperationsAccessCard extends StatelessWidget {
  final bool isAdmin;
  final bool canAccessAdmin;
  final bool canAccessDelivery;
  final String roleLabel;

  const _OperationsAccessCard({
    required this.isAdmin,
    required this.canAccessAdmin,
    required this.canAccessDelivery,
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final title = isAdmin ? 'Operations Access' : 'Delivery Access';
    final subtitle = isAdmin
        ? 'Admin can manage orders and product operations'
        : 'Access delivery workflow and driver tools';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            WMTheme.royalPurple,
            Color(0xFF8A56C9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.local_shipping_rounded,
                  color: Colors.white,
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
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (canAccessAdmin) ...[
            _OpsActionButton(
              icon: Icons.inventory_2_outlined,
              label: 'Open Admin Orders',
              filled: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminGuard(
                      child: AdminOrdersScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _OpsActionButton(
              icon: Icons.shopping_cart_outlined,
              label: 'Manage Products',
              filled: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminGuard(
                      child: AdminProductsScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _OpsActionButton(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Open Finance Dashboard',
              filled: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminGuard(
                      child: AdminFinanceScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _OpsActionButton(
              icon: Icons.rule_folder_outlined,
              label: 'Moderate Product Requests',
              filled: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminGuard(
                      child: AdminProductRequestsScreen(),
                    ),
                  ),
                );
              },
            ),
            if (canAccessDelivery) const SizedBox(height: 10),
          ],
          if (canAccessDelivery)
            _OpsActionButton(
              icon: Icons.local_shipping_rounded,
              label: 'Open Driver Mode',
              filled: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeliveryOrdersScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _OpsActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _OpsActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? Colors.white : Colors.white.withValues(alpha: 0.08);
    final fg = filled ? WMTheme.royalPurple : Colors.white;
    final border = filled ? Colors.white : Colors.white.withValues(alpha: 0.65);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final String initials;
  final String fullName;
  final String email;
  final String phone;
  final int rewardPoints;
  final int totalOrders;
  final String? roleLabel;

  const _ProfileHeroCard({
    required this.initials,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.rewardPoints,
    required this.totalOrders,
    this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WMTheme.royalPurple,
            Color(0xFF8A56C9),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                if (email.trim().isNotEmpty)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (phone.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniPill(
                      icon: Icons.workspace_premium_rounded,
                      label: '$rewardPoints pts',
                    ),
                    _MiniPill(
                      icon: Icons.shopping_bag_outlined,
                      label: '$totalOrders orders',
                    ),
                    if (roleLabel != null)
                      _MiniPill(
                        icon: Icons.admin_panel_settings_rounded,
                        label: roleLabel!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  final ProfileModel profile;

  const _RewardsCard({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = profile.remainingToNextReward;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF2E4B2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF0C53E),
                      Color(0xFFFFD96A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Malabar Rewards',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Earn points on every order',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: null,
                child: const Text(
                  'Redeem',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Current Points',
                  value: '${profile.rewardPoints}',
                  valueColor: WMTheme.royalPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: 'Next Reward',
                  value: '${profile.nextRewardAt} pts',
                  valueColor: const Color(0xFFF0C53E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: profile.rewardProgress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF2EDF8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                WMTheme.royalPurple,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remaining == 0
                ? 'You are ready to redeem your next reward.'
                : 'Only $remaining more points to unlock your next reward.',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: valueColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCFBFE),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFECE5F6)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EDFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: WMTheme.royalPurple,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: WMTheme.royalPurple,
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WMTheme.royalPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
