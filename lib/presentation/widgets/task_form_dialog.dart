import 'package:flutter/material.dart';

class TaskFormDialog extends StatefulWidget {
  final String? initialTitle;
  final String title;
  final String confirmButtonText;

  const TaskFormDialog({
    Key? key,
    this.initialTitle,
    required this.title,
    required this.confirmButtonText,
  }) : super(key: key);

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();

  static Future<String?> show({
    required BuildContext context,
    String? initialTitle,
    required String title,
    required String confirmButtonText,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => TaskFormDialog(
        initialTitle: initialTitle,
        title: title,
        confirmButtonText: confirmButtonText,
      ),
    );
  }
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Enter task title',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.task_alt),
          ),
          autofocus: true,
          maxLength: 100,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a task title';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmButtonText),
        ),
      ],
    );
  }
}