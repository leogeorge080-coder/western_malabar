import 'package:flutter_test/flutter_test.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';
import 'package:western_malabar/features/checkout/providers/checkout_provider.dart';

void main() {
  group('CheckoutNotifier', () {
    late CheckoutNotifier notifier;

    setUp(() {
      notifier = CheckoutNotifier();
    });

    AddressModel buildSavedAddress() {
      return const AddressModel(
        id: 'addr-1',
        userId: 'user-1',
        label: 'Home',
        fullName: 'Saved User',
        phone: '07000000000',
        postcode: 'B1 1AA',
        addressLine1: '10 High Street',
        addressLine2: 'Flat 1',
        city: 'Birmingham',
        isDefault: true,
      );
    }

    test('applySavedAddress hydrates address and selection metadata', () {
      final saved = buildSavedAddress();

      notifier.applySavedAddress(saved);

      expect(notifier.state.selectedSavedAddress?.id, saved.id);
      expect(notifier.state.selectedAddressLabel, saved.shortDisplay);
      expect(notifier.state.address.fullName, saved.fullName);
      expect(notifier.state.address.postcode, saved.postcode);
      expect(notifier.state.postcodeEligible, isTrue);
    });

    test('editing postcode clears saved address selection and address details',
        () {
      notifier.applySavedAddress(buildSavedAddress());

      notifier.updatePostcode('E1 6AN');

      expect(notifier.state.selectedSavedAddress, isNull);
      expect(notifier.state.selectedAddressLabel, isEmpty);
      expect(notifier.state.address.postcode, 'E1 6AN');
      expect(notifier.state.address.addressLine1, isEmpty);
      expect(notifier.state.address.addressLine2, isEmpty);
      expect(notifier.state.address.city, isEmpty);
      expect(notifier.state.postcodeEligible, isFalse);
    });

    test('setRewardsSummary clamps negative values and disables empty rewards',
        () {
      notifier.setRewardsSummary(
        availableRewardPence: -100,
        pointsToNextReward: -20,
      );

      expect(notifier.state.availableRewardPence, 0);
      expect(notifier.state.pointsToNextReward, 0);
      expect(notifier.state.useRewards, isFalse);
    });

    test('toggleUseRewards applies available rewards and disables cleanly', () {
      notifier.setRewardsSummary(
        availableRewardPence: 250,
        pointsToNextReward: 50,
      );

      notifier.toggleUseRewards(true);
      expect(notifier.state.useRewards, isTrue);
      expect(notifier.state.appliedRewardPence, 250);

      notifier.toggleUseRewards(false);
      expect(notifier.state.useRewards, isFalse);
      expect(notifier.state.appliedRewardPence, 0);
    });

    test('reconcileRewardUsage caps applied rewards to eligible subtotal', () {
      notifier.setRewardsSummary(
        availableRewardPence: 500,
        pointsToNextReward: 0,
      );
      notifier.toggleUseRewards(true);

      notifier.reconcileRewardUsage(eligibleSubtotalCents: 180);

      expect(notifier.state.useRewards, isTrue);
      expect(notifier.state.appliedRewardPence, 180);
    });

    test('backend summary error clears loaded flag and stores message', () {
      notifier.setBackendSummary(
        subtotalCents: 1000,
        eligibleSubtotalCents: 1000,
        deliveryFeeCents: 200,
        rewardDiscountCents: 0,
        totalCents: 1200,
        pointsToRedeem: 0,
      );

      notifier.setBackendSummaryError('Could not confirm latest basket total.');

      expect(notifier.state.backendSummaryLoaded, isFalse);
      expect(notifier.state.backendSummaryLoading, isFalse);
      expect(notifier.state.backendSummaryError,
          'Could not confirm latest basket total.');
    });
  });
}
