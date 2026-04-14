import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:western_malabar/features/cart/providers/cart_provider.dart';
import 'package:western_malabar/features/catalog/models/product_model.dart';

const _wmAddPrimary = Color(0xFF2A2F3A);
const _wmAddPrimaryDark = Color(0xFF171A20);
const _wmAddBorder = Color(0xFFE5E7EB);
const _wmAddSnackBg = Color(0xFF111827);

class AddToCartControl extends ConsumerWidget {
  const AddToCartControl({
    super.key,
    required this.product,
    this.onAdded,
    this.compact = false,
  });

  final ProductModel product;
  final VoidCallback? onAdded;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(
      cartProvider.select((cart) {
        final item = cart.where((e) => e.product.id == product.id).firstOrNull;
        return item?.qty ?? 0;
      }),
    );

    final config = _AddToCartSizing.from(compact: compact);

    return RepaintBoundary(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerRight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          reverseDuration: const Duration(milliseconds: 140),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            final scale = Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            );
          },
          child: qty == 0
              ? _AddButtonState(
                  key: ValueKey('add-${product.id}-${compact ? 'c' : 'n'}'),
                  product: product,
                  onAdded: onAdded,
                  config: config,
                )
              : _StepperState(
                  key: ValueKey('stepper-${product.id}-${compact ? 'c' : 'n'}'),
                  product: product,
                  qty: qty,
                  onAdded: onAdded,
                  config: config,
                ),
        ),
      ),
    );
  }
}

class _AddToCartSizing {
  final bool compact;
  final double height;
  final double addWidth;
  final double compactWidth;
  final double radius;
  final double iconSize;
  final double sideMin;
  final double qtyMinWidth;
  final EdgeInsets addPadding;
  final double labelFontSize;
  final double qtyFontSize;

  const _AddToCartSizing({
    required this.compact,
    required this.height,
    required this.addWidth,
    required this.compactWidth,
    required this.radius,
    required this.iconSize,
    required this.sideMin,
    required this.qtyMinWidth,
    required this.addPadding,
    required this.labelFontSize,
    required this.qtyFontSize,
  });

  factory _AddToCartSizing.from({required bool compact}) {
    if (compact) {
      return const _AddToCartSizing(
        compact: true,
        height: 36,
        addWidth: 36,
        compactWidth: 96,
        radius: 10,
        iconSize: 17,
        sideMin: 28,
        qtyMinWidth: 18,
        addPadding: EdgeInsets.zero,
        labelFontSize: 12.5,
        qtyFontSize: 12,
      );
    }

    return const _AddToCartSizing(
      compact: false,
      height: 32,
      addWidth: 68,
      compactWidth: 102,
      radius: 12,
      iconSize: 16.5,
      sideMin: 30,
      qtyMinWidth: 22,
      addPadding: EdgeInsets.symmetric(horizontal: 10),
      labelFontSize: 12.8,
      qtyFontSize: 12,
    );
  }
}

class _AddButtonState extends ConsumerStatefulWidget {
  const _AddButtonState({
    super.key,
    required this.product,
    required this.onAdded,
    required this.config,
  });

  final ProductModel product;
  final VoidCallback? onAdded;
  final _AddToCartSizing config;

  @override
  ConsumerState<_AddButtonState> createState() => _AddButtonStateState();
}

class _AddButtonStateState extends ConsumerState<_AddButtonState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 120),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 94),
        backgroundColor: _wmAddSnackBg,
        duration: const Duration(milliseconds: 1200),
        content: const Text(
          'This item is currently unavailable',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    final effectivePrice =
        widget.product.salePriceCents ?? widget.product.priceCents ?? 0;

    if (effectivePrice <= 0) {
      _showUnavailable();
      return;
    }

    await _pressController.forward();
    await _pressController.reverse();

    if (!mounted) return;

    ref.read(cartProvider.notifier).add(widget.product);
    widget.onAdded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.config.compact;

    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        height: widget.config.height,
        width: widget.config.addWidth,
        child: Material(
          color: _wmAddPrimary,
          borderRadius: BorderRadius.circular(widget.config.radius),
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(widget.config.radius),
            splashColor: const Color(0x22FFFFFF),
            highlightColor: const Color(0x14FFFFFF),
            child: Container(
              padding: widget.config.addPadding,
              alignment: Alignment.center,
              child: isCompact
                  ? Icon(
                      Icons.add_rounded,
                      size: widget.config.iconSize,
                      color: Colors.white,
                    )
                  : Text(
                      'Add',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: widget.config.labelFontSize,
                        height: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperState extends ConsumerWidget {
  const _StepperState({
    super.key,
    required this.product,
    required this.qty,
    required this.onAdded,
    required this.config,
  });

  final ProductModel product;
  final int qty;
  final VoidCallback? onAdded;
  final _AddToCartSizing config;

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 94),
        backgroundColor: _wmAddSnackBg,
        duration: const Duration(milliseconds: 1200),
        content: const Text(
          'This item is currently unavailable',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectivePrice = product.salePriceCents ?? product.priceCents ?? 0;

    return Container(
      height: config.height,
      width: config.compactWidth,
      decoration: BoxDecoration(
        color: _wmAddPrimary,
        borderRadius: BorderRadius.circular(config.radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: config.sideMin,
            child: _StepperSideButton(
              icon: Icons.remove_rounded,
              iconSize: config.iconSize,
              minSize: config.sideMin,
              radius: config.radius,
              onTap: () {
                ref.read(cartProvider.notifier).dec(product);
              },
            ),
          ),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '$qty',
                  key: ValueKey('qty-$qty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: config.qtyFontSize,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: config.sideMin,
            child: _StepperSideButton(
              icon: Icons.add_rounded,
              iconSize: config.iconSize,
              minSize: config.sideMin,
              radius: config.radius,
              onTap: () {
                if (effectivePrice <= 0) {
                  _showUnavailable(context);
                  return;
                }

                ref.read(cartProvider.notifier).inc(product);
                onAdded?.call();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperSideButton extends StatefulWidget {
  const _StepperSideButton({
    required this.icon,
    required this.iconSize,
    required this.minSize,
    required this.radius,
    required this.onTap,
  });

  final IconData icon;
  final double iconSize;
  final double minSize;
  final double radius;
  final VoidCallback onTap;

  @override
  State<_StepperSideButton> createState() => _StepperSideButtonState();
}

class _StepperSideButtonState extends State<_StepperSideButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 110),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(widget.radius),
          splashColor: const Color(0x18FFFFFF),
          highlightColor: Colors.transparent,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
