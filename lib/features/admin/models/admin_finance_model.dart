enum AdminFinanceRangeType {
  thisWeek,
  thisMonth,
  custom,
}

class AdminFinanceDateRange {
  final DateTime start;
  final DateTime end;
  final AdminFinanceRangeType type;

  const AdminFinanceDateRange({
    required this.start,
    required this.end,
    required this.type,
  });

  AdminFinanceDateRange copyWith({
    DateTime? start,
    DateTime? end,
    AdminFinanceRangeType? type,
  }) {
    return AdminFinanceDateRange(
      start: start ?? this.start,
      end: end ?? this.end,
      type: type ?? this.type,
    );
  }

  static AdminFinanceDateRange thisWeek() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return AdminFinanceDateRange(
      start: start,
      end: end,
      type: AdminFinanceRangeType.thisWeek,
    );
  }

  static AdminFinanceDateRange thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return AdminFinanceDateRange(
      start: start,
      end: end,
      type: AdminFinanceRangeType.thisMonth,
    );
  }
}

class SellerPayoutModel {
  final String id;
  final String sellerId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int amountCents;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final DateTime? paidAt;

  const SellerPayoutModel({
    required this.id,
    required this.sellerId,
    required this.periodStart,
    required this.periodEnd,
    required this.amountCents,
    required this.status,
    this.note,
    this.createdAt,
    this.paidAt,
  });

  factory SellerPayoutModel.fromMap(Map<String, dynamic> map) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return SellerPayoutModel(
      id: (map['id'] ?? '').toString(),
      sellerId: (map['seller_id'] ?? '').toString(),
      periodStart: DateTime.parse(map['period_start'].toString()),
      periodEnd: DateTime.parse(map['period_end'].toString()),
      amountCents: (map['amount_cents'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? 'pending').toString(),
      note: map['note']?.toString(),
      createdAt: parse(map['created_at']),
      paidAt: parse(map['paid_at']),
    );
  }
}

class AdminPlatformFinanceSummary {
  final int totalOrders;
  final int totalOrderLines;
  final int totalUnitsSold;
  final int grossSalesCents;
  final int sellerPayableCents;
  final int platformMarginCents;

  const AdminPlatformFinanceSummary({
    required this.totalOrders,
    required this.totalOrderLines,
    required this.totalUnitsSold,
    required this.grossSalesCents,
    required this.sellerPayableCents,
    required this.platformMarginCents,
  });

