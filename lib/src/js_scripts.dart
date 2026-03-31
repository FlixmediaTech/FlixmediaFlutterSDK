const String flixTrackingBridgeJS = r"""
      (function() {
        function patchFlixtracking(target) {
          if (!target || (typeof target !== 'object' && typeof target !== 'function')) {
            target = {};
          }

          target.scrollToViewport = function(viewportTop, animated) {
            try {
              var shouldAnimate = animated;
              if (typeof shouldAnimate !== 'boolean') {
                shouldAnimate = true;
              }
              window.flutter_inappwebview.callHandler('scrollToViewport', viewportTop, shouldAnimate);
            } catch (e) {}
          };

          return target;
        }

        try {
          var flixtrackingRef = patchFlixtracking(window.flixtracking);

          Object.defineProperty(window, 'flixtracking', {
            configurable: true,
            enumerable: true,
            get: function() {
              return flixtrackingRef;
            },
            set: function(value) {
              flixtrackingRef = patchFlixtracking(value);
            }
          });

          window.flixtracking = flixtrackingRef;
        } catch (e) {
          window.flixtracking = patchFlixtracking(window.flixtracking);
        }
      })();
""";

const String linkHandlerJS = r"""
      (function() {
        function shouldOpenExternally(url) {
          if (!url) return false;
          var normalizedUrl = String(url).trim().replace(/&amp;/gi, '&');
          return (
            /\.(pdf|docx?|usdz)(?:$|[?#&])/i.test(normalizedUrl) ||
            /^https?:\/\/arvr\.google\.com\/scene-viewer(?:[/?#]|$)/i.test(normalizedUrl) ||
            /^intent:/i.test(normalizedUrl)
          );
        }

        document.addEventListener('click', function(ev) {
          var clicked = ev.target;
          var dataLinkNode = clicked && typeof clicked.closest === 'function'
            ? clicked.closest('[data-link]')
            : null;

          if (dataLinkNode) {
            var dataLinkValue = dataLinkNode.getAttribute('data-link');
            if (!dataLinkValue) return;

            var dataLinkUrl = '';
            try {
              dataLinkUrl = new URL(dataLinkValue, window.location.href).toString();
            } catch (e) {
              return;
            }

            ev.preventDefault();
            ev.stopPropagation();
            if (typeof ev.stopImmediatePropagation === 'function') {
              ev.stopImmediatePropagation();
            }
            window.flutter_inappwebview.callHandler('onLinktap', dataLinkUrl, true);
            return;
          }

          var node = clicked;

          while (node && node !== document) {
            if (node.tagName && node.tagName.toLowerCase() === 'a') break;
            node = node.parentNode;
          }
          if (!node || node === document) return;

          var href = node.getAttribute('href') || node.href;
          if (!href || !shouldOpenExternally(href)) return;

          ev.preventDefault();
          ev.stopPropagation();
          if (typeof ev.stopImmediatePropagation === 'function') {
            ev.stopImmediatePropagation();
          }
          window.flutter_inappwebview.callHandler('onLinktap', href);
        }, true);

        try {
          window.open = function(url) {
            if (!url) return null;

            if (shouldOpenExternally(url)) {
              window.flutter_inappwebview.callHandler('onLinktap', url);
              return null;
            }

            window.location.href = url;
            return null;
          };
        } catch (e) {}
      })();
""";

const String canvas3DInteractionJS = r"""
(function() {
  var touching = false;

  function notifyStart() {
    if (touching) return;
    touching = true;
    try { window.flutter_inappwebview.callHandler('on3DInteractionStart'); } catch(e) {}
  }

  function notifyEnd() {
    if (!touching) return;
    touching = false;
    try { window.flutter_inappwebview.callHandler('on3DInteractionEnd'); } catch(e) {}
  }

  function onTouchStart(e) {
    var el = e.target;
    while (el && el !== document) {
      if (el.tagName === 'CANVAS') { notifyStart(); return; }
      el = el.parentElement;
    }
  }

  document.addEventListener('touchstart', onTouchStart, { capture: true, passive: true });
  document.addEventListener('touchend', function(e) { if (e.touches.length === 0) notifyEnd(); }, { capture: true, passive: true });
  document.addEventListener('touchcancel', notifyEnd, { capture: true, passive: true });
})();
""";

const String resizeObserverJS = r"""
        var lastHeight = 0;
        function sendResizeMessage() {
            try {
              var h = document.body.scrollHeight;
              if (h === lastHeight) return;
              lastHeight = h;
              window.flutter_inappwebview.callHandler('onResize', h);
            } catch (e) {}
        }
        const observer = new ResizeObserver(function(entries) { sendResizeMessage(); });
        observer.observe(document.body);
        window.addEventListener("load", sendResizeMessage);
""";
