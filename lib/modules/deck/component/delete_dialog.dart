import 'package:flutter/material.dart';

import '../../../i18n/i18n.dart';
import '../../../utils/custom_navigator.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog({required this.title, required this.content, Key? key})
      : super(key: key);

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            primary: Theme.of(context).textTheme.bodyText2!.color,
          ),
          onPressed: () => CustomNavigator.getInstance().pop(false),
          child: Text(S.of(context).cancel.toUpperCase()),
        ),
        TextButton(
          style: TextButton.styleFrom(
            primary: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => CustomNavigator.getInstance().pop(true),
          child: Text(S.of(context).delete.toUpperCase()),
        ),
      ],
    );
  }
}
