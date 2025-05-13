import 'package:flutter/material.dart';

class UnsavedChangesDialogWidget extends StatelessWidget {
  const UnsavedChangesDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unsaved Changes'),
      content: const Text('You have unsaved changes. Do you want to exit?'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Exit'),
        ),
      ],
    );
  }
}
