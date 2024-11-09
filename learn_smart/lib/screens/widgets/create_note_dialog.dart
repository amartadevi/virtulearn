import 'package:flutter/material.dart';
import 'custom_form_field.dart';
import 'custom_button.dart';

class CreateNoteDialog extends StatelessWidget {
  final Function(String title, String content) onSubmit;

  const CreateNoteDialog({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? _title;
    String? _content;

    return AlertDialog(
      title: Text('Create Note'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomFormField(
              label: 'Title',
              onSaved: (value) => _title = value,
            ),
            SizedBox(height: 16),
            CustomFormField(
              label: 'Content',
              onSaved: (value) => _content = value,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        CustomButton(
          text: 'Cancel',
          backgroundColor: Colors.grey,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CustomButton(
          text: 'Create',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              onSubmit(_title ?? 'Untitled', _content ?? 'No content');
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
