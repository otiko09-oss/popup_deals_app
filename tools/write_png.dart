import 'dart:io';

import 'package:image/image.dart' as img;

Future<void> main() async {
  final file = File('assets/icons/app_icon.png');
  await file.parent.create(recursive: true);

  final image = img.Image(width: 1024, height: 1024);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixel(x, y, img.ColorRgba8(255, 139, 61, 255));
    }
  }

  final rounded = img.copyResize(image, width: 800, height: 800);
  final encoded = img.encodePng(rounded);
  await file.writeAsBytes(encoded, flush: true);
  print('wrote ${file.path} (${file.statSync().size} bytes)');
}
