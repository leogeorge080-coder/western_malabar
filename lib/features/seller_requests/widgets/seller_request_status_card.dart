import 'package:flutter/material.dart';
import '../models/seller_product_request_model.dart';

class SellerRequestStatusCard extends StatelessWidget {
  const SellerRequestStatusCard({
    super.key,
    required this.request,
  });

  final SellerProductRequestModel request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.productName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(request.status)),
                Chip(label: Text(request.duplicateStatus)),
                Chip(
                    label: Text(
                        '${request.duplicateConfidence.toStringAsFixed(0)}%')),
              ],
            ),
            if (request.issueFlags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: request.issueFlags
                    .map((e) => Chip(label: Text(e)))
                    .toList(),
              ),
            ],
            if ((request.reviewSummary ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(request.reviewSummary!),
            ],
            if ((request.adminNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Admin note: ${request.adminNote!}'),
            ],
          ],
        ),
      ),
    );
  }
}
