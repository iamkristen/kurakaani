import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:photo_view/photo_view.dart';

class FullPhoto extends StatelessWidget {
  const FullPhoto({Key? key, required this.imgUrl}) : super(key: key);
  final String imgUrl;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Full Image",
          style: TextStyle(
              fontSize: 40, fontFamily: 'signatra', letterSpacing: 1.5),
        ),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imgUrl),
      ),
    );
  }
}
