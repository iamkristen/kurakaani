import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:kurakaani/constants/color_constants.dart';

Container circularProgress() {
  return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 10.0),
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(ColorConstants.primaryColor),
      ));
}

linearProgress() {
  return const LinearProgressIndicator(
    backgroundColor: ColorConstants.primaryText,
    valueColor: AlwaysStoppedAnimation(ColorConstants.primaryColor),
  );
}
