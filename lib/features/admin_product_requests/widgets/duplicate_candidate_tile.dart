import 'package:flutter/material.dart';
import '../../seller_requests/models/duplicate_candidate_model.dart';

class DuplicateCandidateTile extends StatelessWidget {
  const DuplicateCandidateTile({
    super.key,
    required this.candidate,
    this.onTap,
  });

  final DuplicateCandidateModel candidate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(candidate.productName),
      subtitle: Text(
        '${candidate.reason} • ${candidate.similarityScore.toStringAsFixed(0)}%',
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
