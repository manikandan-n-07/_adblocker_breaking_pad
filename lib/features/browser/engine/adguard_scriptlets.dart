class AdGuardScriptlets {
  // All known ad script domains — blocked at createElement level
  static const List<String> _blockedScriptDomains = [
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'adservice.google', 'pagead2.googlesyndication', 'imasdk.googleapis.com',
    'adnxs.com', 'appnexus.com', 'taboola.com', 'outbrain.com', 'criteo.com',
    'pubmatic.com', 'rubiconproject.com', 'openx.net', 'smartadserver.com',
    'casalemedia.com', 'contextweb.com', 'bidswitch.net', 'moatads.com',
    'sharethrough.com', 'triplelift.com', 'sovrn.com', 'yieldmo.com',
    'spotxchange.com', 'spotx.tv', 'gumgum.com', 'exponential.com',
    'conversantmedia.com', 'yieldlove.com', 'tremorhub.com', 'revjet.com',
    'flashtalking.com', 'media.net', 'amazon-adsystem.com', 'adsrvr.org',
    'adroll.com', 'bluekai.com', 'krxd.net', 'adform.net', 'thetradedesk.com',
    'serving-sys.com', 'advertising.com', 'adtechus.com', 'imrworldwide.com',
    'scorecardresearch.com', 'quantserve.com', 'lotame.com', 'mookie1.com',
    'adcolony.com', 'applovin.com', 'vungle.com', 'chartboost.com',
    'inmobi.com', 'ironsrc.com', 'mopub.com', 'smaato.net', 'startapp.com',
    'tapjoy.com', 'flurry.com', 'connect.facebook.net', 'tr.snapchat.com',
    'popads.net', 'popcash.net', 'propellerads.com', 'adcash.com',
    'exoclick.com', 'trafficjunky.com', 'mgid.com', 'revcontent.com',
    'nativo.com', 'infolinks.com', 'shareaholic.com', 'adpushup.com',
    'juicyads.com', 'clickadu.com', 'adsterra.com', 'tsyndicate.com',
    'ero-advertising.com', 'adxpansion.com', 'clksite.com', 'komli.com',
    'hotjar.com', 'clarity.ms', 'mouseflow.com', 'fullstory.com',
    'moatads.com', 'yldbt.com', 'smartclip.net', 'freewheel.tv',
    'videohub.tv', 'undertone.com', 'ad.adfactor.co.in',
    'colombiaonline.com', 'clmbtech.com', 'ade.clmbtech.com', 'static.clmbtech.com',
    'tg.indiatimes.com', 'jss.indiatimes.com', 'agi-static.indiatimes.com',
    'hserver.indiatimes.com', 'adspecs.indiatimes.com', 'tilmads.indiatimes.com',
    'timesinternet.in', 'affle.com', 'adgyde.com', 'adplus.co.in', 'zedo.com',
    'tyroo.com', 'adgebra.co.in',
  ];

  static String getDocumentStartScript({
    bool enableYouTubeMitigation = true,
    bool enablePopupProtection = true,
  }) {
    final blockedDomainsJs = _blockedScriptDomains
        .map((d) => "'$d'")
        .join(',');

    return '''
    (function() {
      'use strict';
      if (window.__breakingPadScriptletsInjected) return;
      window.__breakingPadScriptletsInjected = true;

      // ════════════════════════════════════════════════════════
      // LAYER 1: Anti-Adblock Detection Evasion
      // ════════════════════════════════════════════════════════
      try {
        // Fake "ads loaded successfully" to fool anti-adblock scripts
        window.canRunAds = true;
        window.google_ad_status = 1;
        window.google_ad_client = 'ca-pub-0000000000000000';
        window.isAdBlockActive = false;
        window.adBlockDetected = false;
        window.adBlockEnabled = false;
        window.blockAdBlock = undefined;
        window.fuckAdBlock = undefined;
        window.adsense_loaded = true;
        window.__adBlockerDetected = false;
        window.adsbygoogle = window.adsbygoogle || [];
        window.adsbygoogle.loaded = true;
        window.adsbygoogle.push = function() { return 0; };

        // Override adsbygoogle property permanently
        try {
          Object.defineProperty(window, 'adsbygoogle', {
            get: function() { return { loaded: true, push: function() { return 0; } }; },
            set: function(v) {},
            configurable: false
          });
        } catch(e) {}

        // Neutralize googletag / GPT completely
        const fakeSlot = {
          addService: function() { return this; },
          setTargeting: function() { return this; },
          defineSizeMapping: function() { return this; },
          setCollapseEmptyDiv: function() { return this; },
          getAdUnitPath: function() { return ''; },
          getSlotElementId: function() { return ''; },
          getTargeting: function() { return []; },
          getTargetingKeys: function() { return []; },
          clearTargeting: function() { return this; }
        };
        const fakePubAds = {
          enableSingleRequest: function() {},
          setTargeting: function() { return this; },
          collapseEmptyDivs: function() {},
          addEventListener: function() {},
          removeEventListener: function() {},
          getSlots: function() { return []; },
          refresh: function() {},
          disableInitialLoad: function() {},
          enableLazyLoad: function() {},
          setCentering: function() {},
          setPrivacySettings: function() {},
          clear: function() { return []; }
        };
        window.googletag = window.googletag || {};
        window.googletag.cmd = window.googletag.cmd || [];
        window.googletag.defineSlot = function() { return fakeSlot; };
        window.googletag.defineOutOfPageSlot = function() { return fakeSlot; };
        window.googletag.enableServices = function() {};
        window.googletag.display = function() {};
        window.googletag.destroySlots = function() { return true; };
        window.googletag.pubads = function() { return fakePubAds; };
        window.googletag.companionAds = function() { return { enableSyncLoading: function(){} }; };
        window.googletag.sizeMapping = function() {
          return { addSize: function() { return this; }, build: function() { return []; } };
        };
        // Drain the cmd queue silently
        try {
          const origCmd = window.googletag.cmd;
          window.googletag.cmd = {
            push: function(fn) { try { fn(); } catch(e) {} },
            slice: Array.prototype.slice.bind(origCmd || [])
          };
        } catch(e) {}

        // Block pbjs (Prebid.js)
        window.pbjs = window.pbjs || {};
        window.pbjs.que = window.pbjs.que || [];
        window.pbjs.que.push = function() {};
        window.pbjs.requestBids = function() {};
        window.pbjs.addAdUnits = function() {};
        window.pbjs.setConfig = function() {};

        // Block apstag (Amazon TAM)
        window.apstag = window.apstag || {};
        window.apstag.init = function() {};
        window.apstag.fetchBids = function(config, cb) { if (cb) cb([]); };
        window.apstag.setDisplayBids = function() {};

        // Block Taboola
        window._taboola = window._taboola || [];
        window._taboola.push = function() {};

        // Block Outbrain
        window.OBR = window.OBR || {};
        window.OBR.extern = window.OBR.extern || {};
        window.OBR.extern.renderCompleted = function() {};

        // Block Criteo
        window.Criteo = window.Criteo || {};
        window.Criteo.DisplayAcceptableAdIfAdblocked = function() {};
        window.Criteo.events = window.Criteo.events || { push: function() {} };
        window.criteo_q = window.criteo_q || [];
        window.criteo_q.push = function() {};

        // Neutralize Colombia (CLMB) / Times Internet ad stack
        window.clmb = window.clmb || {};
        window.clmb.init = function() {};
        window.clmb.load = function() {};
        window.clmb.push = function() {};
        window.colombia = window.colombia || {};
        window.colombia.init = function() {};
        window.colombia.load = function() {};
        window.colombia.render = function() {};
        window._clmb = window._clmb || [];
        window._clmb.push = function() {};
        window.TimesAd = window.TimesAd || {};
        window.tilMads = window.tilMads || {};

      } catch (e) {}

      // ════════════════════════════════════════════════════════
      // LAYER 2: Block Ad Script Injection via createElement
      // ════════════════════════════════════════════════════════
      try {
        const blockedDomains = [$blockedDomainsJs];
        const origCreateElement = document.createElement.bind(document);

        document.createElement = function(tag) {
          const el = origCreateElement(tag);
          const tagLower = (tag || '').toLowerCase();

          if (tagLower === 'script') {
            const srcDescriptor = Object.getOwnPropertyDescriptor(HTMLScriptElement.prototype, 'src');
            if (srcDescriptor && srcDescriptor.set) {
              Object.defineProperty(el, 'src', {
                set: function(val) {
                  const strVal = String(val || '');
                  if (blockedDomains.some(function(d) { return strVal.includes(d); })) {
                    console.log('[BREAKING PAD] ⛔ Blocked ad script: ' + strVal);
                    // Make script a no-op data URI instead
                    srcDescriptor.set.call(this, 'data:text/javascript,');
                    return;
                  }
                  srcDescriptor.set.call(this, val);
                },
                get: srcDescriptor.get,
                configurable: true
              });
            }
          }

          if (tagLower === 'iframe') {
            const srcDescriptor = Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'src');
            if (srcDescriptor && srcDescriptor.set) {
              Object.defineProperty(el, 'src', {
                set: function(val) {
                  const strVal = String(val || '');
                  if (blockedDomains.some(function(d) { return strVal.includes(d); })) {
                    console.log('[BREAKING PAD] ⛔ Blocked ad iframe: ' + strVal);
                    srcDescriptor.set.call(this, 'about:blank');
                    return;
                  }
                  srcDescriptor.set.call(this, val);
                },
                get: srcDescriptor.get,
                configurable: true
              });
            }
          }

          return el;
        };
      } catch(e) {}

      // ════════════════════════════════════════════════════════
      // LAYER 3: Block fetch() and XMLHttpRequest to ad servers
      // ════════════════════════════════════════════════════════
      try {
        const blockedDomains = [$blockedDomainsJs];

        function isBlockedUrl(url) {
          if (!url) return false;
          return blockedDomains.some(function(d) { return String(url).includes(d); });
        }

        // Block fetch
        const origFetch = window.fetch;
        if (origFetch) {
          window.fetch = function(input, init) {
            const url = typeof input === 'string' ? input : (input && input.url ? input.url : '');
            if (url.includes('spotify.com') && (url.includes('ad-logic') || url.includes('/ads/'))) {
              return Promise.resolve(new Response(JSON.stringify({
                ad_breaks: [],
                ads: [],
                in_ad_break: false
              }), {
                status: 200,
                headers: { 'Content-Type': 'application/json' }
              }));
            }
            if (isBlockedUrl(url)) {
              console.log('[BREAKING PAD] ⛔ Blocked fetch: ' + url);
              return Promise.resolve(new Response('', { status: 200 }));
            }
            return origFetch.apply(this, arguments);
          };
        }

        // Block XHR
        const origOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function(method, url) {
          if (isBlockedUrl(url)) {
            console.log('[BREAKING PAD] ⛔ Blocked XHR: ' + url);
            // Override send to be a no-op
            this.send = function() {
              Object.defineProperty(this, 'readyState', { get: function() { return 4; } });
              Object.defineProperty(this, 'status', { get: function() { return 200; } });
              Object.defineProperty(this, 'responseText', { get: function() { return ''; } });
            };
            return;
          }
          return origOpen.apply(this, arguments);
        };
      } catch(e) {}

      // ════════════════════════════════════════════════════════
      // LAYER 4: Popup & Redirect Guard
      // ════════════════════════════════════════════════════════
      ${enablePopupProtection ? '''
      try {
        const originalWindowOpen = window.open;
        window.open = function(url, target, features) {
          if (!url || url === 'about:blank') {
            return { closed: false, focus: function(){}, close: function(){}, location: { href: '' } };
          }
          const lowerUrl = String(url).toLowerCase();
          const adPatterns = [
            'popup', 'popunder', 'adclick', 'affiliate', 'tracking', 'redirect',
            'onclick', 'clickunder', 'clickthrough', 'exit', 'door', 'interstitial',
            'ad.php', '/ads/', 'adserver', 'adsystem', 'adservice', '/click?',
            'doubleclick.net', 'googlesyndication.com', 'exoclick.com', 'popads.net'
          ];
          if (adPatterns.some(function(p) { return lowerUrl.includes(p); })) {
            console.log('[BREAKING PAD] ⛔ Blocked popup: ' + url);
            return null;
          }
          return originalWindowOpen.apply(window, arguments);
        };
      } catch (e) {}

      // Block aggressive redirect via history API
      try {
        const origPushState = history.pushState;
        const origReplaceState = history.replaceState;
        const adNavPatterns = ['adclick', 'popunder', 'trackevent', '/ads/', 'adservice', 'adredirect'];
        function isAdNav(url) {
          if (!url) return false;
          const u = String(url).toLowerCase();
          return adNavPatterns.some(function(p) { return u.includes(p); });
        }
        history.pushState = function(state, title, url) {
          if (isAdNav(url)) return;
          return origPushState.apply(this, arguments);
        };
        history.replaceState = function(state, title, url) {
          if (isAdNav(url)) return;
          return origReplaceState.apply(this, arguments);
        };
      } catch(e) {}

      // Block document.write for ad injection
      try {
        const origDocWrite = document.write.bind(document);
        document.write = function(html) {
          const h = String(html || '').toLowerCase();
          if (h.includes('doubleclick') || h.includes('googlesyndication') ||
              h.includes('adsbygoogle') || h.includes('googletag') ||
              h.includes('pagead') || h.includes('adnxs') || h.includes('taboola')) {
            console.log('[BREAKING PAD] ⛔ Blocked document.write ad injection');
            return;
          }
          return origDocWrite(html);
        };
      } catch(e) {}
      ''' : ''}

      // ════════════════════════════════════════════════════════
      // LAYER 5: YouTube Ad Mitigation + Mini Player
      // ════════════════════════════════════════════════════════
      ${enableYouTubeMitigation ? '''
      try {
        const isYouTube = location.hostname.includes('youtube.com') || location.hostname.includes('youtu.be');
        if (isYouTube) {

          // --- 5a. Strip ad data from YouTube API responses ---
          const AD_KEYS = [
            'playerAds', 'adPlacements', 'adSlots', 'adBreakHeartbeatParams',
            'adSafetyReason', 'adMessagingConfig', 'auxiliaryUi',
            'autoplayVideoRenderer', 'adBreaks', 'adParams',
            'inVideoSurveyRenderer', 'companionSlot', 'activeView',
            'companionAdRenderer', 'promotedSparklesRenderer',
            'promotedVideoRenderer', 'statementBannerRenderer',
          ];

          function cleanYouTubeData(obj) {
            if (!obj || typeof obj !== 'object') return obj;
            for (const key of AD_KEYS) {
              if (key in obj) delete obj[key];
            }
            for (const k in obj) {
              if (Object.prototype.hasOwnProperty.call(obj, k) && typeof obj[k] === 'object') {
                cleanYouTubeData(obj[k]);
              }
            }
            return obj;
          }

          // Hook JSON.parse
          const origJSONParse = JSON.parse;
          JSON.parse = function(text, reviver) {
            const result = origJSONParse.apply(this, arguments);
            if (result && typeof result === 'object') {
              const hasAds = AD_KEYS.some(function(k) { return k in result; });
              if (hasAds) return cleanYouTubeData(result);
            }
            return result;
          };

          // Hook fetch for YouTube player endpoint
          const origFetch = window.fetch;
          if (origFetch) {
            window.fetch = async function(input, init) {
              const url = typeof input === 'string' ? input : (input && input.url ? input.url : '');
              const response = await origFetch.apply(this, arguments);
              if (url && (
                url.includes('/youtubei/v1/player') ||
                url.includes('/youtubei/v1/next') ||
                url.includes('/youtubei/v1/browse')
              )) {
                try {
                  const clone = response.clone();
                  const json = await clone.json();
                  const cleaned = cleanYouTubeData(json);
                  return new Response(JSON.stringify(cleaned), {
                    status: response.status,
                    statusText: response.statusText,
                    headers: response.headers
                  });
                } catch (e) { return response; }
              }
              return response;
            };
          }

          // --- 5b. Auto-skip ads every 150ms ---
          setInterval(function() {
            try {
              const video = document.querySelector('video');
              const adShowing = document.querySelector(
                '.ad-showing, .ytp-ad-player-overlay, ytd-ad-slot-renderer, .ytp-ad-module, [class*="ad-showing"]'
              );

              if (adShowing && video) {
                // Mute and speed through ad
                if (!video.muted) video.muted = true;
                if (video.playbackRate < 16) video.playbackRate = 16;
                // If short ad, seek to end
                if (isFinite(video.duration) && video.duration > 0 && video.duration < 120) {
                  video.currentTime = video.duration - 0.1;
                }
              } else if (video && video.muted && video.playbackRate >= 16) {
                // Restore normal playback when ad ends
                video.muted = false;
                video.playbackRate = 1.0;
              }

              // Auto-click ALL skip buttons
              const skipSelectors = [
                '.ytp-ad-skip-button','.ytp-skip-ad-button',
                '.ytp-ad-skip-button-modern','.ytm-skip-ad-button',
                '[class*="skip-button"]','button[id*="skip"]',
                '.videoAdUiSkipButton','.ytp-ad-overlay-close-button'
              ];
              for (const sel of skipSelectors) {
                const btns = document.querySelectorAll(sel);
                for (const btn of btns) {
                  if (btn && btn.offsetParent !== null) {
                    btn.click();
                  }
                }
              }

              // Hide all ad overlay elements
              const adEls = document.querySelectorAll(
                '.ytp-ad-module, .ytp-ad-overlay-container, .ytp-ad-player-overlay, ' +
                '.ytp-ad-text, .ytp-ad-preview-container, #player-ads, ' +
                'ytd-ad-slot-renderer, ytm-promoted-sparkles-web-renderer, ' +
                'ytm-companion-ad-renderer, ytm-statement-banner-renderer, ' +
                'ytd-promoted-video-renderer, ytd-in-feed-ad-layout-renderer'
              );
              for (const el of adEls) {
                el.style.setProperty('display', 'none', 'important');
              }
            } catch(e) {}
          }, 150);

          // --- 5c. Mini Control Overlay (floating one-tap controls) ---
          function injectYouTubeMiniControls() {
            if (document.getElementById('__bp_mini_controls')) return;
            const overlay = document.createElement('div');
            overlay.id = '__bp_mini_controls';
            overlay.style.cssText = `
              position: fixed;
              bottom: 72px;
              right: 12px;
              z-index: 2147483647;
              display: flex;
              flex-direction: column;
              gap: 8px;
              align-items: center;
            `;

            function makeBtn(label, emoji, action) {
              const btn = document.createElement('button');
              btn.title = label;
              btn.textContent = emoji;
              btn.style.cssText = `
                width: 44px;
                height: 44px;
                border-radius: 50%;
                background: #000000;
                border: 1.5px solid #FFFFFF;
                color: #FFFFFF;
                font-size: 18px;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                box-shadow: 0 2px 12px rgba(0,0,0,0.5);
                transition: transform 0.1s;
              `;
              btn.addEventListener('click', action);
              btn.addEventListener('mousedown', function() { btn.style.transform = 'scale(0.9)'; });
              btn.addEventListener('mouseup', function() { btn.style.transform = 'scale(1)'; });
              return btn;
            }

            function getVideo() { return document.querySelector('video'); }

            const skipAd = makeBtn('Skip Ad', '⚡', function() {
              const v = getVideo();
              const adEl = document.querySelector('.ad-showing, .ytp-ad-player-overlay');
              if (adEl && v && isFinite(v.duration) && v.duration > 0) {
                v.currentTime = v.duration;
                v.muted = false;
                v.playbackRate = 1.0;
              }
              document.querySelectorAll('.ytp-ad-skip-button, .ytp-skip-ad-button, .ytp-ad-skip-button-modern')
                .forEach(function(b) { b.click(); });
            });

            const skipFwd = makeBtn('Forward 10s', '⏩', function() {
              const v = getVideo();
              if (v) v.currentTime = Math.min(v.duration || 0, v.currentTime + 10);
            });

            const playPause = makeBtn('Play / Pause', '⏯', function() {
              const v = getVideo();
              if (v) { if (v.paused) v.play(); else v.pause(); }
            });

            const skipBack = makeBtn('Back 10s', '⏪', function() {
              const v = getVideo();
              if (v) v.currentTime = Math.max(0, v.currentTime - 10);
            });

            const muteBtn = makeBtn('Mute', '🔇', function() {
              const v = getVideo();
              if (v) {
                v.muted = !v.muted;
                muteBtn.textContent = v.muted ? '🔇' : '🔊';
              }
            });

            overlay.appendChild(skipAd);
            overlay.appendChild(skipFwd);
            overlay.appendChild(playPause);
            overlay.appendChild(skipBack);
            overlay.appendChild(muteBtn);
            document.body.appendChild(overlay);
          }

          if (document.body) {
            injectYouTubeMiniControls();
          } else {
            document.addEventListener('DOMContentLoaded', injectYouTubeMiniControls);
          }
        }
      } catch(e) {}
      ''' : ''}

      // ════════════════════════════════════════════════════════
      // LAYER 6: Spotify Web Player & Anti-Adblock Evasion
      // ════════════════════════════════════════════════════════
      try {
        const isSpotify = location.hostname.includes('spotify.com');
        if (isSpotify) {
          // 6a. Spoof Desktop Environment so Spotify doesn't show "Playback disabled" on mobile
          try {
            const desktopUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
            Object.defineProperty(navigator, 'userAgent', { get: function() { return desktopUA; }, configurable: true });
            Object.defineProperty(navigator, 'appVersion', { get: function() { return '5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'; }, configurable: true });
            Object.defineProperty(navigator, 'platform', { get: function() { return 'Win32'; }, configurable: true });
            if (navigator.userAgentData) {
              Object.defineProperty(navigator.userAgentData, 'mobile', { get: function() { return false; }, configurable: true });
              Object.defineProperty(navigator.userAgentData, 'platform', { get: function() { return 'Windows'; }, configurable: true });
            }
          } catch(e) {}

          // 6b. Bypass Anti-Adblock Detection on Spotify
          try {
            window.__hasAdBlocker = false;
            window.isAdBlocked = false;
          } catch(e) {}

          // 6c. Auto-Skip Spotify Audio Ads (Instant 0.05s skip & mute)
          setInterval(function() {
            try {
              const audio = document.querySelector('audio');
              const nowPlaying = document.querySelector('[data-testid="now-playing-widget"]');
              const adLabel = document.querySelector('[data-testid="track-info-advertiser"], [aria-label*="Advertisement"]');
              const isAdPlaying = adLabel !== null || (nowPlaying && nowPlaying.textContent.toLowerCase().includes('advertisement'));

              if (isAdPlaying && audio) {
                audio.muted = true;
                if (isFinite(audio.duration) && audio.duration > 0) {
                  audio.currentTime = audio.duration;
                }
                const skipBtn = document.querySelector('[data-testid="control-button-skip-forward"]');
                if (skipBtn && !skipBtn.disabled) {
                  skipBtn.click();
                }
              } else if (audio && audio.muted && !isAdPlaying) {
                audio.muted = false;
              }
            } catch(e) {}
          }, 200);
        }
      } catch(e) {}

    })();
    ''';
  }
}
