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
import 'package:western_malabar/features/rewards/screens/rewards_screen.dart';
import 'package:western_malabar/features/seller/providers/seller_session_provider.dart';
import 'package:western_malabar/features/seller/screens/seller_products_screen.dart';

final profileAuthBusyProvider = StateProvider<bool>((ref) => false);

const _wmProfileBg = Color(0xFFF7F7F7);
const _wmProfileSurface = Colors.white;
const _wmProfileBorder = Color(0xFFE5E7EB);

const _wmProfileTextStrong = Color(0xFF111827);
const _wmProfileTextSoft = Color(0xFF6B7280);
const _wmProfileTextMuted = Color(0xFF9CA3AF);

const _wmProfilePrimary = Color(0xFF2A2F3A);
const _wmProfilePrimaryDark = Color(0xFF171A20);

const _wmProfileAmber = Color(0xFFF59E0B);
const _wmProfileAmberDark = Color(0xFFD97706);
const _wmProfileAmberSoft = Color(0xFFFFF7ED);

const _wmProfileSuccess = Color(0xFF15803D);
const _wmProfileDanger = Color(0xFFDC2626);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? authUser = ref.watch(authUserProvider);

    final bool isActuallySignedIn = authUser != null && !(authUser.isAnonymous);
    final access = ref.watch(accessStateProvider);

    return Scaffold(
      backgroundColor: _wmProfileBg,
      body: SafeArea(
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
                                message: 'Profile not found for this account.',
                                onRetry: () => ref.invalidate(profileProvider),
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
                                  listen: false,
                                );
                                final messenger = ScaffoldMessenger.of(context);

                                final busy =
                                    container.read(profileAuthBusyProvider);
                                if (busy) return;

                                final busyNotifier = container
                                    .read(profileAuthBusyProvider.notifier);

                                busyNotifier.state = true;

                                try {
                                  container.read(cartProvider.notifier).reset();
                                  container
                                      .read(checkoutProvider.notifier)
                                      .reset();

                                  await container
                                      .read(authServiceProvider)
                                      .signOut();

                                  container.invalidate(cartProvider);
                                  container.invalidate(checkoutProvider);
                                  container.invalidate(addressesProvider);
                                  container.invalidate(defaultAddressProvider);
                                  container.invalidate(profileProvider);
                                  container.invalidate(accessStateProvider);
                                  container.invalidate(authUserProvider);
                                  container.invalidate(sellerSessionProvider);

                                  if (!context.mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Signed out successfully'),
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
                color: _wmProfileTextStrong,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _wmProfileSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _wmProfileBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onSettingsTap,
              icon: const Icon(
                Icons.settings_outlined,
                color: _wmProfilePrimary,
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
                        _wmProfilePrimaryDark,
                        _wmProfilePrimary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
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
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
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
                          color: Colors.white.withOpacity(0.92),
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
                                    listen: false,
                                  );
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
                                    color: _wmProfilePrimary,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            isBusy ? 'Signing in...' : 'Continue with Google',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _wmProfilePrimary,
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
                    color: _wmProfileTextSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'App Version 1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: _wmProfileTextMuted,
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
    final hasSellerAccess = sellerSessionAsync.maybeWhen(
      data: (session) => session.isSeller && session.isActive,
      orElse: () => false,
    );
    final showWorkTools = _showAdminAccess || hasSellerAccess;
    final heroRoleLabel = hasSellerAccess && !_showAdminAccess
        ? 'Seller'
        : (showWorkTools ? roleLabel : null);

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
            roleLabel: heroRoleLabel,
          ),
          const SizedBox(height: 14),
          _RewardsCard(profile: profile),
          const SizedBox(height: 14),
          _InfoSectionCard(
            title: 'Account',
            subtitle:
                'Everything related to your shopping identity and preferences.',
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
                  subtitle: 'Preferred delivery timings coming soon',
                ),
                const SizedBox(height: 10),
                _ProfileMenuTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Malabar Rewards',
                  subtitle: profile.rewardWalletFormatted == '£0.00'
                      ? 'Track points and unlock offers'
                      : '${profile.rewardWalletFormatted} available',
                  onTap: isBusy
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RewardsScreen(),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
          if (showWorkTools) ...[
            const SizedBox(height: 14),
            _InfoSectionCard(
              title: 'Work Tools',
              subtitle:
                  'Operational shortcuts stay separate from your customer account.',
              child: Column(
                children: [
                  _WorkModeBadge(
                    isAdmin: isAdmin,
                    canAccessAdmin: canAccessAdmin,
                    canAccessDelivery: canAccessDelivery,
                    hasSellerAccess: hasSellerAccess,
                    roleLabel: roleLabel,
                  ),
                  if (canAccessAdmin) ...[
                    const SizedBox(height: 10),
                    _ProfileMenuTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Admin Orders',
                      subtitle: 'Review customer orders and operational queues',
                      onTap: isBusy
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdminGuard(
                                    child: AdminOrdersScreen(),
                                  ),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 10),
                    _ProfileMenuTile(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Product Operations',
                      subtitle: 'Manage catalog, stock, and product visibility',
                      onTap: isBusy
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdminGuard(
                                    child: AdminProductsScreen(),
                                  ),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 10),
                    _ProfileMenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Finance Dashboard',
                      subtitle:
                          'View finance metrics and payout-relevant totals',
                      onTap: isBusy
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdminGuard(
                                    child: AdminFinanceScreen(),
                                  ),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: 10),
                    _ProfileMenuTile(
                      icon: Icons.rule_folder_outlined,
                      title: 'Product Requests',
                      subtitle:
                          'Moderate catalog suggestions and supplier requests',
                      onTap: isBusy
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdminGuard(
                                    child: AdminProductRequestsScreen(),
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                  if (canAccessDelivery) ...[
                    const SizedBox(height: 10),
                    _ProfileMenuTile(
                      icon: Icons.local_shipping_rounded,
                      title: 'Delivery Workflow',
                      subtitle:
                          'Open driver mode, delivery queues, and handoff tasks',
                      onTap: isBusy
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const DeliveryOrdersScreen(),
                                ),
                              );
                            },
                    ),
                  ],
                  if (hasSellerAccess) ...[
                    const SizedBox(height: 10),
                    _ProfileMenuTile(
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
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const _InfoSectionCard(
            title: 'Support',
            subtitle: 'Help, policies, and store information.',
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
                        color: _wmProfilePrimary,
                      ),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(
                isBusy ? 'Signing out...' : 'Sign Out',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _wmProfilePrimary,
                side: const BorderSide(color: _wmProfileBorder),
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _wmProfileSurface,
                disabledForegroundColor: _wmProfileTextMuted,
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
              color: _wmProfileTextSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'App Version 1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: _wmProfileTextMuted,
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
            _wmProfilePrimaryDark,
            _wmProfilePrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
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
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.16),
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
                        color: Color(0xFFE5E7EB),
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
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.16),
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
    final bg = filled ? Colors.white : Colors.white.withOpacity(0.08);
    final fg = filled ? _wmProfilePrimary : Colors.white;
    final border = filled ? Colors.white : Colors.white.withOpacity(0.65);

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
            _wmProfilePrimaryDark,
            _wmProfilePrimary,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
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
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
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
                      color: Colors.white.withOpacity(0.92),
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
                      color: Colors.white.withOpacity(0.92),
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

class _WorkModeBadge extends StatelessWidget {
  const _WorkModeBadge({
    required this.isAdmin,
    required this.canAccessAdmin,
    required this.canAccessDelivery,
    required this.hasSellerAccess,
    required this.roleLabel,
  });

  final bool isAdmin;
  final bool canAccessAdmin;
  final bool canAccessDelivery;
  final bool hasSellerAccess;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final title =
        isAdmin ? 'Work mode is available' : 'Operations access enabled';
    final subtitle = isAdmin
        ? 'Admin tools are separated here so your account stays customer-first.'
        : canAccessDelivery
            ? 'Delivery workflow lives here, separate from your personal account.'
            : 'Use this section for operational shortcuts only when you need them.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_wmProfilePrimaryDark, _wmProfilePrimary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Icon(
              isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : canAccessDelivery
                      ? Icons.local_shipping_rounded
                      : Icons.storefront_outlined,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Text(
              hasSellerAccess && !canAccessAdmin && !canAccessDelivery
                  ? 'Seller'
                  : roleLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
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
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
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
        color: _wmProfileSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFED7AA)),
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
                      _wmProfileAmber,
                      Color(0xFFFBBF24),
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
                        color: _wmProfileTextStrong,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Earn points on every order',
                      style: TextStyle(
                        fontSize: 13,
                        color: _wmProfileTextSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: null,
                child: Text(
                  'Redeem',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _wmProfileTextMuted,
                  ),
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
                  valueColor: _wmProfilePrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: 'Next Reward',
                  value: '${profile.nextRewardAt} pts',
                  valueColor: _wmProfileAmberDark,
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
              backgroundColor: const Color(0xFFFDE7C7),
              valueColor: const AlwaysStoppedAnimation<Color>(
                _wmProfileAmber,
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
              color: _wmProfileTextSoft,
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
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmProfileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _wmProfileTextSoft,
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
  final String? subtitle;
  final Widget child;

  const _InfoSectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _wmProfileSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _wmProfileBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
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
              color: _wmProfileTextStrong,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _wmProfileTextSoft,
                height: 1.35,
              ),
            ),
          ],
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
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _wmProfileBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: _wmProfilePrimary,
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
                        color: _wmProfileTextStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _wmProfileTextSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                onTap == null
                    ? Icons.schedule_rounded
                    : Icons.chevron_right_rounded,
                color: _wmProfileTextMuted,
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
        color: _wmProfilePrimary,
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
            color: _wmProfileSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _wmProfileBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: _wmProfileDanger,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _wmProfileTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _wmProfileTextSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wmProfilePrimary,
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
