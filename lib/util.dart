import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

requestRecordPermission({
  VoidCallback? onDenied,
  VoidCallback? onPermanentlyDenied,
}) async {
  final status = await Permission.microphone.status;
  if (!status.isGranted) {
    final result = await Permission.microphone.request();
    if (result.isDenied) {
      onDenied?.call();
    } else if (result.isPermanentlyDenied) {
      onPermanentlyDenied?.call();
    }
  }

  return status.isGranted;
}

showMessageDialog(
  BuildContext context, {
  required String title,
  required String content,
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
          TextButton(
            onPressed: () {
              onConfirm?.call();
              Navigator.of(context).pop();
            },
            child: Text('确定'),
          ),
          TextButton(
            onPressed: () {
              onCancel?.call();
              Navigator.of(context).pop();
            },
            child: Text('取消'),
          ),
        ],
      );
    },
  );
}
