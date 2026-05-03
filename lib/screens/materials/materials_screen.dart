import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/materials_provider.dart';
import '../../models/document_model.dart';
import '../../services/pdf_service.dart';
import '../../utils/app_theme.dart';
import 'document_detail_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});
  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MaterialsProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: () => context.read<MaterialsProvider>().fetchDocuments(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Upload'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: _buildBody(prov)),
    );
  }

  Widget _buildBody(MaterialsProvider prov) {
    if (prov.isLoading && prov.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (prov.isUploading) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: AppColors.accent),
        const SizedBox(height: 16),
        const Text('Uploading & processing...', style: TextStyle(color: AppColors.secondary)),
        const SizedBox(height: 8),
        LinearProgressIndicator(color: AppColors.accent, backgroundColor: AppColors.accentLight,
            minHeight: 4),
      ]));
    }
    if (prov.documents.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.upload_file_rounded, color: AppColors.accent, size: 40)),
          const SizedBox(height: 20),
          const Text('No materials yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Upload a PDF or paste text to get started.\nEarn +50 XP per upload!',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.secondary, height: 1.6)),
        ]),
      ));
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<MaterialsProvider>().fetchDocuments(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: prov.documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _DocCard(doc: prov.documents[i]),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _UploadSheet(),
    );
  }
}

class _DocCard extends StatelessWidget {
  final DocumentModel doc;
  const _DocCard({required this.doc});
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete document?'),
            content: Text('Delete "${doc.title}"? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: AppColors.error))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => context.read<MaterialsProvider>().deleteDocument(doc.id),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc))),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
          child: Row(children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_outlined, color: AppColors.accent, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
              const SizedBox(height: 4),
              Text(DateFormat('MMM dd, yyyy').format(doc.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(doc.rawText.length > 80 ? '${doc.rawText.substring(0, 80)}...' : doc.rawText,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  const _UploadSheet();
  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _titleCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    setState(() { _isProcessing = true; _error = null; });
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['pdf'],
          withData: true);
      if (result == null || result.files.isEmpty) { setState(() => _isProcessing = false); return; }
      final file = result.files.first;
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) throw Exception('Could not read file.');

      final inputTitle = _titleCtrl.text.trim();
      final title = inputTitle.isNotEmpty ? inputTitle : file.name.replaceAll('.pdf', '');
      final text = await PdfService.extractText(Uint8List.fromList(bytes));
      if (text.trim().isEmpty) throw Exception('PDF appears to be empty or image-only.');

      if (!mounted) return;
      final prov = context.read<MaterialsProvider>();
      Navigator.pop(context);
      final doc = await prov.saveDocument(title: title, rawText: text);
      if (!mounted) return;
      if (doc != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Document uploaded! +50 XP earned')));
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isProcessing = false; });
    }
  }

  Future<void> _submitText() async {
    final title = _titleCtrl.text.trim();
    final text = _textCtrl.text.trim();
    if (title.isEmpty || text.isEmpty) {
      setState(() => _error = 'Please fill in both title and text.'); return;
    }
    setState(() { _isProcessing = true; _error = null; });
    final prov = context.read<MaterialsProvider>();
    Navigator.pop(context);
    final doc = await prov.saveDocument(title: title, rawText: text);
    if (!mounted) return;
    if (doc != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Document saved! +50 XP earned')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 20),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('Upload Material', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary))),
        const SizedBox(height: 4),
        const Text('+50 XP on upload', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.accent,
            tabs: const [Tab(text: 'PDF File'), Tab(text: 'Text Input')],
          ),
        ),
        SizedBox(
          height: 380,
          child: TabBarView(controller: _tabCtrl, children: [
            _buildPdfTab(),
            _buildTextTab(),
          ]),
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        const SizedBox(height: 16),
      ]),
      ),
    );
  }

  Widget _buildPdfTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        TextField(controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Document title (Optional)', labelText: 'Title')),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _isProcessing ? null : _pickPdf,
          child: Container(
            width: double.infinity, height: 120,
            decoration: BoxDecoration(
                color: AppColors.accentLight, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent, style: BorderStyle.solid)),
            child: _isProcessing
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                    SizedBox(height: 10),
                    Text('Extracting text...', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                  ]))
                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent, size: 40),
                    SizedBox(height: 8),
                    Text('Tap to select PDF', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    Text('Text is extracted on-device', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        TextField(controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Document title', labelText: 'Title')),
        const SizedBox(height: 12),
        TextField(controller: _textCtrl, maxLines: 4, minLines: 3,
            decoration: const InputDecoration(hintText: 'Paste your notes or content here...', labelText: 'Content')),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _submitText,
            child: const Text('Save Document'),
          ),
        ),
      ]),
    );
  }
}
