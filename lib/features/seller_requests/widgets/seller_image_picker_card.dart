import 'dart:io';

import 'package:flutter/material.dart';

class SellerImagePickerCard extends StatelessWidget {
  const SellerImagePickerCard({
    super.key,
    required this.localImageFile,
    required this.imageUrl,
    required this.uploading,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final File? localImageFile;
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final hasAnyImage = localImageFile != null || imageUrl != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Image',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (!hasAnyImage)
            InkWell(
              onTap: uploading ? null : onPickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD9CCE9),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: uploading
                      ? const CircularProgressIndicator()
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 34),
                            SizedBox(height: 10),
                            Text(
                              'Tap to add image',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Very easy for seller',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            )
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: localImageFile != null
                      ? Image.file(
                          localImageFile!,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          imageUrl!,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploading ? null : onPickImage,
                        icon: const Icon(Icons.refresh),
                        label: Text(uploading ? 'Uploading...' : 'Replace'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploading ? null : onRemoveImage,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
