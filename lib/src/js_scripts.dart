  const String linkHandlerJS = r"""
        (function() {
          document.addEventListener('click', function(ev) {
            var node = ev.target;

            while (node && node !== document) {
              if (node.tagName && node.tagName.toLowerCase() === 'a') break;
              node = node.parentNode;
            }
            if (!node || node === document) return;

            var href = node.getAttribute('href') || node.href;
            if (!href) return;

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