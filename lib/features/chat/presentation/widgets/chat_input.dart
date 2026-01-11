import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/message.dart';

/// Chat input widget with text, voice, and file support
class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String message, List<MessageAttachment>? attachments)
      onSend;
  final VoidCallback onVoiceInput;

  const ChatInput({
    required this.controller,
    required this.onSend,
    required this.onVoiceInput,
    super.key,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final List<MessageAttachment> _attachments = [];
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = widget.controller.text.trim().isNotEmpty;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _attachments.add(
          MessageAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: image.path,
            type: AttachmentType.image,
            mimeType: 'image/${image.path.split('.').last}',
          ),
        );
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _attachments.add(
          MessageAttachment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            path: file.path!,
            type: AttachmentType.file,
            mimeType: file.extension,
            sizeBytes: file.size,
          ),
        );
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    widget.onSend(
      text,
      _attachments.isNotEmpty ? List.from(_attachments) : null,
    );

    setState(() {
      _attachments.clear();
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachments preview
          if (_attachments.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final attachment = entry.value;
                  return _buildAttachmentChip(attachment, index);
                }).toList(),
              ),
            ),

          // Input row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAttachmentOptions(context),
                  tooltip: 'Add attachment',
                ),

                // Text input
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),

                // Voice or Send button
                if (_isComposing || _attachments.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _handleSend,
                    color: theme.colorScheme.primary,
                    tooltip: 'Send',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: widget.onVoiceInput,
                    tooltip: 'Voice input',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentChip(MessageAttachment attachment, int index) {
    return Chip(
      avatar: Icon(
        attachment.type == AttachmentType.image
            ? Icons.image
            : Icons.attach_file,
        size: 16,
      ),
      label: Text(
        attachment.path.split('/').last,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => _removeAttachment(index),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }
}

