import 'package:flutter/material.dart';

import '../services/app_localization.dart';
import '../services/app_state.dart';
import '../theme.dart';

class AiErrorDialog {
  AiErrorDialog._();

  static Future<void> show(
      BuildContext context, {
        required String code,
        VoidCallback? onRetry,
      }) {
    final language = AppScope.of(context).language;

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AI error',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _AiErrorCard(
          code: code,
          language: language,
          onRetry: onRetry,
        );
      },
      transitionBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          child,
          ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: .88,
              end: 1,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _AiErrorCard extends StatelessWidget {
  const _AiErrorCard({
    required this.code,
    required this.language,
    this.onRetry,
  });

  final String code;
  final String language;
  final VoidCallback? onRetry;

  String _tr(String key) => AppLocalization.text(language, key);

  String get _title {
    switch (code) {
      case 'imageTooDark':
        return _tr('imageTooDark');
      case 'imageTooBright':
        return _tr('imageTooBright');
      case 'imageBlurry':
        return _tr('imageBlurry');
      case 'unsupportedImage':
        return _tr('unsupportedImage');
      case 'imageTooLarge':
        return _tr('imageTooLarge');
      case 'imageTooSmall':
        return _tr('imageTooSmall');
      case 'subjectNotFound':
        return _tr('subjectNotFound');
      case 'imageMissing':
        return _tr('noPhotoFound');
      case 'aiTimeout':
        return _tr('aiTimeout');
      case 'aiNetworkError':
        return _tr('aiNetworkError');
      case 'aiServerError':
        return _tr('aiServerError');
      default:
        return _tr('aiUnknown');
    }
  }

  IconData get _icon {
    switch (code) {
      case 'imageTooDark':
        return Icons.brightness_4_rounded;
      case 'imageTooBright':
        return Icons.wb_sunny_outlined;
      case 'imageBlurry':
        return Icons.blur_on_rounded;
      case 'unsupportedImage':
        return Icons.broken_image_outlined;
      case 'imageTooLarge':
        return Icons.photo_size_select_large_outlined;
      case 'imageTooSmall':
        return Icons.photo_size_select_small_outlined;
      case 'subjectNotFound':
        return Icons.center_focus_strong_rounded;
      case 'imageMissing':
        return Icons.photo_library_outlined;
      case 'aiTimeout':
        return Icons.timer_off_outlined;
      case 'aiNetworkError':
        return Icons.wifi_off_rounded;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 390),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .75, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.clay.withOpacity(.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icon,
                        color: AppColors.clay,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _tr('photoEnhancementFailed'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(_tr('cancel')),
                        ),
                      ),
                      if (onRetry != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onRetry!.call();
                            },
                            child: Text(_tr('checkAgain')),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
