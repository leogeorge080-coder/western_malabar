import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/checkout/models/address_model.dart';
import 'package:western_malabar/features/checkout/providers/address_provider.dart';
import 'package:western_malabar/features/profile/providers/profile_provider.dart';

const _wmAddrBg = Color(0xFFF7F7F7);
const _wmAddrSurface = Colors.white;
const _wmAddrBorder = Color(0xFFE5E7EB);

const _wmAddrTextStrong = Color(0xFF111827);
const _wmAddrTextSoft = Color(0xFF6B7280);
const _wmAddrTextMuted = Color(0xFF9CA3AF);

const _wmAddrPrimary = Color(0xFF2A2F3A);
const _wmAddrPrimaryDark = Color(0xFF171A20);

const _wmAddrSuccess = Color(0xFF15803D);
const _wmAddrSuccessSoft = Color(0xFFECFDF5);
const _wmAddrDanger = Color(0xFFDC2626);

class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends ConsumerState<SavedAddressesScreen> {
  bool _isBusy = false;

  Future<void> _refreshAll() async {
    ref.invalidate(addressesProvider);
    ref.invalidate(defaultAddressProvider);
    ref.invalidate(profileProvider);
    await ref.read(addressesProvider.future);
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddressEditorSheet(),
    );

    if (result == true) {
      await _refreshAll();
    }
  }

  Future<void> _openEditSheet(AddressModel address) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressEditorSheet(existing: address),
    );

    if (result == true) {
      await _refreshAll();
    }
  }

  Future<void> _setDefault(AddressModel address) async {
    if (_isBusy || address.isDefault) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(addressServiceProvider).setDefaultAddress(address.id);

      if (!mounted) return;
      await _refreshAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${address.label} set as default address'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set default address: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    if (_isBusy) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: _wmAddrSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Delete address?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _wmAddrTextStrong,
              ),
            ),
            content: Text(
              'Remove "${address.label}" from your saved addresses?',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _wmAddrTextSoft,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wmAddrDanger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isBusy = true);
    try {
      await ref.read(addressServiceProvider).deleteAddress(address.id);

      if (!mounted) return;
      await _refreshAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${address.label} deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete address: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: _wmAddrBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBusy ? null : _openAddSheet,
        backgroundColor: _wmAddrPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          'Add Address',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _SavedAddressesHeader(),
            Expanded(
              child: addressesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: _wmAddrPrimary,
                  ),
                ),
                error: (error, _) => _SavedAddressesErrorView(
                  message: error.toString(),
                  onRetry: _refreshAll,
                ),
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return _EmptySavedAddressesView(
                      onAddTap: _openAddSheet,
                    );
                  }

                  return RefreshIndicator(
                    color: _wmAddrPrimary,
                    onRefresh: _refreshAll,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                      children: [
                        _SavedAddressesIntroCard(
                          count: addresses.length,
                        ),
                        const SizedBox(height: 14),
                        ...addresses.map(
                          (address) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AddressCard(
                              address: address,
                              isBusy: _isBusy,
                              onSetDefault: () => _setDefault(address),
                              onEdit: () => _openEditSheet(address),
                              onDelete: () => _deleteAddress(address),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _SavedAddressesHeader extends StatelessWidget {
  const _SavedAddressesHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _wmAddrPrimary,
            ),
          ),
          const Expanded(
            child: Text(
              'Saved Addresses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _wmAddrTextStrong,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SavedAddressesIntroCard extends StatelessWidget {
  final int count;

  const _SavedAddressesIntroCard({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _wmAddrPrimaryDark,
            _wmAddrPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Address Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count saved address${count == 1 ? '' : 'es'} ready for faster checkout.',
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isBusy;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.isBusy,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = address.isDefault;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _wmAddrSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDefault ? const Color(0xFFA7F3D0) : _wmAddrBorder,
          width: isDefault ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      isDefault ? _wmAddrSuccessSoft : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  address.label.toLowerCase() == 'work'
                      ? Icons.business_center_outlined
                      : Icons.home_rounded,
                  color: isDefault ? _wmAddrSuccess : _wmAddrPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _wmAddrTextStrong,
                            ),
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _wmAddrSuccess,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _wmAddrTextStrong,
                      ),
                    ),
                    if (address.phone.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        address.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _wmAddrTextSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _wmAddrBorder,
              ),
            ),
            child: Text(
              address.shortDisplay,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _wmAddrTextSoft,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (!isDefault)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onSetDefault,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      'Set Default',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _wmAddrPrimary,
                      side: const BorderSide(color: _wmAddrPrimary),
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              if (!isDefault) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wmAddrPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: isBusy ? null : onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(
                'Delete Address',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _wmAddrDanger,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySavedAddressesView extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptySavedAddressesView({
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _wmAddrSurface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _wmAddrBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _wmAddrPrimaryDark,
                      _wmAddrPrimary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.add_location_alt_outlined,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No saved addresses yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _wmAddrTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your home or work address for faster checkout and smoother repeat orders.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _wmAddrTextSoft,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAddTap,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add Your First Address',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wmAddrPrimary,
                    foregroundColor: Colors.white,
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
      ],
    );
  }
}

class _SavedAddressesErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _SavedAddressesErrorView({
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _wmAddrSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _wmAddrBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: _wmAddrDanger,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load addresses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _wmAddrTextStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _wmAddrTextSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wmAddrPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressEditorSheet extends ConsumerStatefulWidget {
  final AddressModel? existing;

  const _AddressEditorSheet({
    this.existing,
  });

  @override
  ConsumerState<_AddressEditorSheet> createState() =>
      _AddressEditorSheetState();
}

class _AddressEditorSheetState extends ConsumerState<_AddressEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _countyController;
  late final TextEditingController _deliveryNoteController;

  late bool _isDefault;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final address = widget.existing;

    _labelController = TextEditingController(text: address?.label ?? 'Home');
    _fullNameController = TextEditingController(text: address?.fullName ?? '');
    _phoneController = TextEditingController(text: address?.phone ?? '');
    _postcodeController = TextEditingController(text: address?.postcode ?? '');
    _addressLine1Controller =
        TextEditingController(text: address?.addressLine1 ?? '');
    _addressLine2Controller =
        TextEditingController(text: address?.addressLine2 ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _countyController = TextEditingController(text: address?.county ?? '');
    _deliveryNoteController =
        TextEditingController(text: address?.deliveryNote ?? '');

    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _postcodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final label = _labelController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final postcode = _postcodeController.text.trim().toUpperCase();
    final addressLine1 = _addressLine1Controller.text.trim();
    final addressLine2 = _addressLine2Controller.text.trim();
    final city = _cityController.text.trim();
    final county = _countyController.text.trim();
    final deliveryNote = _deliveryNoteController.text.trim();

    if (label.isEmpty ||
        fullName.isEmpty ||
        phone.isEmpty ||
        postcode.isEmpty ||
        addressLine1.isEmpty ||
        city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required address details'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final service = ref.read(addressServiceProvider);

      if (_isEdit) {
        await service.updateAddress(
          widget.existing!.copyWith(
            label: label,
            fullName: fullName,
            phone: phone,
            postcode: postcode,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            city: city,
            county: county.isEmpty ? null : county,
            deliveryNote: deliveryNote.isEmpty ? null : deliveryNote,
            isDefault: _isDefault,
          ),
        );
      } else {
        await service.addAddress(
          AddressModel(
            id: '',
            userId: '',
            label: label,
            fullName: fullName,
            phone: phone,
            postcode: postcode,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            city: city,
            county: county.isEmpty ? null : county,
            deliveryNote: deliveryNote.isEmpty ? null : deliveryNote,
            isDefault: _isDefault,
            latitude: null,
            longitude: null,
            createdAt: null,
            updatedAt: null,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Failed to update address: $e'
                : 'Failed to add address: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _wmAddrSurface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      _isEdit
                          ? Icons.edit_location_alt_outlined
                          : Icons.add_location_alt_outlined,
                      color: _wmAddrPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit Address' : 'Add New Address',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _wmAddrTextStrong,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _EditorTextField(
                  label: 'Label',
                  controller: _labelController,
                  hintText: 'Home, Work, Parents...',
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  label: 'Full Name',
                  controller: _fullNameController,
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  label: 'Postcode',
                  controller: _postcodeController,
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  label: 'Address Line 1',
                  controller: _addressLine1Controller,
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  label: 'Address Line 2',
                  controller: _addressLine2Controller,
                  hintText: 'Optional',
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  label: 'City',
                  controller: _cityController,
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  label: 'County',
                  controller: _countyController,
                  hintText: 'Optional',
                ),
                const SizedBox(height: 12),
                _EditorTextField(
                  label: 'Delivery Note',
                  controller: _deliveryNoteController,
                  hintText: 'Optional',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _wmAddrBorder),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set as default address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _wmAddrTextStrong,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This address will be shown first during checkout.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _wmAddrTextSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isDefault,
                        activeColor: _wmAddrPrimary,
                        onChanged: (value) {
                          setState(() => _isDefault = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _wmAddrPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Save Changes' : 'Add Address',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _EditorTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(
          color: _wmAddrTextSoft,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: _wmAddrTextMuted,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _wmAddrBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _wmAddrPrimary, width: 1.2),
        ),
      ),
    );
  }
}
