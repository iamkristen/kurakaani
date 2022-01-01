import 'dart:async';

import 'package:flutter/cupertino.dart';

class Debouncer {
  Debouncer({this.millisecond});
  final millisecond;
  Timer? _timer;
  run(VoidCallback action) {
    _timer!.cancel();
    _timer = Timer(Duration(milliseconds: millisecond), action);
  }
}
