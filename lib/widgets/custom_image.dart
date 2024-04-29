import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:kurakaani/widgets/progress.dart';

Widget cachedNetworkImage(String mediaUrl) {
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => circularProgress(),
    errorWidget: (context, url, error) => const Icon(Icons.error),
  );
}
