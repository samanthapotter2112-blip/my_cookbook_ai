import 'dart:typed_data';

class OcrService {
  static bool get isSupported => false;

  static Future<String> recogniseText({
    required Uint8List imageBytes,
    required String imagePath,
  }) {
    throw UnsupportedError(
      'Automatic text recognition is not available on this platform.',
    );
  }
}
