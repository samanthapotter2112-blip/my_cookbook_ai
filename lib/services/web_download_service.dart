import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class WebDownloadService {
  static void downloadFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    final JSUint8Array jsBytes =
        bytes.toJS;

    final web.Blob blob = web.Blob(
      <web.BlobPart>[
        jsBytes,
      ].toJS,
      web.BlobPropertyBag(
        type: mimeType,
      ),
    );

    final String objectUrl =
        web.URL.createObjectURL(blob);

    final web.HTMLAnchorElement anchor =
        web.HTMLAnchorElement()
          ..href = objectUrl
          ..download = fileName
          ..style.display = 'none';

    web.document.body?.append(anchor);

    anchor.click();
    anchor.remove();

    web.URL.revokeObjectURL(objectUrl);
  }
}