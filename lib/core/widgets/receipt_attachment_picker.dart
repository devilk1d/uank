import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../utils/receipt_ocr_parser.dart';
import 'receipt_image_viewer.dart';

class ReceiptAttachmentPicker extends StatefulWidget {
  const ReceiptAttachmentPicker({
    super.key,
    this.stagedBytes,
    this.stagedExtension,
    this.existingUrl,
    this.isExistingRemoved = false,
    this.isScanningOcr = false,
    this.isOcrEnabled = true,
    required this.onImageSelected,
    required this.onImageRemoved,
    this.onOcrParsed,
  });

  final Uint8List? stagedBytes;
  final String? stagedExtension;
  final String? existingUrl;
  final bool isExistingRemoved;
  final bool isScanningOcr;
  final bool isOcrEnabled;
  final void Function(Uint8List bytes, String extension, String? filePath) onImageSelected;
  final VoidCallback onImageRemoved;
  final void Function(OcrResult ocrResult)? onOcrParsed;

  @override
  State<ReceiptAttachmentPicker> createState() => _ReceiptAttachmentPickerState();
}

class _ReceiptAttachmentPickerState extends State<ReceiptAttachmentPicker> {
  final ImagePicker _picker = ImagePicker();

  bool get _hasImage {
    if (widget.stagedBytes != null) return true;
    if (widget.existingUrl != null && !widget.isExistingRemoved) return true;
    return false;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final ext = pickedFile.name.split('.').last.toLowerCase();

      widget.onImageSelected(bytes, ext, pickedFile.path);

      // Perform OCR only if feature is enabled & callback provided
      if (widget.isOcrEnabled && widget.onOcrParsed != null) {
        final ocr = await ReceiptOcrParser.parseReceiptFromFile(pickedFile.path);
        widget.onOcrParsed!(ocr);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: ctx.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: ctx.cardBorder, width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attach Receipt / Proof',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take a photo or choose an existing screenshot. Details will be auto-scanned.',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: context.accentLinkColor, size: 22),
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
                subtitle: Text(
                  'Snap a physical receipt or transfer slip',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.teal, size: 22),
                ),
                title: Text(
                  'Gallery / Screenshots',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
                subtitle: Text(
                  'Upload bank transfer proof or e-receipt screenshot',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Receipt / Proof (Optional)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
            ),
            if (widget.isScanningOcr && widget.isOcrEnabled)
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.accentLinkColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Scanning...',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.accentLinkColor),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),

        if (!_hasImage)
          // Empty state: Upload button
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showImageSourceSheet,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.cardBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: context.accentLinkColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Receipt / Transfer Proof',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          widget.isOcrEnabled
                              ? 'Auto-scan nominal & date from photos'
                              : 'Attach receipt photo or screenshot',
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.add_photo_alternate_outlined, size: 20, color: context.accentLinkColor),
                ],
              ),
            ),
          )
        else
          // Staged or existing image preview card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.inputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (context.isDark ? AppColors.primary : const Color(0xFF15803D)).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Clickable Thumbnail with Zoom Viewer
                GestureDetector(
                  onTap: () {
                    ReceiptImageViewer.show(
                      context,
                      imageUrl: widget.stagedBytes == null ? widget.existingUrl : null,
                      imageBytes: widget.stagedBytes,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: widget.stagedBytes != null
                              ? Image.memory(widget.stagedBytes!, fit: BoxFit.cover)
                              : Image.network(
                                  widget.existingUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.black26,
                                    child: const Icon(Icons.broken_image_rounded, size: 20),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_in_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: context.accentLinkColor),
                          const SizedBox(width: 4),
                          Text(
                            widget.stagedBytes != null ? 'Receipt Ready to Upload' : 'Receipt Attached',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap image to enlarge',
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Action Buttons (Change & Delete)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Change Image',
                      color: context.accentLinkColor,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: _showImageSourceSheet,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      tooltip: 'Remove Image',
                      color: AppColors.red,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: widget.onImageRemoved,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
