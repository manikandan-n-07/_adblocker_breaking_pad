import 'filter_rule_manager.dart';

class CosmeticFilter {
  final FilterRuleManager ruleManager;

  CosmeticFilter({required this.ruleManager});

  /// Builds the consolidated CSS stylesheet to inject into web pages.
  String buildCssRules({String? domain}) {
    if (!ruleManager.isCosmeticFilteringEnabled) return '';
    if (domain != null && ruleManager.isDomainAllowlisted(domain)) return '';

    final selectors = ruleManager.cosmeticSelectors;
    if (selectors.isEmpty) return '';

    final joined = selectors.join(', ');
    return '''
      $joined {
        display: none !important;
        height: 0 !important;
        min-height: 0 !important;
        max-height: 0 !important;
        max-width: 0 !important;
        width: 0 !important;
        visibility: hidden !important;
        pointer-events: none !important;
        opacity: 0 !important;
        overflow: hidden !important;
        position: absolute !important;
        left: -9999px !important;
      }

      /* Collapse empty ad containers that left whitespace */
      .adsbygoogle[style],
      ins.adsbygoogle[style],
      [id^="div-gpt-ad"][style] {
        display: none !important;
        height: 0 !important;
      }
    ''';
  }

  /// Builds aggressive MutationObserver + style injector JS
  String buildMutationObserverJs({String? domain}) {
    if (!ruleManager.isCosmeticFilteringEnabled) return '';
    if (domain != null && ruleManager.isDomainAllowlisted(domain)) return '';

    final selectors = ruleManager.cosmeticSelectors.map((s) => "'${s.replaceAll("'", "\\'")}'").join(',');

    return '''
      (function() {
        if (window.__breakingPadCosmeticInjected) return;
        window.__breakingPadCosmeticInjected = true;

        const adSelectors = [$selectors];
        const selectorQuery = adSelectors.join(',');

        // Additional aggressive text-based patterns for inline ads
        const AD_LABEL_TEXTS = ['advertisement', 'sponsored', 'promoted'];

        function isAdByText(el) {
          if (!el || !el.textContent) return false;
          const txt = el.textContent.trim().toLowerCase();
          return AD_LABEL_TEXTS.some(t => txt === t) && el.textContent.trim().length < 20;
        }

        function hideEl(el) {
          if (!el) return;
          el.style.setProperty('display', 'none', 'important');
          el.style.setProperty('height', '0px', 'important');
          el.style.setProperty('min-height', '0px', 'important');
          el.style.setProperty('visibility', 'hidden', 'important');
          el.style.setProperty('overflow', 'hidden', 'important');
          el.style.setProperty('pointer-events', 'none', 'important');
        }

        function cleanAds(root) {
          if (!root || !root.querySelectorAll) return;
          try {
            // 1. CSS selector matches
            const matches = root.querySelectorAll(selectorQuery);
            for (let i = 0; i < matches.length; i++) hideEl(matches[i]);

            // 2. Hide iframes used for ads (by src patterns)
            const iframes = root.querySelectorAll('iframe[src*="doubleclick"], iframe[src*="googlesyndication"], iframe[src*="adservice"], iframe[src*="ads"], iframe[src*="adnxs"], iframe[src*="taboola"], iframe[src*="outbrain"]');
            for (let f of iframes) hideEl(f);

            // 3. Hide elements whose parent is a known ad wrapper
            const adWrappers = root.querySelectorAll('[class*="advertisement"], [class*="ad-container"], [class*="ad_container"], [class*="adSlot"], [class*="ad-slot"], [class*="ad-wrapper"], [id*="advertisement"], [id*="gpt-ad"], [id*="ad-slot"]');
            for (let el of adWrappers) hideEl(el);

            // 4. Floating overlay / sticky ads (bottom/corner popups)
            const fixedEls = root.querySelectorAll('[style*="position: fixed"], [style*="position:fixed"], [style*="position: sticky"], [style*="position:sticky"]');
            const adClassPattern = /(?:^|[\\s_-])(?:ad|ads|advertisement|sponsor|promo|banner)(?:[\\s_-]|\$)/i;
            for (let el of fixedEls) {
              const cls = el.className && typeof el.className === 'string' ? el.className : '';
              const id  = el.id || '';
              const isAd = adClassPattern.test(cls) || adClassPattern.test(id);
              if (isAd) hideEl(el);
            }

            // 5. Sticky bottom ads
            const stickyEls = root.querySelectorAll('[class*="sticky-ad"], [class*="sticky_ad"], [class*="bottom-ad"], [class*="bottom_ad"], [class*="fixed-ad"], [class*="float-ad"], [class*="floating-ad"], [id*="sticky-ad"], [id*="float-ad"]');
            for (let el of stickyEls) hideEl(el);

          } catch(e) {}
        }

        // Block adsbygoogle.push to prevent new ads rendering
        try {
          if (window.adsbygoogle) {
            window.adsbygoogle.push = function() { return 0; };
          }
          Object.defineProperty(window, 'adsbygoogle', {
            get: () => ({ loaded: true, push: () => 0 }),
            set: (v) => {},
            configurable: true
          });
        } catch(e) {}

        // Run on initial DOM
        function runClean() {
          if (document.body) cleanAds(document.body);
        }
        runClean();

        // Run periodically to catch lazy-loaded ads
        setInterval(runClean, 1500);

        // MutationObserver for dynamically injected ad nodes
        const observer = new MutationObserver((mutations) => {
          for (let mutation of mutations) {
            for (let node of mutation.addedNodes) {
              if (node.nodeType === 1) cleanAds(node);
            }
          }
        });

        observer.observe(document.documentElement || document, {
          childList: true,
          subtree: true
        });
      })();
    ''';
  }

