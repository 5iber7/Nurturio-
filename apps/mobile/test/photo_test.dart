import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:nurturio/features/discover/discover_screen.dart';

void main() {
  test('photo preparation emits bounded JPEG with stripped metadata', () {
    final image = img.Image(width: 2000, height: 1000);
    image.exif.imageIfd.gpsLatitude = 25.0;
    final jpeg = Uint8List.fromList(img.encodeJpg(image));
    final result = img.decodeJpg(preparePhoto(jpeg))!;
    expect(result.width, 1536);
    expect(result.height, 768);
    expect(result.exif.isEmpty, true);
  });
  test('invalid image fails rather than producing a misleading result', () {
    expect(() => preparePhoto(Uint8List.fromList([1, 2, 3])), throwsStateError);
  });
}
