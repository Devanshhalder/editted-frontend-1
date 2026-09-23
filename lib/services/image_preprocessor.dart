import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

enum ImagePreparationCode {
  fileMissing,
  unsupportedImage,
  imageTooLarge,
  imageTooSmall,
  imageTooDark,
  imageTooBright,
  imageBlurry,
  preparationFailed,
}

class ImagePreparationException implements Exception {
  const ImagePreparationException(this.code, this.details);
  final ImagePreparationCode code;
  final String details;
  @override
  String toString() => 'ImagePreparationException($code): $details';
}

class PreparedImage {
  const PreparedImage({required this.path, required this.width, required this.height, required this.bytes});
  final String path;
  final int width;
  final int height;
  final int bytes;
}

/// Converts a camera capture into a small disk-backed WebP before AI upload.
/// The UI/AppState only needs the returned path; the original camera file is
/// deleted after the prepared file has been written successfully.
class ImagePreprocessor {
  ImagePreprocessor._();

  static const int _targetDimension = 1080;
  static const int _minDimension = 320;
  static const int _maxUploadBytes = 500 * 1024;
  static const int _absoluteInputLimit = 100 * 1024 * 1024;

  static Future<PreparedImage> prepare(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const ImagePreparationException(ImagePreparationCode.fileMissing, 'The selected image file does not exist.');
    }
    final sourceLength = await source.length();
    if (sourceLength <= 0) {
      throw const ImagePreparationException(ImagePreparationCode.fileMissing, 'The selected image file is empty.');
    }
    if (sourceLength > _absoluteInputLimit) {
      throw const ImagePreparationException(ImagePreparationCode.imageTooLarge, 'The source image is too large to safely process on this device.');
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/karigarkart_ai');
    await directory.create(recursive: true);
    final id = DateTime.now().microsecondsSinceEpoch;
    final tempJpeg = File('${directory.path}/camera_$id.jpg');
    final output = File('${directory.path}/input_$id.webp');

    try {
      final decoded = await img.decodeImageFile(source.path);
      if (decoded == null) {
        throw const ImagePreparationException(ImagePreparationCode.unsupportedImage, 'The image could not be decoded.');
      }
      final studio = _resizeAndCrop(decoded, _targetDimension);
      await tempJpeg.writeAsBytes(img.encodeJpg(studio, quality: 82), flush: true);

      const attempts = <({int dimension, int quality})>[
        (dimension: 1080, quality: 82),
        (dimension: 1080, quality: 70),
        (dimension: 960, quality: 64),
        (dimension: 840, quality: 58),
        (dimension: 720, quality: 52),
      ];

      XFile? compressed;
      for (final attempt in attempts) {
        await _deleteIfExists(output);
        compressed = await FlutterImageCompress.compressAndGetFile(
          tempJpeg.path,
          output.path,
          minWidth: attempt.dimension,
          minHeight: attempt.dimension,
          quality: attempt.quality,
          format: CompressFormat.webp,
          autoCorrectionAngle: true,
          keepExif: false,
        );
        if (compressed == null || !await output.exists()) continue;
        if (await output.length() <= _maxUploadBytes) {
          await _validatePreparedFile(output);
          final prepared = await _readPrepared(output);
          // The camera's original full-resolution capture is no longer needed.
          await _deleteIfExists(source);
          return prepared;
        }
      }

      throw const ImagePreparationException(
        ImagePreparationCode.imageTooLarge,
        'The image could not be compressed below 500 KB on this device.',
      );
    } on ImagePreparationException {
      rethrow;
    } catch (e) {
      throw ImagePreparationException(ImagePreparationCode.preparationFailed, e.toString());
    } finally {
      await _deleteIfExists(tempJpeg);
      // Never leave a partially-written oversized output behind.
      if (await output.exists() && await output.length() > _maxUploadBytes) {
        await _deleteIfExists(output);
      }
    }
  }

