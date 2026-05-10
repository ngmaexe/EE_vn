// bookmark.js - Script to save reader's stopping point
(function () {
  // Function to send current URL to parent window
  function sendCurrentUrl() {
    if (window.parent && window.parent !== window) {
      const currentUrl = window.location.href;
      window.parent.postMessage(
        {
          type: "updateBookmark",
          url: currentUrl,
        },
        "*",
      );
    }
  }

  // Send URL when page loads
  window.addEventListener("load", sendCurrentUrl);

  // Send URL when hash changes (for internal navigation)
  window.addEventListener("hashchange", sendCurrentUrl);
})();
