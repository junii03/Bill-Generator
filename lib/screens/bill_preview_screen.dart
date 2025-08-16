import 'package:flutter/material.dart';
import 'package:pdf_viewer_plus/pdf_viewer.dart';
import 'package:share_plus/share_plus.dart';

class BillPreviewScreen extends StatelessWidget {
  final String pdfPath;
  const BillPreviewScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    final name = pdfPath.split('/').last;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () => Share.shareXFiles([XFile(pdfPath)], text: name),
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
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: PdfViewer(
            pdfPath: pdfPath,
            initialSidebarOpen: true,
            sidebarWidth: 180,
            thumbnailHeight: 140,
            sidebarBackgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}
