# model_viewer_plus 1.10.0

Source: https://pub.dev/packages/model_viewer_plus/versions/1.10.0
Repository: https://github.com/omchiii/model_viewer_plus.dart

Vendored under its preserved Apache-2.0 LICENSE. Original library and renderer assets are retained; development examples are omitted.

Nurturio patch: asynchronous model-view initialization checks `mounted` before registering views or updating state. If the native loopback server finishes binding after disposal, it is closed immediately. CI exposed a real `setState() called after dispose()` crash during rapid lesson navigation. These guards address the race without bypassing the native renderer in gameplay tests.

Native interactive scenes claim horizontal drags instead of eagerly capturing every gesture, letting the containing page scroll vertically. Noninteractive previews let their enclosing card receive taps. Physical pinch/gesture acceptance remains separate. HTML attributes for shadow intensity/softness no longer contain an extra brace; CSS rgba alpha uses its valid 0–1 range.
