import 'package:advance_pdf_viewer/src/pdf_viewer_controls.dart';
import 'package:advance_pdf_viewer/src/zoomable_widget.dart';
import 'package:flutter/material.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:flutter/services.dart';

/// PDFViewer, a inbuild pdf viewer, you can create your own too.
/// [document] an instance of `PDFDocument`, document to be loaded
/// [indicatorText] color of indicator text
/// [indicatorBackground] color of indicator background
/// [pickerButtonColor] the picker button background color
/// [pickerIconColor] the picker button icon color
/// [indicatorPosition] position of the indicator position defined by `IndicatorPosition` enum
/// [showIndicator] show,hide indicator
/// [showPicker] show hide picker
/// [showNavigation] show hide navigation bar
/// [toolTip] tooltip, instance of `PDFViewerTooltip`
/// [enableSwipeNavigation] enable,disable swipe navigation
/// [scrollDirection] scroll direction horizontal or vertical
/// [lazyLoad] lazy load pages or load all at once
/// [controller] page controller to control page viewer
/// [zoomSteps] zoom steps for pdf page
/// [minScale] minimum zoom scale for pdf page
/// [maxScale] maximum zoom scale for pdf page
/// [panLimit] pan limit for pdf page
/// [onPageChanged] function called when page changes
///
class PDFViewer extends StatefulWidget {
  final PDFDocument document;
  final PDFViewerTooltip tooltip;
  final Color backgroundColor;
  final bool enableSwipeNavigation;
  final Axis? scrollDirection;
  final bool lazyLoad;
  final PageController? controller;
  final int? zoomSteps;
  final double? minScale;
  final double? maxScale;
  final double? panLimit;
  final ValueChanged<int>? onPageChanged;
  final Widget Function(PdfViewerControls controls) controlsBuilder;

  PDFViewer({
    Key? key,
    required this.document,
    this.scrollDirection,
    this.lazyLoad = true,
    this.enableSwipeNavigation = true,
    this.tooltip = const PDFViewerTooltip(),
    required this.controlsBuilder,
    this.controller,
    this.zoomSteps,
    this.minScale,
    this.maxScale,
    this.panLimit,
    this.onPageChanged,
    this.backgroundColor = Colors.grey,
  }) : super(key: key);

  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  bool _isLoading = true;
  late int _pageNumber;
  bool _swipeEnabled = true;
  List<PDFPage?>? _pages;
  late PageController _pageController;
  final Duration animationDuration = Duration(milliseconds: 200);
  final Curve animationCurve = Curves.easeIn;
  EventTrigger zoomEventTrigger = EventTrigger('');

  EventTrigger unzoomEventTrigger = EventTrigger('');
  @override
  void initState() {
    super.initState();
    _pages = List.filled(widget.document.count, null);
    _pageController = widget.controller ?? PageController();
    _pageNumber = _pageController.initialPage + 1;
    if (!widget.lazyLoad)
      widget.document.preloadPages(
        zoomEventTrigger,
        unzoomEventTrigger,
        onZoomChanged: onZoomChanged,
        zoomSteps: widget.zoomSteps,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        panLimit: widget.panLimit,
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageNumber = _pageController.initialPage + 1;
    _isLoading = true;
    _pages = List.filled(widget.document.count, null);
    // _loadAllPages();
    _loadPage();
  }

  @override
  void didUpdateWidget(PDFViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  onZoomChanged(double scale) {
    if (scale != 1.0) {
      setState(() {
        _swipeEnabled = false;
      });
    } else {
      setState(() {
        _swipeEnabled = true;
      });
    }
  }

  _loadPage() async {
    if (_pages![_pageNumber - 1] != null) return;
    setState(() {
      _isLoading = true;
    });
    final data = await widget.document.get(
      zoomEventTrigger,
      unzoomEventTrigger,
      page: _pageNumber,
      onZoomChanged: onZoomChanged,
      zoomSteps: widget.zoomSteps,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      panLimit: widget.panLimit,
    );
    _pages![_pageNumber - 1] = data;
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _animateToPage({int? page}) {
    _pageController.animateToPage(page != null ? page : _pageNumber - 1,
        duration: animationDuration, curve: animationCurve);
  }

  // _jumpToPage({int? page}) {
  //   _pageController.jumpToPage(page != null ? page : _pageNumber - 1);
  // }

  void _previousPage() {
    _pageController.previousPage(
        duration: animationDuration, curve: animationCurve);
  }

  void _nextPage() {
    _pageController.nextPage(
        duration: animationDuration, curve: animationCurve);
  }

  void _zoom() {
    zoomEventTrigger.trigger();
  }

  void _unZoom() {
    unzoomEventTrigger.trigger();
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
  }

  void _changeOrientation() {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            physics:
                _swipeEnabled && widget.enableSwipeNavigation && !_isLoading
                    ? null
                    : NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              setState(() {
                _pageNumber = page + 1;
              });
              _loadPage();
              widget.onPageChanged?.call(page);
            },
            scrollDirection: widget.scrollDirection ?? Axis.horizontal,
            controller: _pageController,
            itemCount: _pages?.length ?? 0,
            itemBuilder: (context, index) => _pages![index] == null
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : _pages![index]!,
          ),
          widget.controlsBuilder(PdfViewerControls(
              context: context,
              nextPage: _nextPage,
              zoom: _zoom,
              onChangedOrientation: _changeOrientation,
              pageNumber: _pageNumber,
              previousPage: _previousPage,
              totalPages: widget.document.count,
              unzoom: _unZoom))
        ],
      ),
    );
  }
}
