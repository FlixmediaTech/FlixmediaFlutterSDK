import 'dart:async';
import 'dart:math';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'flix_bridge.dart';

class FlixInpageHtmlView extends StatefulWidget {
  final Map<String, dynamic> productParams;
  final String? baseURL;

  const FlixInpageHtmlView({
    super.key,
    required this.productParams,
    this.baseURL,
  });

  @override
  State<FlixInpageHtmlView> createState() => _FlixInpageHtmlViewState();
}

class _FlixInpageHtmlViewState extends State<FlixInpageHtmlView> {
  InAppWebViewController? _controller;
  double _height = 1;
  String? _html;

  ScrollPosition? _scrollPosition;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  static const _throttle = Duration(milliseconds: 50);

  static const String _resizeObserverJS = r"""
        function sendResizeMessage() {
            try { 
              window.flutter_inappwebview.callHandler('onResize', document.body.scrollHeight); 
            } catch (e) {}
        }
        const observer = new MutationObserver(function(mutations) { sendResizeMessage(); });
        observer.observe(document.body, { childList: true, subtree: true, attributes: true });
        window.addEventListener("load", sendResizeMessage);
  """;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPos = Scrollable.of(context)?.position;
    if (_scrollPosition != newPos) {
      _scrollPosition?.removeListener(_onParentScrolled);
      _scrollPosition = newPos;
      _scrollPosition?.addListener(_onParentScrolled);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendViewportMetrics());
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onParentScrolled);
    super.dispose();
  }

  void _onParentScrolled() {
    final now = DateTime.now();
    if (now.difference(_lastSent) >= _throttle) {
      _lastSent = now;
      _sendViewportMetrics();
    }
  }

  Future<void> _loadHtml() async {
    final html = await FlixBridge.getInpageHtml(productParams: widget.productParams);
    if (!mounted) return;
    setState(() {
      _html = html ?? '<html><body><div style="padding:12px;color:#777">No HTML</div></body></html>';
    });
  }

  Rect _webViewGlobalRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return Rect.zero;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Rect _viewportGlobalRect() {
    final scrollable = Scrollable.of(context);
    final ro = scrollable?.context.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return Rect.zero;
    final topLeft = ro.localToGlobal(Offset.zero);
    return topLeft & ro.size;
  }

  Future<void> _sendViewportMetrics() async {
    if (_controller == null) return;

    final w = _webViewGlobalRect();
    final vp = _viewportGlobalRect();
    if (w == Rect.zero || vp == Rect.zero) return;

    final intersection = w.intersect(vp);

    final double topOffset = (intersection.top - w.top).clamp(0.0, w.height);

    final double visibleHeight = intersection.height.clamp(0.0, w.height);

    final js = """
      (function(){
        try {
          if (typeof InpageModuleTracker !== 'undefined' &&
              typeof InpageModuleTracker.onScrollFromApp === 'function') {
            InpageModuleTracker.onScrollFromApp(${topOffset.toStringAsFixed(2)}, ${visibleHeight.toStringAsFixed(2)});
          }
        } catch(e) {}
      })();
    """;

    try {
      await _controller!.evaluateJavascript(source: js);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_html == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: _height,
      child: InAppWebView(
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          disableVerticalScroll: true,
          disableHorizontalScroll: true,
          supportZoom: false,
          transparentBackground: false,
          isInspectable: true,
        ),
        initialUserScripts: UnmodifiableListView<UserScript>([
          UserScript(
            source: _resizeObserverJS,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          ),
        ]),
        initialData: InAppWebViewInitialData(
          data: _html!,
          baseUrl: widget.baseURL != null ? WebUri(widget.baseURL!) : null,
        ),
        onWebViewCreated: (c) {
          _controller = c;
          c.addJavaScriptHandler(
            handlerName: 'onResize',
            callback: (args) {
              if (args.isEmpty) return null;
              final newH = max(1.0, (args.first as num).toDouble());
              if (newH != _height && mounted) {
                setState(() => _height = newH);
                WidgetsBinding.instance.addPostFrameCallback((_) => _sendViewportMetrics());
              }
              return null;
            },
          );
        },
        onLoadStop: (c, url) async {
          await c.evaluateJavascript(
            source: "try { window.flutter_inappwebview.callHandler('onResize', document.body.scrollHeight); } catch(e){}",
          );
          WidgetsBinding.instance.addPostFrameCallback((_) => _sendViewportMetrics());
        },
      ),
    );
  }
}