  /// Extended cosmetic selectors covering Indian news sites, news aggregators and common ad networks
  static List<String> getExtendedSelectors() {
    return [
      // Generic ad by class/attribute
      '.adsbygoogle',
      'ins.adsbygoogle',
      '[id^="div-gpt-ad"]',
      '[data-ad-slot]',
      '[data-ad-unit]',
      '[data-google-query-id]',
      '.ad-banner',
      '.ad-container',
      '.ad-wrapper',
      '.ad-block',
      '.ad-unit',
      '.ad-slot',
      '.ad-row',
      '.ad-top',
      '.ad-bottom',
      '.ad-box',
      '.ad-label',
      '.ad-frame',
      '.ad-section',
      '.ad-flex',
      '.ad-strip',
      '.ad-horizontal',
      '.ad-vertical',
      '.ad-inline',
      '.ad-fixed',
      '.ad-sticky',
      '.ad-overlay',
      '.ad-interstitial',
      '.ad-popup',
      '.adunit',
      '.adwrap',
      '.adDiv',
      '.ad_banner',
      '.ad_wrapper',
      '.ad_container',
      '.ad_box',
      '.ad_unit',
      '.ad_slot',
      '[class*="advertisement"]',
      '[class*="advertisment"]',
      '[class*="adBanner"]',
      '[class*="adContainer"]',
      '[class*="adWrapper"]',
      '[class*="adSlot"]',
      '[class*="adUnit"]',
      '[id*="advertisement"]',
      '[id*="adBanner"]',
      '[id*="adContainer"]',
      '[id*="gpt-ad"]',
      '[id*="ad-slot"]',
      '[id*="ad_slot"]',
      '.popup-backdrop',
      '.modal-backdrop',
      '.overlay-ad',

      // Times of India / Indian news specific
      '.toi-plus-subscription',
      '.toi-prem-popup',
      '[class*="dontMiss"]',
      '.crtv-banner',
      '.crtv_div',
      '[id*="criteo"]',
      '.criteo-slot',
      '[id*="taboola"]',
      '[class*="taboola"]',
      '[data-taboola-id]',
      '[id*="outbrain"]',
      '[class*="outbrain"]',
      '.OUTBRAIN',
      '.ob-widget',
      '[id*="mediabrix"]',
      '[class*="mediabrix"]',
      '.mgadv',
      '.mgadbox',
      '[class*="mgid"]',
      '[id*="mgid"]',
      '.btm-sticky-wrapper',
      '.dfp-ad-wrapper',
      '.dfp-ad',
      '.dfp-slot',
      '.dfp-banner',
      '[class*="dfp"]',
      '[class*="gam-slot"]',
      '[id*="dfp"]',
      '.storyAd',
      '.story-ad',
      '.story_ad',
      '.articleAd',
      '.article-ad',
      '.article_ad',
      '.inArticleAd',
      '.in-article-ad',
      '.topAd',
      '.top-ad',
      '.bottomAd',
      '.bottom-ad',
      '.stickyad',
      '.sticky-ad',
      '.floatingAd',
      '.floating-ad',
      '.float-ad',
      '.corner-ad',
      '.interstitial-ad',
      '.overlay-ad',
      '.newsletter-modal',
      '.subscription-popup',

      // YouTube
      'ytm-promoted-sparkles-web-renderer',
      'ytm-companion-ad-renderer',
      'ytm-statement-banner-renderer',
      'ytd-ad-slot-renderer',
      'ytd-promoted-video-renderer',
      'ytd-in-feed-ad-layout-renderer',
      'ytm-promoted-video-renderer',
      '.ytp-ad-module',
      '.ytp-ad-overlay-container',
      '#player-ads',
      '.ytp-ad-text',
      '.ytp-ad-preview-container',
      '.ytp-ad-skip-button-container',
      '.ytp-ad-message-container',
      '.ytp-ad-player-overlay',
      '.ad-showing .ytp-ad-player-overlay',

      // Floating / fixed corner ads
      '[class*="sticky"][class*="ad"]',
      '[class*="float"][class*="ad"]',
      '[class*="fixed"][class*="ad"]',

      // Loan / instant loan corner widgets (common on Indian news sites)
      '[class*="loan"]',
      '[class*="Loan"]',
      '[id*="loan"]',
      '[id*="Loan"]',
      '[class*="instant-"]',
      '[class*="corner-widget"]',
      '[class*="cornerWidget"]',
      '[class*="corner_widget"]',
      '[class*="chat-widget"][class*="promo"]',
      '[class*="chatbot-promo"]',
      '[class*="lead-form"]',
      '[class*="leadForm"]',
      '[class*="lead_form"]',

      // Additional TOI / Indian news
      '.toi-ad',
      '.toi_ad',
      '[id*="toi-ad"]',
      '[id*="toi_ad"]',
      '.nav-ad',
      '.topbar-ad',
      '.header-ad',
      '.footer-ad',
      '[class*="native-ad"]',
      '[class*="native_ad"]',
      '[class*="nativeAd"]',
      '.sponsored-content',
      '.sponsored_content',
      '[class*="sponsoredContent"]',
      '[class*="sponsored-"]',
      '.promoted-content',
      '[class*="promotedContent"]',
      '[class*="widget-ad"]',
      '[class*="widgetAd"]',
      '.ad-300x250',
      '.ad-728x90',
      '.ad-320x50',
      '.ad-160x600',
    ];
  }
}
