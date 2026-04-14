import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../providers/document_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_button.dart';

class UploadBottomSheet extends StatefulWidget {
  const UploadBottomSheet({super.key});

  @override
  State<UploadBottomSheet> createState() => _UploadBottomSheetState();
}

class _UploadBottomSheetState extends State<UploadBottomSheet> {
  bool _isUploading = false;
  String? _uploadStatusText;
  bool _uploadingTextMode = false;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _handleUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
          _uploadStatusText = "Uploading ${result.files.single.name}...";
        });

        final provider = Provider.of<DocumentProvider>(context, listen: false);
        String inputTitle = _titleController.text.trim();
        String finalTitle = inputTitle.isNotEmpty ? inputTitle : result.files.single.name;

        dynamic doc;
        if (result.files.single.extension?.toLowerCase() == 'pdf') {
          try {
            final bytes = await File(result.files.single.path!).readAsBytes();
            final syncfusionPdf = PdfDocument(inputBytes: bytes);
            String pdfText = PdfTextExtractor(syncfusionPdf).extractText();
            syncfusionPdf.dispose();
            doc = await provider.uploadText(pdfText.trim().isEmpty ? "Empty PDF" : pdfText, title: finalTitle);
          } catch (pdfError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to read PDF format')),
              );
            }
          }
        } else {
          final stringValue = await File(result.files.single.path!).readAsString();
          doc = await provider.uploadText(stringValue, title: finalTitle);
        }

        if (doc != null && mounted) {
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Upload failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick file'), backgroundColor: AppTheme.errorColor),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _handleUploadText() async {
    final textContent = _textController.text.trim();
    if (textContent.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadStatusText = "Uploading text...";
    });

    String inputTitle = _titleController.text.trim();
    String? finalTitle = inputTitle.isNotEmpty ? inputTitle : null;

    final provider = Provider.of<DocumentProvider>(context, listen: false);
    final doc = await provider.uploadText(textContent, title: finalTitle);

    if (doc != null && mounted) {
      Provider.of<UserProvider>(context, listen: false).addXp(5);
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Upload failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }

    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            height: 4, width: 40,
            decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 24),
          Text(
            _uploadingTextMode ? 'Paste Text' : 'Upload Document',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.navyText),
          ),
          const SizedBox(height: 24),

          // Title field
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppTheme.navyText),
            decoration: InputDecoration(
              hintText: 'Document Title (Optional)',
              prefixIcon: const Icon(Icons.title, color: AppTheme.accent),
            ),
          ),
          const SizedBox(height: 16),

          if (_isUploading) ...[
            Text(_uploadStatusText ?? 'Processing...', style: const TextStyle(color: AppTheme.accent, fontSize: 14)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.borderColor,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
          ] else ...[
            if (_uploadingTextMode) ...[
              TextField(
                controller: _textController,
                maxLines: 6,
                style: const TextStyle(color: AppTheme.navyText),
                decoration: const InputDecoration(
                  hintText: 'Enter or paste document text here...',
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(text: 'SAVE TEXT', onPressed: _handleUploadText),
              TextButton(
                onPressed: () => setState(() => _uploadingTextMode = false),
                child: const Text('Back to File Upload', style: TextStyle(color: AppTheme.accent)),
              ),
            ] else ...[
              // Upload zone
              InkWell(
                onTap: _handleUploadFile,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 44, color: AppTheme.accent),
                      const SizedBox(height: 12),
                      const Text('Select PDF or TXT', style: TextStyle(color: AppTheme.navyText, fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      const Text('Tap to browse files', style: TextStyle(color: AppTheme.mutedText, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppTheme.borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppTheme.mutedText, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: AppTheme.borderColor)),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _uploadingTextMode = true),
                icon: const Icon(Icons.text_fields),
                label: const Text('Paste Raw Text'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
