import 'dart:async';
import 'dart:math';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'flix_bridge.dart';
import 'js_scripts.dart';
import 'external_link.dart';
import 'flix_inpage_controller.dart';

class FlixInpageHtmlView extends StatefulWidget {
  final Map<String, dynamic> productParams;
  final String? baseURL;
  final ScrollController? parentScrollController;
  final FlixInpageHtmlViewController? controller;
  final void Function(Object error)? onError;

  const FlixInpageHtmlView({
    super.key,
    required this.productParams,
    this.baseURL,
    this.parentScrollController,
    this.controller,
    this.onError,
  });

  @override
  State<FlixInpageHtmlView> createState() => _FlixInpageHtmlViewState();
}

class _FlixInpageHtmlViewState extends State<FlixInpageHtmlView> {
  InAppWebViewController? _controller;
  double _height = 1;
  String? _html;
  bool _is3DInteracting = false;

  ScrollPosition? _scrollPosition;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  static const _throttle = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPos = Scrollable.of(context).position;
    if (_scrollPosition != newPos) {
      _scrollPosition?.removeListener(_onParentScrolled);
      _scrollPosition = newPos;
      _scrollPosition?.addListener(_onParentScrolled);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendViewportMetrics());
  }

  @override
  void dispose() {
    widget.controller?.detach();
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
    try {
      final html = await FlixBridge.getInpageHtml(
        productParams: widget.productParams,
        baseURL: widget.baseURL,
      );
      if (!mounted) return;
      setState(() {
        _html =
            html ??
            '<html><body><div style="padding:12px;color:#777">No HTML</div></body></html>';
      });
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(e);
    }
  }

  Rect _webViewGlobalRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return Rect.zero;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Rect _viewportGlobalRect() {
    final scrollable = Scrollable.of(context);
    final ro = scrollable.context.findRenderObject();
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

    final js =
        """
      (function(){
        try {
          if (typeof window.flixtracking.onScrollFromApp === 'function') {
            window.flixtracking.onScrollFromApp(${topOffset.toStringAsFixed(2)}, ${visibleHeight.toStringAsFixed(2)});
          }
        } catch(e) {}
      })();
    """;

    try {
      await _controller!.evaluateJavascript(source: js);
    } catch (_) {}
  }

  Future<void> _scrollViewportTo(
    double viewportTop, {
    bool animated = true,
  }) async {
    if (widget.parentScrollController == null) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) {
      Future.delayed(const Duration(milliseconds: 20), () {
        _scrollViewportTo(viewportTop, animated: animated);
      });
      return;
    }

    final mediaTop = MediaQuery.of(context).padding.top;
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 0;

    final localOffset = box.localToGlobal(Offset(0, viewportTop));
    final scrollOffset =
        widget.parentScrollController!.offset +
        localOffset.dy -
        mediaTop -
        appBarHeight;

    try {
      widget.parentScrollController!.animateTo(
        scrollOffset,
        duration: animated
            ? const Duration(milliseconds: 250)
            : const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      debugPrint("Error during scrolling: $e");
    }
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
        gestureRecognizers: defaultTargetPlatform == TargetPlatform.android
            ? (_is3DInteracting
                ? <Factory<OneSequenceGestureRecognizer>>{
                    Factory<EagerGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  }
                : <Factory<OneSequenceGestureRecognizer>>{
                    Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer(),
                    ),
                  })
            : null,
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          disableVerticalScroll: defaultTargetPlatform != TargetPlatform.android,
          disableHorizontalScroll: defaultTargetPlatform != TargetPlatform.android,
          supportZoom: false,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
          transparentBackground: false,
          isInspectable: true,
        ),
        initialUserScripts: UnmodifiableListView<UserScript>([
          UserScript(
            source: flixTrackingBridgeJS,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
          if (defaultTargetPlatform == TargetPlatform.android)
            UserScript(
              source: canvas3DInteractionJS,
              injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
            ),
          UserScript(
            source: resizeObserverJS,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          ),
          UserScript(
            source: linkHandlerJS,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          ),
        ]),
        initialData: InAppWebViewInitialData(
          data: _html!,
          baseUrl: widget.baseURL != null ? WebUri(widget.baseURL!) : null,
        ),
        onWebViewCreated: (c) {
          _controller = c;
          widget.controller?.attach(c);
          c.addJavaScriptHandler(
            handlerName: 'onResize',
            callback: (args) {
              if (args.isEmpty) return null;
              final newH = max(1.0, (args.first as num).toDouble());
              if (newH != _height && mounted) {
                setState(() => _height = newH);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _sendViewportMetrics(),
                );
              }
              return null;
            },
          );
          c.addJavaScriptHandler(
            handlerName: 'onLinktap',
            callback: (args) {
              if (args.isEmpty) return null;
              final url = args.first.toString();
              final forceExternal = args.length > 1 && args[1] == true;
              if (!forceExternal && !shouldHandleAsExternalLink(url)) {
                return null;
              }
              handleExternalLink(url, context, forceExternal: forceExternal);
              return null;
            },
          );
          c.addJavaScriptHandler(
            handlerName: 'scrollToViewport',
            callback: (args) {
              try {
                if (args.isEmpty) return null;
                final first = args[0];
                if (first is! num) return null;
                final double viewportTop = first.toDouble();

                bool animated = true;
                if (args.length > 1 && args[1] is bool) {
                  animated = args[1] as bool;
                }

                _scrollViewportTo(viewportTop, animated: animated);
              } catch (_) {
                // ignore
              }
              return null;
            },
          );
          if (defaultTargetPlatform == TargetPlatform.android) {
            c.addJavaScriptHandler(
              handlerName: 'on3DInteractionStart',
              callback: (args) {
                if (mounted && !_is3DInteracting) {
                  setState(() => _is3DInteracting = true);
                }
                return null;
              },
            );
            c.addJavaScriptHandler(
              handlerName: 'on3DInteractionEnd',
              callback: (args) {
                if (mounted && _is3DInteracting) {
                  setState(() => _is3DInteracting = false);
                }
                return null;
              },
            );
          }
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url?.toString() ?? '';
          if (shouldHandleAsExternalLink(url)) {
            await handleExternalLink(url, context);
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
        onLoadStop: (c, url) async {
          await c.evaluateJavascript(
            source:
                "try { window.flutter_inappwebview.callHandler('onResize', document.body.scrollHeight); } catch(e){}",
          );
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _sendViewportMetrics(),
          );
        },
      ),
    );
  }
}
