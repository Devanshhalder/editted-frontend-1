import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_state.dart';
import '../theme.dart';

class WhatsAppShowcaseCard extends StatefulWidget {
  const WhatsAppShowcaseCard({
    super.key,
    required this.productId,
    required this.productNameEnglish,
    required this.productNameHindi,
    required this.price,
    required this.fairWage,
    required this.imagePath,
    this.catalogUrl,
  });

  final String productId;
  final String productNameEnglish;
  final String productNameHindi;
  final int price;
  final int fairWage;
  final String imagePath;
  final String? catalogUrl;

  @override
  State<WhatsAppShowcaseCard> createState() => _WhatsAppShowcaseCardState();
}

class _WhatsAppShowcaseCardState extends State<WhatsAppShowcaseCard> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _sharing = false;

  String get _qrPayload =>
      widget.catalogUrl?.trim().isNotEmpty == true
          ? widget.catalogUrl!.trim()
          : 'karigarkart://catalog/${Uri.encodeComponent(widget.productId)}';

  Future<Uint8List> _render() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Showcase card is not ready');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (bytes == null) {
      throw StateError('Could not render showcase card');
    }

    return bytes.buffer.asUint8List();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      final bytes = await _render();
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/karigarkart_story_${widget.productId}.png',
      );
      await file.writeAsBytes(bytes, flush: true);

      final artisan = AppScope.of(context).profileName;
      final verified = AppScope.of(context).isIdentityVerified
          ? '\nHandmade / Authentic Craftsperson ✓'
          : '';
      final text =
          'Namaste! / नमस्ते!\n$artisan presents ${widget.productNameEnglish} / ${widget.productNameHindi}.\nPrice: ₹${widget.price}\nFair wage estimate: ₹${widget.fairWage}$verified\nEnquire on KarigarKart.';

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: '${widget.productNameEnglish} — KarigarKart',
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create the share card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final verified = AppScope.of(context).isIdentityVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.outline.withOpacity(.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.25,
                    child: File(widget.imagePath).existsSync()
                        ? Image.file(File(widget.imagePath), fit: BoxFit.cover)
                        : Container(
                            color: AppColors.cream,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_outlined, size: 50),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.productNameEnglish,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.productNameHindi,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withOpacity(.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: AppColors.forest,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Handmade / Authentic Craftsperson',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '₹${widget.price}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forest.withOpacity(.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Fair wage ₹${widget.fairWage}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    QrImageView(data: _qrPayload, size: 58),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Scan to open the digital catalog\n$_qrPayload',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.chat_rounded),
            label: Text(
              _sharing ? 'Preparing…' : 'Share to WhatsApp / Chats',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
