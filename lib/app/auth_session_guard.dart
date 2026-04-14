import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:western_malabar/features/admin/providers/admin_orders_provider.dart';
import 'package:western_malabar/features/auth/providers/access_provider.dart';
import 'package:western_malabar/features/auth/providers/auth_provider.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/checkout/providers/address_provider.dart';
import 'package:western_malabar/features/checkout/providers/checkout_provider.dart';
import 'package:western_malabar/features/profile/providers/profile_provider.dart'
    hide
        canAccessDeliveryProvider,
        canAccessAdminProvider,
        currentUserRoleProvider,
        currentUserProvider;

class AuthSessionGuard extends ConsumerStatefulWidget {
  final Widget child;

  const AuthSessionGuard({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AuthSessionGuard> createState() => _AuthSessionGuardState();
}

class _AuthSessionGuardState extends ConsumerState<AuthSessionGuard> {
  ProviderSubscription<User?>? _authSubscription;
  String? _lastHandledUserId;

  @override
  void initState() {
    super.initState();

    _lastHandledUserId = ref.read(authUserProvider)?.id;

    _authSubscription = ref.listenManual<User?>(
      authUserProvider,
      (previous, next) {
        final previousUserId = previous?.id;
        final nextUserId = next?.id;

        if (previousUserId == nextUserId) return;
        if (_lastHandledUserId == nextUserId) return;

        _lastHandledUserId = nextUserId;
        _handleSessionBoundaryChange();
      },
      fireImmediately: false,
    );
  }

  void _handleSessionBoundaryChange() {
    ref.read(cartProvider.notifier).reset();
    ref.read(checkoutProvider.notifier).reset();

    ref.invalidate(addressesProvider);
    ref.invalidate(defaultAddressProvider);

    ref.invalidate(profileProvider);
    ref.invalidate(accessStateProvider);
    ref.invalidate(isAdminProvider);
    ref.invalidate(canAccessDeliveryProvider);

    ref.invalidate(adminOrdersProvider);
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
