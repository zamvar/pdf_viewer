import 'package:flutter/material.dart';

class PdfViewerControls {
  final BuildContext context;
  final int pageNumber;
  final int totalPages;
  final VoidCallback previousPage;
  final VoidCallback nextPage;
  final VoidCallback zoom;
  final VoidCallback unzoom;
  final VoidCallback onChangedOrientation;

  PdfViewerControls(
      {required this.context,
      required this.pageNumber,
      required this.totalPages,
      required this.previousPage,
      required this.nextPage,
      required this.zoom,
      required this.unzoom,
      required this.onChangedOrientation});
}
