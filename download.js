(function () {
  const config = {
    iosStoreUrl: "",
    testFlightUrl: "",
    androidUrl: "",
    fallbackUrl: "/",
  };

  const ua = navigator.userAgent || "";
  const isIOS = /iPhone|iPad|iPod/i.test(ua);
  const isAndroid = /Android/i.test(ua);

  const autoTarget = isIOS
    ? config.iosStoreUrl || config.testFlightUrl
    : isAndroid
      ? config.androidUrl
      : "";

  const status = document.querySelector("[data-download-status]");
  const autoLink = document.querySelector("[data-auto-link]");
  const iosLink = document.querySelector("[data-ios-link]");
  const testflightLink = document.querySelector("[data-testflight-link]");
  const androidLink = document.querySelector("[data-android-link]");
  const homeLink = document.querySelector("[data-home-link]");

  if (iosLink) {
    iosLink.href = config.iosStoreUrl || config.testFlightUrl || config.fallbackUrl;
    iosLink.setAttribute("aria-disabled", String(!(config.iosStoreUrl || config.testFlightUrl)));
  }

  if (testflightLink) {
    testflightLink.href = config.testFlightUrl || config.fallbackUrl;
    testflightLink.setAttribute("aria-disabled", String(!config.testFlightUrl));
  }

  if (androidLink) {
    androidLink.href = config.androidUrl || config.fallbackUrl;
    androidLink.setAttribute("aria-disabled", String(!config.androidUrl));
  }

  if (homeLink) {
    homeLink.href = config.fallbackUrl;
  }

  if (autoTarget) {
    if (status) {
      status.textContent = isIOS
        ? "检测到你正在使用 iPhone，准备跳转下载。"
        : "检测到你正在使用 Android，准备跳转下载。";
    }
    if (autoLink) {
      autoLink.href = autoTarget;
    }
    setTimeout(function () {
      window.location.href = autoTarget;
    }, 900);
  } else {
    if (status) {
      status.textContent = "下载链接还没最终确定，先保留这个中转页，后面上线后只改这里就够了。";
    }
    if (autoLink) {
      autoLink.style.display = "none";
    }
  }
})();
