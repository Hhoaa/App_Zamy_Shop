import 'package:flutter/foundation.dart';

class BubbleVisibility {
  static final ValueNotifier<bool> visible = ValueNotifier<bool>(true);

  static void show() => visible.value = true;
  static void hide() => visible.value = false;
}


