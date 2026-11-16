import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/portal_section.dart';
import '../utils/app_theme.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({required this.section, super.key});

  final PortalSection section;

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
          onWebResourceError: (WebResourceError? error) {
            if (error == null) return;
            if (!(error.isForMainFrame ?? false)) return;
            if (mounted) {
              setState(() {
                _loading = false;
                _error = 'The official SRIT website could not be loaded.';
              });
            }
          },
        ),
      )
      ..loadRequest(widget.section.uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.label),
        leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            tooltip: 'Open website in browser',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public_off_outlined, size: 48, color: AppTheme.secondaryText),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openExternal() async {
    try {
      final opened = await launchUrl(
        widget.section.uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the website.')));
      }
    } catch (error, stackTrace) {
      debugPrint('Could not open the SRIT website: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the website.')));
      }
    }
  }
}
