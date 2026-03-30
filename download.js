(function () {
  const config = {
    downloadHubUrl: "https://fasting-nu.vercel.app/download",
    iosStoreUrl: "",
    androidUrl: "",
    fallbackUrl: "/",
  };

  const ua = navigator.userAgent || "";
  const isIOS = /iPhone|iPad|iPod/i.test(ua);
  const isAndroid = /Android/i.test(ua);

  const autoTarget = isIOS ? config.iosStoreUrl : isAndroid ? config.androidUrl : "";

  const status = document.querySelector("[data-download-status]");
  const autoLink = document.querySelector("[data-auto-link]");
  const iosLink = document.querySelector("[data-ios-link]");
  const androidLink = document.querySelector("[data-android-link]");
  const homeLink = document.querySelector("[data-home-link]");

  if (iosLink) {
    iosLink.href = config.iosStoreUrl || config.downloadHubUrl;
    iosLink.setAttribute("aria-disabled", String(!config.iosStoreUrl));
  }

  if (androidLink) {
    androidLink.href = config.androidUrl || config.fallbackUrl;
    androidLink.setAttribute("aria-disabled", String(!config.androidUrl));
    if (!config.androidUrl) {
      androidLink.addEventListener("click", function (event) {
        event.preventDefault();
      });
    }
  }

  if (homeLink) {
    homeLink.href = config.fallbackUrl;
  }

  if (autoLink) {
    autoLink.href = config.iosStoreUrl || config.downloadHubUrl;
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
      status.textContent = config.iosStoreUrl
        ? "如果没有自动跳转，可以手动点击上面的 iPhone 下载。"
        : "iPhone 下载入口即将开放，安卓版敬请期待。";
    }
  }
})();
