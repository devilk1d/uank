import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ReceiptImageViewer extends StatelessWidget {
  const ReceiptImageViewer({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.title = 'Receipt / Proof',
  }) : assert(imageUrl != null || imageBytes != null, 'Either imageUrl or imageBytes must be provided');

  final String? imageUrl;
  final Uint8List? imageBytes;
  final String title;

  static void show(
    BuildContext context, {
    String? imageUrl,
    Uint8List? imageBytes,
    String title = 'Receipt / Proof',
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => ReceiptImageViewer(
        imageUrl: imageUrl,
        imageBytes: imageBytes,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Interactive Zoomable Image
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Hero(
                  tag: imageUrl ?? 'receipt_${imageBytes.hashCode}',
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
                        )
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
                        ),
                ),
              ),
            ),

            // Top Bar with Title & Close Button
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Hint
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Pinch to zoom / Drag to pan',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
          SizedBox(height: 10),
          Text(
            'Failed to load image',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
