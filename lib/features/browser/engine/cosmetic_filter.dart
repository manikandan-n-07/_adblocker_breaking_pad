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
      $joined,
      .paisa-wrapper, .main-paisa, [class*="paisa"], [id*="paisa"],
      .topBand_adwrapper, [class*="topBand"], [class*="adwrapper"], [class*="ad_wrapper"], [class*="ad-wrapper"],
      .adInv, .appgutter, [id*="appgutter"], [data-ua-type],
      [class*="ad-placeholder"], [class*="ad_placeholder"], [class*="adPlaceholder"],
      [class*="adv-container"], [class*="adv_container"], [class*="adv-wrapper"], [class*="adv_wrapper"],
      [class*="adv-box"], [class*="adv_box"],
      [class*="advertisement-container"], [class*="advertisment-container"],
      [class*="instant-loan"], [class*="instantLoan"], [class*="instant_loan"], [class*="loan-widget"], [class*="widget-loan"],
      [class*="colombia"], [class*="clmb"], [id*="colombia"], [id*="clmb"], [data-clmb-id],
      [class*="gutter-ad"], [class*="gutter_ad"], .gutter-ad-left, .gutter-ad-right, [class*="ad-gutter"],
      [class*="skin-ad"], [class*="skin_ad"], [class*="wallpaper-ad"], [class*="wallpaper_ad"],
      [id*="skin_ad"], [id*="wallpaper"], [id*="gutter"],
      [class*="ad-holder"], [class*="ad_holder"], [class*="adHolder"],
      [class*="ad-section"], [class*="ad_section"], [class*="adSection"],
      [class*="ad-space"], [class*="ad_space"], [class*="adSpace"],
      [class*="ad-strip"], [class*="ad_strip"], [class*="adStrip"],
      [class*="ad-unit"], [class*="ad_unit"], [class*="adUnit"],
      [class*="ad-slot"], [class*="ad_slot"], [class*="adSlot"],
      [class*="ad-box"], [class*="ad_box"], [class*="adBox"],
      [class*="ad-frame"], [class*="ad_frame"], [class*="adFrame"],
      [class*="ad-banner"], [class*="ad_banner"], [class*="adBanner"],
      [class*="ad-flex"], [class*="ad_flex"],
      [class*="advertisement"], [class*="advertisment"],
      [id*="div-gpt-ad"], [id*="gpt-ad"], [data-ad-slot], [data-ad-unit], [data-slot="ad"] {
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
        margin: 0 !important;
        padding: 0 !important;
        border: none !important;
        line-height: 0 !important;
        font-size: 0 !important;
      }

      /* Strip pseudo-element ad labels like .paisa-wrapper:before { content: "advertisement" } */
      .paisa-wrapper:before, .paisa-wrapper:after,
      [class*="paisa"]:before, [class*="paisa"]:after,
      .topBand_adwrapper:before, .topBand_adwrapper:after,
      [class*="adwrapper"]:before, [class*="adwrapper"]:after,
      [class*="ad-wrapper"]:before, [class*="ad-wrapper"]:after,
      [class*="ad_wrapper"]:before, [class*="ad_wrapper"]:after,
      [class*="advertisement"]:before, [class*="advertisement"]:after,
      [class*="ad-box"]:before, [class*="ad-box"]:after,
      [class*="ad-slot"]:before, [class*="ad-slot"]:after {
        content: none !important;
        display: none !important;
        height: 0 !important;
        width: 0 !important;
        visibility: hidden !important;
        margin: 0 !important;
        padding: 0 !important;
      }

      /* Collapse empty ad containers with inline styling */
      .paisa-wrapper[style],
      .main-paisa[style],
      [class*="paisa"][style],
      [class*="adwrapper"][style],
      [class*="ad-wrapper"][style],
      [class*="ad_wrapper"][style],
      [class*="ad-box"][style],
      [class*="ad-slot"][style],
      [class*="ad-unit"][style],
      [class*="topBand"][style],
      .topBand_adwrapper[style],
      .adsbygoogle[style],
      ins.adsbygoogle[style],
      [id^="div-gpt-ad"][style],
      [data-ad-slot][style],
      [data-slot="ad"][style] {
        display: none !important;
        height: 0 !important;
        min-height: 0 !important;
        max-height: 0 !important;
        margin: 0 !important;
        padding: 0 !important;
        border: none !important;
      }

      /* Strip background wallpaper / takeover ads */
      body, html, #app, #root, .wrapper, .main-wrapper, .site-content, .content-wrapper, #main-content {
        background-image: none !important;
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

        function hideEl(el) {
          if (!el) return;
          el.style.setProperty('display', 'none', 'important');
          el.style.setProperty('height', '0px', 'important');
          el.style.setProperty('min-height', '0px', 'important');
          el.style.setProperty('max-height', '0px', 'important');
          el.style.setProperty('visibility', 'hidden', 'important');
          el.style.setProperty('overflow', 'hidden', 'important');
          el.style.setProperty('pointer-events', 'none', 'important');
          el.style.setProperty('margin', '0px', 'important');
          el.style.setProperty('padding', '0px', 'important');
          el.style.setProperty('border', 'none', 'important');
        }

        function cleanAds(root) {
          if (!root || !root.querySelectorAll) return;
          try {
            // 1. CSS selector matches
            const matches = root.querySelectorAll(selectorQuery);
            for (let i = 0; i < matches.length; i++) hideEl(matches[i]);

            // 2. Extra ad & paisa specific queries
            const extraAdWrappers = root.querySelectorAll('.paisa-wrapper, .main-paisa, [class*="paisa" i], [id*="paisa" i], .topBand_adwrapper, [class*="topBand" i], .adInv, .appgutter, [class*="adwrapper" i], [class*="ad-wrapper" i], [class*="ad_wrapper" i], [class*="adbox" i], [class*="ad-box" i], [class*="ad_box" i], [class*="adslot" i], [class*="ad-slot" i], [class*="ad_slot" i], [class*="adunit" i], [class*="ad-unit" i], [class*="adholder" i], [class*="ad-holder" i]');
            for (let i = 0; i < extraAdWrappers.length; i++) {
              hideEl(extraAdWrappers[i]);
              if (extraAdWrappers[i].parentElement && (extraAdWrappers[i].parentElement.children.length === 1 || (extraAdWrappers[i].parentElement.className && extraAdWrappers[i].parentElement.className.toLowerCase().includes('paisa')))) {
                hideEl(extraAdWrappers[i].parentElement);
              }
            }

            // 3. Hide iframes used for ads (by src patterns)
            const iframes = root.querySelectorAll('iframe[src*="doubleclick"], iframe[src*="googlesyndication"], iframe[src*="adservice"], iframe[src*="ads"], iframe[src*="adnxs"], iframe[src*="taboola"], iframe[src*="outbrain"], iframe[src*="clmb"], iframe[src*="colombia"]');
            for (let f of iframes) {
              hideEl(f);
              if (f.parentElement && f.parentElement.children.length === 1) {
                hideEl(f.parentElement);
              }
            }

            // 4. Purge Elements with "Advertisement" / "Sponsored" (both in DOM text and in CSS ::before / ::after)
            const textNodes = root.querySelectorAll('div, span, p, label, b, em, strong, a, section, aside');
            const AD_KEYWORDS = ['advertisement', 'sponsored', 'promoted', 'ads by google'];
            for (let el of textNodes) {
              if (!el) continue;
              const txt = (el.textContent || '').trim().toLowerCase();
              let isAdLabel = AD_KEYWORDS.includes(txt) || (txt.startsWith('advertisement') && txt.length < 25);

              if (!isAdLabel) {
                try {
                  const bContent = window.getComputedStyle(el, '::before').getPropertyValue('content');
                  if (bContent && (bContent.toLowerCase().includes('advertisement') || bContent.toLowerCase().includes('sponsored'))) {
                    isAdLabel = true;
                  }
                } catch(e) {}
              }

              if (isAdLabel) {
                hideEl(el);
                let curr = el;
                for (let d = 0; d < 4; d++) {
                  if (!curr.parentElement || curr.parentElement === document.body || curr.parentElement === document.documentElement) break;
                  curr = curr.parentElement;
                  const pHeight = parseInt(window.getComputedStyle(curr).minHeight) || parseInt(curr.style.minHeight) || parseInt(curr.style.height) || 0;
                  const pCls = (curr.className || '').toLowerCase();
                  const pId = (curr.id || '').toLowerCase();
                  const hasAdIndicator = pCls.includes('ad') || pCls.includes('paisa') || pCls.includes('banner') || pCls.includes('slot') || pCls.includes('wrapper') || pId.includes('ad') || pId.includes('paisa') || curr.children.length <= 2;
                  if (pHeight > 30 || hasAdIndicator) {
                    hideEl(curr);
                  }
                }
              }
            }

            // 5. Collapse empty / blank ad placeholder containers
            const containers = root.querySelectorAll('div, section, aside');
            for (let el of containers) {
              const cls = (typeof el.className === 'string' ? el.className : '').toLowerCase();
              const id = (el.id || '').toLowerCase();
              if (cls.includes('paisa') || cls.includes('ad-') || cls.includes('ad_') || cls.includes('adv_') || cls.includes('adbox') || cls.includes('adslot') || cls.includes('adwrapper') || id.includes('gpt-ad') || id.includes('dfp')) {
                const innerTxt = (el.innerText || el.textContent || '').trim().replace(/advertisement|sponsored|promoted/ig, '').trim();
                const hasImg = el.querySelector('img:not([width="1"]):not([height="1"])');
                if (!hasImg && innerTxt.length === 0) {
                  hideEl(el);
                  if (el.parentElement && (el.parentElement.children.length === 1 || el.parentElement.className.toLowerCase().includes('paisa'))) {
                    hideEl(el.parentElement);
                  }
                }
              }
            }

            // 6. Purge Loan Badges & Corner widgets ("INSTANT LOAN", etc.)
            const loanEls = root.querySelectorAll('[class*="loan" i], [id*="loan" i], [class*="instant" i], a[href*="loan" i]');
            for (let el of loanEls) {
              const txt = (el.textContent || '').trim().toLowerCase();
              const cls = (el.className && typeof el.className === 'string' ? el.className : '').toLowerCase();
              if (txt.includes('loan') || txt.includes('apply now') || cls.includes('loan') || cls.includes('instant')) {
                const pos = window.getComputedStyle(el).position;
                if (pos === 'fixed' || pos === 'absolute' || cls.includes('badge') || cls.includes('widget') || cls.includes('corner') || cls.includes('ad')) {
                  hideEl(el);
                }
              }
            }

            // 7. Remove Wallpaper / Takeover Background Ads
            if (document.body) {
              const bodyBg = window.getComputedStyle(document.body).backgroundImage;
              if (bodyBg && bodyBg !== 'none') {
                document.body.style.setProperty('background-image', 'none', 'important');
              }
            }
            if (document.documentElement) {
              const docBg = window.getComputedStyle(document.documentElement).backgroundImage;
              if (docBg && docBg !== 'none') {
                document.documentElement.style.setProperty('background-image', 'none', 'important');
              }
            }

            // 8. Sticky bottom / floating ads
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
        setInterval(runClean, 1000);

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

  /// Builds a lightweight immediate cleanup snippet for execution during page navigation/progress
  String buildCleanupSnippetJs({String? domain}) {
    if (!ruleManager.isCosmeticFilteringEnabled) return '';
    if (domain != null && ruleManager.isDomainAllowlisted(domain)) return '';

    return '''
      (function() {
        try {
          function hideEl(el) {
            if (!el) return;
            el.style.setProperty('display', 'none', 'important');
            el.style.setProperty('height', '0px', 'important');
            el.style.setProperty('min-height', '0px', 'important');
            el.style.setProperty('max-height', '0px', 'important');
            el.style.setProperty('visibility', 'hidden', 'important');
            el.style.setProperty('overflow', 'hidden', 'important');
            el.style.setProperty('margin', '0px', 'important');
            el.style.setProperty('padding', '0px', 'important');
          }

          const adSelectors = [
            '.paisa-wrapper', '.main-paisa', '[class*="paisa" i]', '[id*="paisa" i]',
            '.topBand_adwrapper', '[class*="topBand" i]', '.adInv', '.appgutter',
            '[class*="adwrapper" i]', '[class*="ad-wrapper" i]', '[class*="ad_wrapper" i]',
            '[class*="adbox" i]', '[class*="ad-box" i]', '[class*="ad_box" i]',
            '[class*="adslot" i]', '[class*="ad-slot" i]', '[class*="ad_slot" i]',
            '[class*="adunit" i]', '[class*="ad-unit" i]', '[class*="adholder" i]',
            '.adsbygoogle', 'ins.adsbygoogle', '[id^="div-gpt-ad"]', '[data-ad-slot]',
            '[class*="ad-placeholder"]', '[class*="ad_placeholder"]', '[class*="advertisement-container"]',
            '[class*="colombia"]', '[class*="clmb"]', '[id*="colombia"]', '[id*="clmb"]',
            '[class*="instant-loan"]', '[class*="loan-widget"]', '[class*="gutter-ad"]',
            '[class*="skin-ad"]', '[class*="wallpaper-ad"]'
          ];
          const matches = document.querySelectorAll(adSelectors.join(','));
          for (let i = 0; i < matches.length; i++) {
            hideEl(matches[i]);
            if (matches[i].parentElement && (matches[i].parentElement.children.length === 1 || (matches[i].parentElement.className && matches[i].parentElement.className.toLowerCase().includes('paisa')))) {
              hideEl(matches[i].parentElement);
            }
          }

          // Collapse parent wrappers with text "Advertisement" or ::before "advertisement"
          const allText = document.querySelectorAll('div, span, p, label, b, strong, section, aside');
          for (let el of allText) {
            const txt = (el.textContent || '').trim().toLowerCase();
            let isAd = (txt === 'advertisement' || txt === 'sponsored' || txt === 'promoted' || (txt.startsWith('advertisement') && txt.length < 25));
            if (!isAd) {
              try {
                const bContent = window.getComputedStyle(el, '::before').getPropertyValue('content');
                if (bContent && (bContent.toLowerCase().includes('advertisement') || bContent.toLowerCase().includes('sponsored'))) {
                  isAd = true;
                }
              } catch(e) {}
            }
            if (isAd) {
              hideEl(el);
              let curr = el;
              for (let d = 0; d < 4; d++) {
                if (!curr.parentElement || curr.parentElement === document.body) break;
                curr = curr.parentElement;
                hideEl(curr);
              }
            }
          }

          // Strip background takeover
          if (document.body && window.getComputedStyle(document.body).backgroundImage !== 'none') {
            document.body.style.setProperty('background-image', 'none', 'important');
          }
        } catch(e) {}
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
      '[data-ad-client]',
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
      '[class*="instant-loan"]',
      '[class*="instantLoan"]',
      '[class*="instant_loan"]',
      '[class*="loan-widget"]',
      '[class*="widget-loan"]',
      '[class*="corner-widget"]',
      '[class*="cornerWidget"]',
      '[class*="corner_widget"]',
      '[class*="chat-widget"][class*="promo"]',
      '[class*="chatbot-promo"]',
      '[class*="lead-form"]',
      '[class*="leadForm"]',
      '[class*="lead_form"]',

      // Colombia / CLMB Ad Network (Times of India / Indiatimes native ads)
      '[class*="colombia"]',
      '[class*="clmb"]',
      '[id*="colombia"]',
      '[id*="clmb"]',
      '[data-clmb-id]',
      '[data-advt]',
      '[data-advertisement]',
      '[data-ad]',

      // Empty ad placeholders and wrappers
      '[class*="ad-placeholder"]',
      '[class*="ad_placeholder"]',
      '[class*="adPlaceholder"]',
      '[class*="adv-container"]',
      '[class*="adv_container"]',
      '[class*="adv-wrapper"]',
      '[class*="adv_wrapper"]',
      '[class*="adv-box"]',
      '[class*="adv_box"]',
      '[class*="advertisement-container"]',
      '[class*="advertisment-container"]',

      // Takeover, Skin, Wallpaper & Gutter ads
      '[class*="skin-ad"]',
      '[class*="skin_ad"]',
      '[class*="wallpaper-ad"]',
      '[class*="wallpaper_ad"]',
      '[id*="skin_ad"]',
      '[id*="wallpaper"]',
      '[id*="gutter"]',
      '[class*="gutter-ad"]',
      '[class*="gutter_ad"]',
      '.gutter-ad-left',
      '.gutter-ad-right',
      '[class*="ad-gutter"]',

      // Additional TOI / Indian news
      '.paisa-wrapper',
      '.main-paisa',
      '[class*="paisa"]',
      '[id*="paisa"]',
      '.topBand_adwrapper',
      '[class*="topBand"]',
      '[class*="adwrapper"]',
      '[class*="ad_wrapper"]',
      '[class*="ad-wrapper"]',
      '[class*="adbox"]',
      '[class*="ad-box"]',
      '[class*="ad_box"]',
      '[class*="adslot"]',
      '[class*="ad-slot"]',
      '[class*="ad_slot"]',
      '[class*="adunit"]',
      '[class*="ad-unit"]',
      '[class*="ad_unit"]',
      '[class*="adholder"]',
      '[class*="ad-holder"]',
      '[class*="ad_holder"]',
      '[class*="adspace"]',
      '[class*="ad-space"]',
      '[class*="ad_space"]',
      '[class*="adstrip"]',
      '[class*="ad-strip"]',
      '[class*="ad_strip"]',
      '[class*="adsection"]',
      '[class*="ad-section"]',
      '[class*="ad_section"]',
      '.adInv',
      '.appgutter',
      '[id*="appgutter"]',
      '[data-slot="ad"]',
      '[data-ad="true"]',
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
