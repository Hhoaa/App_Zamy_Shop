import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeTabs {
  static final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);
  static int? _pendingIndex;

  static void setIndex(int index) {
    if (index < 0) return;
    debugPrint('[HomeTabs] setIndex -> $index (current: ${selectedIndex.value})');
    if (selectedIndex.value == index) {
      debugPrint('[HomeTabs] setIndex ignored (same value)');
      return;
    }
    selectedIndex.value = index;
    debugPrint('[HomeTabs] setIndex applied -> ${selectedIndex.value}');
  }

  static void forceSetIndex(int index) {
    if (index < 0) return;
    debugPrint('[HomeTabs] forceSetIndex -> $index (current: ${selectedIndex.value})');
    // Toggle value to force notification even if same index
    if (selectedIndex.value == index) {
      debugPrint('[HomeTabs] forceSetIndex toggling to ensure notifyListeners');
      // Briefly set to a different temp value then set back
      final temp = index == 0 ? 1 : 0;
      selectedIndex.value = temp;
    }
    selectedIndex.value = index;
    debugPrint('[HomeTabs] forceSetIndex applied -> ${selectedIndex.value}');
  }

  static void setPendingIndex(int index) {
    if (index < 0) return;
    _pendingIndex = index;
    debugPrint('[HomeTabs] setPendingIndex -> $_pendingIndex');
  }

  static int? consumePendingIndex() {
    final idx = _pendingIndex;
    _pendingIndex = null;
    if (idx != null) {
      debugPrint('[HomeTabs] consumePendingIndex -> $idx');
    } else {
      debugPrint('[HomeTabs] consumePendingIndex -> null');
    }
    return idx;
  }
}