  static img.Image _resizeAndCrop(img.Image image, int dimension) {
    final scale = dimension / math.max(image.width, image.height);
    final resized = scale < 1
        ? img.copyResize(
            image,
            width: (image.width * scale).round(),
            height: (image.height * scale).round(),
            interpolation: img.Interpolation.average,
          )
        : image;

    final side = math.min(resized.width, resized.height);
    final x = (resized.width - side) ~/ 2;
    final y = (resized.height - side) ~/ 2;
    return img.copyCrop(resized, x: x, y: y, width: side, height: side);
  }

  static Future<void> _validatePreparedFile(File file) async {
    if (!await file.exists() || await file.length() == 0) {
      throw const ImagePreparationException(ImagePreparationCode.preparationFailed, 'The prepared image is empty.');
    }
    final decoded = await img.decodeImageFile(file.path);
    if (decoded == null) {
      throw const ImagePreparationException(ImagePreparationCode.unsupportedImage, 'The prepared image could not be decoded.');
    }
    if (decoded.width != decoded.height) {
      throw const ImagePreparationException(ImagePreparationCode.preparationFailed, 'The prepared product image is not square.');
    }
    if (decoded.width < _minDimension || decoded.height < _minDimension) {
      throw const ImagePreparationException(ImagePreparationCode.imageTooSmall, 'The image resolution is too low for reliable product enhancement.');
    }

    final metrics = _qualityMetrics(decoded);
    if (metrics.meanLuminance < 0.055) {
      throw const ImagePreparationException(ImagePreparationCode.imageTooDark, 'The image is too dark for reliable subject detection.');
    }
    if (metrics.meanLuminance > 0.995) {
      throw const ImagePreparationException(ImagePreparationCode.imageTooBright, 'The image is overexposed.');
    }
    if (metrics.edgeEnergy < 1.25 && metrics.luminanceStdDev < 7.0) {
      throw const ImagePreparationException(ImagePreparationCode.imageBlurry, 'The image has very little usable detail.');
    }
  }

  static _QualityMetrics _qualityMetrics(img.Image image) {
    const samples = 48;
    final stepX = (image.width / samples).ceil().clamp(1, image.width).toInt();
    final stepY = (image.height / samples).ceil().clamp(1, image.height).toInt();
    double sum = 0;
    double sumSquared = 0;
    double edgeSum = 0;
    int count = 0;
    int edgeCount = 0;

    for (int y = 0; y < image.height; y += stepY) {
      for (int x = 0; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        final luminance = pixel.luminance.toDouble();
        sum += luminance;
        sumSquared += luminance * luminance;
        count++;
        if (x + stepX < image.width) {
          edgeSum += (luminance - image.getPixel(x + stepX, y).luminance).abs();
          edgeCount++;
        }
        if (y + stepY < image.height) {
          edgeSum += (luminance - image.getPixel(x, y + stepY).luminance).abs();
          edgeCount++;
        }
      }
    }

    if (count == 0) return const _QualityMetrics(meanLuminance: 0, luminanceStdDev: 0, edgeEnergy: 0);
    final mean = sum / count;
    final variance = (sumSquared / count) - (mean * mean);
    return _QualityMetrics(
      meanLuminance: (mean / 255).clamp(0.0, 1.0),
      luminanceStdDev: variance <= 0 ? 0 : math.sqrt(variance),
      edgeEnergy: edgeCount == 0 ? 0 : edgeSum / edgeCount,
    );
  }

  static Future<PreparedImage> _readPrepared(File file) async {
    final decoded = await img.decodeImageFile(file.path);
    if (decoded == null) {
      throw const ImagePreparationException(ImagePreparationCode.preparationFailed, 'The prepared image could not be read back.');
    }
    return PreparedImage(path: file.path, width: decoded.width, height: decoded.height, bytes: await file.length());
  }

  static Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

class _QualityMetrics {
  const _QualityMetrics({required this.meanLuminance, required this.luminanceStdDev, required this.edgeEnergy});
  final double meanLuminance;
  final double luminanceStdDev;
  final double edgeEnergy;
}
