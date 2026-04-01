(function () {
  const STORAGE_KEY = "fastflow_site_lang";
  const SUPPORTED = ["zh", "en"];

  function normalize(input) {
    if (!input) return null;
    const value = String(input).toLowerCase();
    if (value.startsWith("zh")) return "zh";
    if (value.startsWith("en")) return "en";
    return null;
  }

  function inferByRegion() {
    const lang = normalize(navigator.language || "");
    if (lang === "zh") return "zh";

    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone || "";
    if (timezone === "Asia/Shanghai" || timezone === "Asia/Taipei") {
      return "zh";
    }
    return "en";
  }

  function getInitialLanguage() {
    const stored = normalize(localStorage.getItem(STORAGE_KEY));
    if (stored) return stored;
    return inferByRegion();
  }

  function setDocLanguage(lang) {
    document.documentElement.setAttribute("lang", lang === "zh" ? "zh-CN" : "en");
  }

  function updateMeta(meta, lang) {
    if (!meta) return;
    if (meta.title) document.title = meta.title;
    if (meta.description) {
      const description = document.querySelector('meta[name="description"]');
      if (description) {
        description.setAttribute("content", meta.description);
      }
    }
  }

  function applyTextDictionary(dictionary, lang) {
    const fallback = dictionary.zh || {};
    const active = dictionary[lang] || fallback;
    const allKeys = new Set([...Object.keys(fallback), ...Object.keys(active)]);

    allKeys.forEach((key) => {
      const value = active[key] ?? fallback[key];
      if (value == null) return;
      const nodes = document.querySelectorAll(`[data-i18n="${key}"]`);
      nodes.forEach((node) => {
        node.textContent = value;
      });
    });
  }

  function applyHtmlDictionary(dictionary, lang) {
    const fallback = dictionary.zh || {};
    const active = dictionary[lang] || fallback;
    const allKeys = new Set([...Object.keys(fallback), ...Object.keys(active)]);

    allKeys.forEach((key) => {
      const value = active[key] ?? fallback[key];
      if (value == null) return;
      const nodes = document.querySelectorAll(`[data-i18n-html="${key}"]`);
      nodes.forEach((node) => {
        node.innerHTML = value;
      });
    });
  }

  function renderToggle(lang) {
    const button = document.querySelector("[data-lang-toggle]");
    if (!button) return;
    button.textContent = lang === "zh" ? "EN" : "中文";
    button.setAttribute("aria-label", lang === "zh" ? "Switch to English" : "切换到中文");
  }

  function applyAltDictionary(dictionary, lang) {
    const fallback = dictionary.zh || {};
    const active = dictionary[lang] || fallback;
    const allKeys = new Set([...Object.keys(fallback), ...Object.keys(active)]);
    allKeys.forEach((key) => {
      const value = active[key] ?? fallback[key];
      if (value == null) return;
      const nodes = document.querySelectorAll(`[data-i18n-alt="${key}"]`);
      nodes.forEach((node) => {
        node.setAttribute("alt", value);
      });
    });
  }

  function applyLangOnly(lang) {
    document.querySelectorAll("[data-lang-only]").forEach((node) => {
      const target = node.getAttribute("data-lang-only");
      node.style.display = target === lang ? "" : "none";
    });
  }

  function applyConfig(config, lang) {
    setDocLanguage(lang);
    updateMeta(config.meta?.[lang] || config.meta?.zh, lang);
    if (config.text) applyTextDictionary(config.text, lang);
    if (config.html) applyHtmlDictionary(config.html, lang);
    if (config.alt) applyAltDictionary(config.alt, lang);
    applyLangOnly(lang);
    renderToggle(lang);
    if (typeof config.onLanguageChange === "function") {
      config.onLanguageChange(lang);
    }
  }

  function init(config) {
    const safeConfig = config || {};
    let lang = getInitialLanguage();
    if (!SUPPORTED.includes(lang)) {
      lang = "en";
    }

    applyConfig(safeConfig, lang);

    const toggle = document.querySelector("[data-lang-toggle]");
    if (toggle) {
      toggle.addEventListener("click", function () {
        lang = lang === "zh" ? "en" : "zh";
        localStorage.setItem(STORAGE_KEY, lang);
        applyConfig(safeConfig, lang);
      });
    }
  }

  window.FastFlowSiteI18n = {
    init,
    getLanguage: function () {
      return getInitialLanguage();
    },
  };
})();
