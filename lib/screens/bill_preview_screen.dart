import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdfx/pdfx.dart';

class BillPreviewScreen extends StatefulWidget {
  final String pdfPath;
  const BillPreviewScreen({super.key, required this.pdfPath});
  @override
  State<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends State<BillPreviewScreen> {
  late final PdfControllerPinch _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _controller = PdfControllerPinch(
        document: PdfDocument.openFile(widget.pdfPath),
      );
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    if (!_loading && _error == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.pdfPath.split('/').last;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () =>
                Share.shareXFiles([XFile(widget.pdfPath)], text: name),
          ),
        ],
      ),
      backgroundColor: scheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest.withOpacity(.4),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : PdfViewPinch(
                controller: _controller,
                onDocumentLoaded: (doc) {},
                onPageChanged: (page) {},
              ),
      ),
    );
  }
}
