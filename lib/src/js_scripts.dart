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
        function sendResizeMessage() {
            try { 
              window.flutter_inappwebview.callHandler('onResize', document.body.scrollHeight); 
            } catch (e) {}
        }
        const observer = new MutationObserver(function(mutations) { sendResizeMessage(); });
        observer.observe(document.body, { childList: true, subtree: true, attributes: true });
        window.addEventListener("load", sendResizeMessage);
""";

const String blockAutoplayAndroidJS = r"""
        (function() {
          function lockVideos() {
            var videos = document.querySelectorAll('video');
            for (var i = 0; i < videos.length; i++) {
              var v = videos[i];
              try {
                v.autoplay = false;
                v.removeAttribute('autoplay');
                v.pause();
              } catch (e) {}
            }
          }

          lockVideos();
          var observer = new MutationObserver(function() { lockVideos(); });
          observer.observe(document.documentElement, { childList: true, subtree: true });
        })();
""";
