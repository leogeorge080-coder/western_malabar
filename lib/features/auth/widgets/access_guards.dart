import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/auth/providers/access_provider.dart';
import 'package:western_malabar/shared/widgets/access_denied_view.dart';

class AdminGuard extends ConsumerWidget {
  final Widget child;

  const AdminGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccessAdmin = ref.watch(isAdminProvider);

    if (!canAccessAdmin) {
      return const AccessDeniedView(
        title: 'Admin Access Required',
        message: 'Only administrators can open this section.',
      );
    }

    return child;
  }
}

class DeliveryGuard extends ConsumerWidget {
  final Widget child;

  const DeliveryGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAccessDelivery = ref.watch(canAccessDeliveryProvider);

    if (!canAccessDelivery) {
      return const AccessDeniedView(
        title: 'Delivery Access Required',
        message: 'Only delivery staff or administrators can open this section.',
      );
    }

    return child;
  }
}
