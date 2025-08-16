import 'package:flutter/material.dart';
import 'package:pdf_viewer_plus/pdf_viewer.dart';

class BillPreviewScreen extends StatelessWidget {
  final String pdfPath;
  const BillPreviewScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    final name = pdfPath.split('/').last;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(name)),
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
