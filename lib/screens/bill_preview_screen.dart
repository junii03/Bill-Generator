import 'package:flutter/material.dart';
import 'package:pdf_viewer_plus/pdf_viewer.dart';

class BillPreviewScreen extends StatelessWidget {
  final String pdfPath;
  const BillPreviewScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Viewer with Thumbnails')),
      body: PdfViewer(
        pdfPath: pdfPath,
        initialSidebarOpen: true, // Start with sidebar open
        sidebarWidth: 180, // Custom sidebar width
        thumbnailHeight: 160, // Custom thumbnail height
        sidebarBackgroundColor: Colors.grey[300]!, // Custom sidebar color
      ),
    );
  }
}