  factory AdminPlatformFinanceSummary.fromMap(Map<String, dynamic> map) {
    return AdminPlatformFinanceSummary(
      totalOrders: (map['total_orders'] as num?)?.toInt() ?? 0,
      totalOrderLines: (map['total_order_lines'] as num?)?.toInt() ?? 0,
      totalUnitsSold: (map['total_units_sold'] as num?)?.toInt() ?? 0,
      grossSalesCents: (map['gross_sales_cents'] as num?)?.toInt() ?? 0,
      sellerPayableCents: (map['seller_payable_cents'] as num?)?.toInt() ?? 0,
      platformMarginCents: (map['platform_margin_cents'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminSellerFinanceSummary {
  final String sellerId;
  final String? sellerName;
  final String? sellerEmail;
  final int totalOrders;
  final int totalOrderLines;
  final int totalUnitsSold;
  final int grossSalesCents;
  final int sellerPayableCents;
  final int platformMarginCents;
  final int paidCents;
  final int pendingPayoutCents;

  const AdminSellerFinanceSummary({
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    required this.totalOrders,
    required this.totalOrderLines,
    required this.totalUnitsSold,
    required this.grossSalesCents,
    required this.sellerPayableCents,
    required this.platformMarginCents,
    required this.paidCents,
    required this.pendingPayoutCents,
  });

  factory AdminSellerFinanceSummary.fromMap(Map<String, dynamic> map) {
    return AdminSellerFinanceSummary(
      sellerId: (map['seller_id'] ?? '').toString(),
      sellerName: map['seller_name']?.toString(),
      sellerEmail: map['seller_email']?.toString(),
      totalOrders: (map['total_orders'] as num?)?.toInt() ?? 0,
      totalOrderLines: (map['total_order_lines'] as num?)?.toInt() ?? 0,
      totalUnitsSold: (map['total_units_sold'] as num?)?.toInt() ?? 0,
      grossSalesCents: (map['gross_sales_cents'] as num?)?.toInt() ?? 0,
      sellerPayableCents: (map['seller_payable_cents'] as num?)?.toInt() ?? 0,
      platformMarginCents: (map['platform_margin_cents'] as num?)?.toInt() ?? 0,
      paidCents: (map['paid_cents'] as num?)?.toInt() ?? 0,
      pendingPayoutCents: (map['pending_payout_cents'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminOrderItemFinanceRow {
  final String orderItemId;
  final String orderId;
  final String? orderNumber;
  final DateTime? orderCreatedAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? orderStatus;
  final String productId;
  final String? productName;
  final int qty;
  final String? sellerId;
  final String? sellerName;
  final String? sellerEmail;
  final int? customerUnitPriceCents;
  final int? sellerBasePriceCents;
  final int? platformMarginUnitCents;
  final int? customerLineTotalCents;
  final int? sellerLineTotalCents;
  final int? platformMarginLineCents;
  final bool isFrozen;
  final String? barcode;

  const AdminOrderItemFinanceRow({
    required this.orderItemId,
    required this.orderId,
    required this.orderNumber,
    required this.orderCreatedAt,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    required this.customerUnitPriceCents,
    required this.sellerBasePriceCents,
    required this.platformMarginUnitCents,
    required this.customerLineTotalCents,
    required this.sellerLineTotalCents,
    required this.platformMarginLineCents,
    required this.isFrozen,
    required this.barcode,
  });

  factory AdminOrderItemFinanceRow.fromMap(Map<String, dynamic> map) {
    return AdminOrderItemFinanceRow(
      orderItemId: (map['order_item_id'] ?? '').toString(),
      orderId: (map['order_id'] ?? '').toString(),
      orderNumber: map['order_number']?.toString(),
      orderCreatedAt: map['order_created_at'] == null
          ? null
          : DateTime.tryParse(map['order_created_at'].toString()),
      paymentMethod: map['payment_method']?.toString(),
      paymentStatus: map['payment_status']?.toString(),
      orderStatus: map['order_status']?.toString(),
      productId: (map['product_id'] ?? '').toString(),
      productName: map['product_name']?.toString(),
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      sellerId: map['seller_id']?.toString(),
      sellerName: map['seller_name']?.toString(),
      sellerEmail: map['seller_email']?.toString(),
      customerUnitPriceCents:
          (map['customer_unit_price_cents'] as num?)?.toInt(),
      sellerBasePriceCents: (map['seller_base_price_cents'] as num?)?.toInt(),
      platformMarginUnitCents:
          (map['platform_margin_unit_cents'] as num?)?.toInt(),
      customerLineTotalCents:
          (map['customer_line_total_cents'] as num?)?.toInt(),
      sellerLineTotalCents: (map['seller_line_total_cents'] as num?)?.toInt(),
      platformMarginLineCents:
          (map['platform_margin_line_cents'] as num?)?.toInt(),
      isFrozen: (map['is_frozen'] as bool?) ?? false,
      barcode: map['barcode']?.toString(),
    );
  }
}

class AdminFinanceDashboardData {
  final AdminPlatformFinanceSummary platformSummary;
  final List<AdminSellerFinanceSummary> sellerSummaries;
  final List<AdminOrderItemFinanceRow> recentRows;

  const AdminFinanceDashboardData({
    required this.platformSummary,
    required this.sellerSummaries,
    required this.recentRows,
  });
}
