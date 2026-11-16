import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/student_document.dart';
import '../providers/auth_provider.dart';
import '../services/documents_service.dart';
import '../utils/app_theme.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _service = const DocumentsService();
  final _searchController = TextEditingController();
  List<StudentDocument> _documents = [];
  String _identity = '';
  String? _error;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final identity = '${auth.currentApp?.name}:${auth.currentUser?.uid}';
    if (identity != _identity) {
      _identity = identity;
      _loadDocuments();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final auth = context.read<AuthProvider>();
    final app = auth.currentApp;
    final user = auth.currentUser;
    if (app == null || user == null) {
      setState(() {
        _documents = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    final identity = '${app.name}:${user.uid}';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final documents = await _service.listForStudent(user.uid, app);
      if (!mounted || identity != _identity) return;
      setState(() {
        _documents = documents;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load student documents: $error\n$stackTrace');
      if (mounted && identity == _identity) {
        setState(() {
          _error = 'Documents could not be loaded. Check your connection and try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openDocument(StudentDocument document, {required bool download}) async {
    final uri = Uri.tryParse(document.url);
    if (uri == null) {
      _showMessage('This document link is invalid.');
      return;
    }
    try {
      final opened = await launchUrl(
        uri,
        mode: download ? LaunchMode.externalApplication : LaunchMode.platformDefault,
      );
      if (!opened) _showMessage('Could not open this document on your device.');
    } catch (error, stackTrace) {
      debugPrint('Could not open student document: $error\n$stackTrace');
      _showMessage('Could not open this document. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _documents.where((document) {
      final extension = document.name.split('.').last.toLowerCase();
      const supported = {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'};
      return supported.contains(extension) && document.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search groups',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _loadDocuments)
                    : filtered.isEmpty
                        ? const _EmptyDocuments()
                        : RefreshIndicator(
                            onRefresh: _loadDocuments,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final document = filtered[index];
                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      document.isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                                      color: AppTheme.navy,
                                      size: 28,
                                    ),
                                    title: Text(document.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(_fileType(document.name)),
                                    trailing: PopupMenuButton<String>(
                                      tooltip: 'Document actions',
                                      onSelected: (action) => _openDocument(
                                        document,
                                        download: action == 'download',
                                      ),
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'open', child: Text('Open')),
                                        PopupMenuItem(value: 'download', child: Text('Download')),
                                      ],
                                    ),
                                    onTap: () => _openDocument(document, download: false),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _fileType(String name) {
    final extension = name.split('.').last.toUpperCase();
    return '$extension document';
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_outlined, size: 62, color: AppTheme.secondaryText),
            const SizedBox(height: 28),
            Text(
              'No groups linked to this account yet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
