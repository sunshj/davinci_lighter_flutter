import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

requestPermission(
  Permission permission, {
  VoidCallback? onGranted,
  VoidCallback? onDenied,
  VoidCallback? onPermanentlyDenied,
}) async {
  final status = await permission.status;
  if (status.isGranted) {
    onGranted?.call();
  } else {
    final result = await permission.request();
    if (result.isGranted) {
      onGranted?.call();
    } else if (result.isDenied) {
      onDenied?.call();
    } else if (result.isPermanentlyDenied) {
      onPermanentlyDenied?.call();
    }
  }
}

showMessageDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = '确定',
  String cancelText = '取消',
  bool showConfirmButton = true,
  bool showCancelButton = true,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (showConfirmButton)
            TextButton(
              onPressed: () {
                onConfirm?.call();
                Navigator.of(context).pop();
              },
              child: Text(confirmText),
            ),
          if (showCancelButton)
            TextButton(
              onPressed: () {
                onCancel?.call();
                Navigator.of(context).pop();
              },
              child: Text(cancelText),
            ),
        ],
      );
    },
  );
}

openExternalUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw 'Could not launch $url';
  }
}
