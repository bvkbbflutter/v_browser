import 'package:flutter/material.dart';
import '../../../core/models/dashboard_shortcut_model.dart';

class ShortcutDialog extends StatefulWidget {
  final DashboardShortcutModel? shortcut;
  final Function(String title, String url) onSave;
  final VoidCallback? onDelete;

  const ShortcutDialog({
    super.key,
    this.shortcut,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<ShortcutDialog> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.shortcut?.title ?? '');
    _urlController = TextEditingController(text: widget.shortcut?.url ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.shortcut != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Shortcut' : 'Add Shortcut'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Name (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            autofocus: !isEditing,
            decoration: const InputDecoration(
              labelText: 'URL or Domain',
              hintText: 'e.g. example.com',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        if (isEditing && widget.onDelete != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete!();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_urlController.text.trim().isNotEmpty) {
              Navigator.pop(context);
              widget.onSave(_titleController.text, _urlController.text);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
