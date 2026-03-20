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
        function isExternalDocumentLink(href) {
          return /\.(pdf|doc|docx)(?:[?#].*)?$/i.test(href || '');
        }

        document.addEventListener('click', function(ev) {
          var node = ev.target;

          while (node && node !== document) {
            if (node.tagName && node.tagName.toLowerCase() === 'a') break;
            node = node.parentNode;
          }
          if (!node || node === document) return;

          var href = node.getAttribute('href') || node.href;
          if (!href || !isExternalDocumentLink(href)) return;

          ev.preventDefault();
          window.flutter_inappwebview.callHandler('onLinktap', href);
        }, true);
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
