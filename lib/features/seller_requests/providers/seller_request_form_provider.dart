import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerRequestFormState {
  final bool submitting;

  const SellerRequestFormState({
    this.submitting = false,
  });

  SellerRequestFormState copyWith({
    bool? submitting,
  }) {
    return SellerRequestFormState(
      submitting: submitting ?? this.submitting,
    );
  }
}

class SellerRequestFormNotifier extends StateNotifier<SellerRequestFormState> {
  SellerRequestFormNotifier() : super(const SellerRequestFormState());

  void setSubmitting(bool value) {
    state = state.copyWith(submitting: value);
  }
}

final sellerRequestFormProvider =
    StateNotifierProvider<SellerRequestFormNotifier, SellerRequestFormState>(
  (_) => SellerRequestFormNotifier(),
);
