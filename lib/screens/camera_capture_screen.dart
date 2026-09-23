import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/app_state.dart';
import '../services/haptic_feedback_service.dart';
import '../services/image_preprocessor.dart';
import '../theme.dart';
import '../widgets/state_animation.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    super.key,
    required this.guideText,
    this.title = 'Camera',
  });

  final String guideText;
  final String title;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  XFile? _capturedImage;
  bool _capturing = false;
  bool _shutterFlash = false;
  FlashMode _flashMode = FlashMode.off;
  double _tiltDegrees = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  late final AnimationController _previewAnimationController =
  AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startLevelSensor();
  }

  void _startLevelSensor() {
    _accelerometerSubscription = accelerometerEvents.listen(
          (event) {
        final gravity = math.sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        if (gravity <= 0.1 || !mounted) return;
        final tilt = math.atan2(
          math.sqrt(event.x * event.x + event.y * event.y),
          event.z.abs(),
        ) *
            180 /
            math.pi;
        setState(() => _tiltDegrees = tilt.clamp(0, 45));
      },
      onError: (_) {},
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }
      final backCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      _initializeFuture = controller.initialize();
      await _initializeFuture;
      if (!mounted) return;
      await controller.setFlashMode(_flashMode);
      setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.off,
    };
    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {}
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing ||
        _capturedImage != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _capturing = true;
      _shutterFlash = true;
    });
    KarigarKartHaptics.selection();
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _shutterFlash = false);
    });

    try {
      final raw = await controller.takePicture();
      final prepared = await ImagePreprocessor.prepare(raw.path);
      if (!mounted) {
        try {
          await File(prepared.path).delete();
        } catch (_) {}
        return;
      }
      setState(() {
        _capturedImage = XFile(prepared.path, mimeType: 'image/webp');
        _capturing = false;
      });
      _previewAnimationController.forward(from: 0);
      KarigarKartHaptics.aiSuccess();
    } on ImagePreparationException catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _shutterFlash = false;
      });
      KarigarKartHaptics.aiFailure();
    } on CameraException catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _shutterFlash = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _shutterFlash = false;
      });
      KarigarKartHaptics.aiFailure();
    }
  }

  Future<void> _deleteCapturedFile() async {
    final image = _capturedImage;
    if (image == null) return;
    try {
      final file = File(image.path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _retake() async {
    if (_capturing) return;
    await _deleteCapturedFile();
    if (!mounted) return;
    setState(() => _capturedImage = null);
    _previewAnimationController.reverse();
  }

  void _usePhoto() {
    final image = _capturedImage;
    if (image == null || _capturing) return;
    Navigator.of(context).pop(image);
  }

  Future<void> _showStudioSettings(BuildContext context) async {
    final state = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        const presets = <String>[
          'Pure White',
          'Warm Wood',
          'Neutral Studio',
          'Transparent PNG',
        ];
        const ratios = <String>['1:1', '4:5'];
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final currentPreset = state.studioPreset;
              final currentRatio = state.studioAspectRatio;
              void setPreset(String value) {
                state.setStudioSettings(preset: value);
                setSheetState(() {});
              }

              void setRatio(String value) {
                state.setStudioSettings(aspectRatio: value);
                setSheetState(() {});
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image Studio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose the look and marketplace format before you capture the product.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets
                          .map(
                            (item) => Semantics(
                          label: 'Image Studio preset $item',
                          hint: 'Select this product background style',
                          button: true,
                          child: ChoiceChip(
                            label: Text(item),
                            selected: currentPreset == item,
                            onSelected: (_) => setPreset(item),
                            selectedColor:
                            AppColors.forest.withOpacity(.14),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: currentPreset == item
                                  ? AppColors.forest
                                  : Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aspect ratio',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final item in ratios)
                          Semantics(
                            label: 'Aspect ratio $item',
                            hint: 'Select marketplace image ratio',
                            button: true,
                            child: ChoiceChip(
                              label: Text(item),
                              selected: currentRatio == item,
                              onSelected: (_) => setRatio(item),
                              selectedColor: AppColors.clay.withOpacity(.14),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: currentRatio == item
                                    ? AppColors.clay
                                    : Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _previewAnimationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller != null && controller.value.isInitialized;
    final showingPreview = _capturedImage != null;
    final level = _tiltDegrees <= 6;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: showingPreview
                    ? _CapturePreview(
                  key: const ValueKey('capture-preview'),
                  image: _capturedImage!,
                  animation: _previewAnimationController,
                )
                    : initialized
                    ? _LiveCamera(
                  key: const ValueKey('live-camera'),
                  controller: controller,
                )
                    : const Center(
                  key: ValueKey('camera-loading'),
                  child: KarigarKartStateAnimation(
                    state: KarigarKartAnimationState.analyzing,
                    size: 84,
                  ),
                ),
              ),
            ),
            if (!showingPreview)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CameraGuidePainter(level: level),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  if (!showingPreview)
                    Row(
                      children: [
                        _CircleButton(
                          icon: Icons.tune_rounded,
                          onTap: () => _showStudioSettings(context),
                        ),
                        const SizedBox(width: 8),
                        _CircleButton(
                          icon: _flashIcon,
                          onTap: _toggleFlash,
                        ),
                      ],
                    )
                  else
                    const SizedBox(width: 100, height: 46),
                ],
              ),
            ),
            if (!showingPreview)
              Positioned(
                top: 66,
                left: 24,
                right: 24,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: level
                          ? AppColors.forest.withOpacity(.86)
                          : AppColors.clay.withOpacity(.90),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          level
                              ? Icons.check_rounded
                              : Icons.screen_lock_rotation_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          level
                              ? 'Phone is level'
                              : 'Tilt ${_tiltDegrees.round()}° · hold level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!showingPreview)
              Positioned(
                left: 28,
                right: 28,
                bottom: 30,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.48),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.guideText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      button: true,
                      label: 'Take product photo',
                      hint: level
                          ? 'Take photo'
                          : 'Hold phone level before taking photo',
                      child: GestureDetector(
                        onTap: _capture,
                        child: AnimatedScale(
                          scale: _capturing ? .90 : 1,
                          duration: const Duration(milliseconds: 110),
                          child: Container(
                            width: 78,
                            height: 78,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(.95),
                              border: Border.all(
                                color: AppColors.saffron,
                                width: 3,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _capturing
                                    ? AppColors.clay
                                    : AppColors.forest,
                              ),
                              child: _capturing
                                  ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 27,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Positioned(
                left: 22,
                right: 22,
                bottom: 24,
                child: Row(
                  children: [
                    Expanded(
                      child: _PreviewButton(
                        label: 'Retake',
                        icon: Icons.refresh_rounded,
                        onTap: _retake,
                        filled: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PreviewButton(
                        label: 'Use Photo',
                        icon: Icons.check_rounded,
                        onTap: _usePhoto,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _shutterFlash ? 1 : 0,
                  duration: const Duration(milliseconds: 70),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.off:
      default:
        return Icons.flash_off_rounded;
    }
  }
}

class _LiveCamera extends StatelessWidget {
  const _LiveCamera({super.key, required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final sensorAspectRatio = controller.value.aspectRatio;
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width / sensorAspectRatio;
              return FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: CameraPreview(controller),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CapturePreview extends StatelessWidget {
  const _CapturePreview({
    super.key,
    required this.image,
    required this.animation,
  });

  final XFile image;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = .94 + animation.value * .06;
        return Center(
          child: Opacity(
            opacity: animation.value,
            child: Transform.scale(
              scale: scale,
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRect(
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CameraGuidePainter extends CustomPainter {
  const _CameraGuidePainter({required this.level});

  final bool level;

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width * .84;
    final rect = Rect.fromLTWH(
      (size.width - squareSize) / 2,
      (size.height - squareSize) / 2,
      squareSize,
      squareSize,
    );
    final dimPaint = Paint()..color = Colors.black.withOpacity(.28);
    final path = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, path, hole),
      dimPaint,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final thirdX1 = rect.left + rect.width / 3;
    final thirdX2 = rect.left + rect.width * 2 / 3;
    final thirdY1 = rect.top + rect.height / 3;
    final thirdY2 = rect.top + rect.height * 2 / 3;
    canvas.drawLine(
      Offset(thirdX1, rect.top),
      Offset(thirdX1, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(thirdX2, rect.top),
      Offset(thirdX2, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, thirdY1),
      Offset(rect.right, thirdY1),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, thirdY2),
      Offset(rect.right, thirdY2),
      gridPaint,
    );

    final guidePaint = Paint()
      ..color = (level ? Colors.white : AppColors.saffron).withOpacity(.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      guidePaint,
    );

    final silhouettePaint = Paint()
      ..color = Colors.white.withOpacity(.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: rect.width * .56,
          height: rect.height * .46,
        ),
        const Radius.circular(28),
      ),
      silhouettePaint,
    );

    const cornerLength = 24.0;
    final cornerPaint = Paint()
      ..color = AppColors.saffron
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final x = rect.left;
    final y = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    canvas.drawLine(Offset(x, y + cornerLength), Offset(x, y), cornerPaint);
    canvas.drawLine(Offset(x, y), Offset(x + cornerLength, y), cornerPaint);
    canvas.drawLine(
      Offset(r - cornerLength, y),
      Offset(r, y),
      cornerPaint,
    );
    canvas.drawLine(Offset(r, y), Offset(r, y + cornerLength), cornerPaint);
    canvas.drawLine(
      Offset(x, b - cornerLength),
      Offset(x, b),
      cornerPaint,
    );
    canvas.drawLine(Offset(x, b), Offset(x + cornerLength, b), cornerPaint);
    canvas.drawLine(
      Offset(r - cornerLength, b),
      Offset(r, b),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r, b - cornerLength),
      Offset(r, b),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CameraGuidePainter oldDelegate) =>
      oldDelegate.level != level;
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Material(
        color: filled ? AppColors.forest : Colors.black.withOpacity(.48),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: filled
                    ? Colors.transparent
                    : Colors.white.withOpacity(.38),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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