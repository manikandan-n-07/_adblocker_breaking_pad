class AdGuardFilterRules {
  // ══════════════════════════════════════════════════════════════════
  // AD NETWORKS — 200+ domains (EasyList + AdGuard Base + Peter Lowe)
  // ══════════════════════════════════════════════════════════════════
  static const Set<String> defaultAdDomains = {
    // Google Ad Infrastructure
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'adservice.google.com', 'adservice.google.co.in', 'adservice.google.com.au',
    'pagead2.googlesyndication.com', 'tpc.googlesyndication.com',
    'ade.googlesyndication.com', 'partner.googleadservices.com',
    'www.googleadservices.com',

    // AppNexus / Xandr
    'adnxs.com', 'adnxs-simple.com', 'appnexus.com',

    // Programmatic / RTB networks
    'taboola.com', 'trc.taboola.com', 'cdn.taboola.com', 'nr-data.taboola.com',
    'outbrain.com', 'outbrainimg.com', 'ob-cdn.com',
    'criteo.com', 'static.criteo.net', 'dis.us.criteo.com', 'rtax.criteo.com',
    'pubmatic.com', 'ads.pubmatic.com', 'image6.pubmatic.com',
    'rubiconproject.com', 'eus.rubiconproject.com', 'fastlane.rubiconproject.com',
    'openx.net', 'servedby.openx.net', 'us-u.openx.net',
    'smartadserver.com', 'ced.sascdn.com', 'diff.smartadserver.com',
    'casalemedia.com', 'ssum.casalemedia.com',
    'contextweb.com', 'bh.contextweb.com', 'ib.adnxs.com',
    'bidswitch.net', 'x.bidswitch.net',
    'sharethrough.com', 'native.sharethrough.com',
    'triplelift.com', 'tlx.3lift.com',
    'sovrn.com', 'lijit.com', 'ap.lijit.com',
    'sonobi.com', 'apex.go.sonobi.com',
    'yieldmo.com', 'ads.yieldmo.com',
    'spotxchange.com', 'spotx.tv', 'cdn.spotx.tv',
    'tremorhub.com', 'eb2.3lift.com',
    'gumgum.com', 'g2.gumgum.com',
    'exponential.com', 'exponentialinteractive.com',
    'conversantmedia.com', 'dtm.conversantmedia.com',
    'yieldlove.com', 'ad.yieldlove.com',
    'revjet.com', 'flashtalking.com',
    'adblade.com', 'adbladetech.com',
    'media.net', 'serving.syndication.ms', 'adtng.com',

    // Mobile / In-app ad networks
    'adcolony.com', 'adcolony.net',
    'applovin.com', 'a.applovin.com', 'rt.applovin.com',
    'unity3d.com', 'unityads.unity3d.com', 'config.unityads.unity3d.com',
    'vungle.com', 'ads.api.vungle.com',
    'chartboost.com', 'live.chartboost.com',
    'inmobi.com', 'cf.hb.apstag.com', 'ad.inmobi.com',
    'ironsrc.com', 'outcome.ironsrc.com', 'mediation.ironsrc.com',
    'mopub.com', 'ads.mopub.com',
    'millennial-media.com', 'ads.millennialmedia.com',
    'mobvista.com', 'server-eu.heliummob.com',
    'smaato.net', 'soma.smaato.net',
    'madvertise.de', 'ad.madvertise.de',
    'startapp.com', 'ad3.startapp.com',
    'tapjoy.com', 'ads.tapjoy.com',
    'flurry.com', 'ads.flurry.com',

    // Pop-up / Pop-under / Annoying
    'popads.net', 'popcash.net', 'popunder.net',
    'propellerads.com', 'adcash.com', 'exoclick.com',
    'trafficjunky.com', 'trafficfactory.biz',
    'juicyads.com', 'clickadu.com', 'adsterra.com',
    'hilltopads.net', 'activerevenue.com', 'adskeeper.co.uk',
    'adspyglass.com', 'ero-advertising.com', 'plugrush.com',
    'adxpansion.com', 'tsyndicate.com',

    // Native / Content recommendation
    'mgid.com', 'revcontent.com', 'zergnet.com',
    'content.ad', 'adscale.de', 'nativeads.com',
    'contentabc.com', 'postrelease.com', 'nativo.com',
    'shareaholic.com', 'adpushup.com', 'adpushup.net',
    'marfeel.com', 'infolinks.com', 'vertoz.com',

    // Ad tech / SSPs / DSPs
    'advertising.com', 'adtechus.com', 'aol.com',
    'amazon-adsystem.com', 'ams3.ads.amazon.com', 'fls-na.amazon-adsystem.com',
    'moatads.com', 'moat.com', 'd3nfwcxd527z59.cloudfront.net',
    'serving-sys.com', 'bs.serving-sys.com',
    'adsrvr.org', 'match.adsrvr.org',
    'adroll.com', 'd.adroll.com',
    'mookie1.com', 'ib.mookie1.com',
    'quantcount.com', 'pixel.quantserve.com',
    'bluekai.com', 'tags.bluekai.com',
    'krxd.net', 'beacon.krxd.net',
    'adform.net', 'track.adform.net',
    'emxdgt.com', 'hbopenbid.pubmatic.com',
    'rfihub.com', 'rfihub.net',
    'yldbt.com', 'cdn.yldbt.com',
    'smartclip.net', 'ads.smartclip.net',
    'ad6media.fr', 'smartstream.tv',
    'undertone.com', 'ads.undertone.com',
    'synchrobox.adnxs.com',
    'thetradedesk.com', 'match.thetradedesk.com',
    'adkernel.com', 'ad.adkernel.com',
    'adhigh.net', 'optimatic.com',
    'adincube.com', 'vidoomy.com',
    'bidtheatre.com', 'stickyadstv.com',
    'freewheel.tv', 'adsfac.eu',
    'lotame.com', 'ad.360yield.com',

    // Indian / South Asian ad networks (Times of India, Hindustan Times etc.)
    'ad.adfactor.co.in', 'ads.indiatimes.com',
    'ad.timesinternet.in', 'toi.ad',
    'cbsiadservices.indiatimes.com', 'ad.network.indiatimes.com',
    'gameloft.com', 'ad.gameloft.com',
    'ad.global.ymcdn.com',
    'rediffmail.com', 'ad.rediff.com',
    'komli.com', 'ad.komli.com',
    'vdopia.com', 'mads.amazon.in',

    // Video / Pre-roll ads
    'imasdk.googleapis.com', 'yt3.ggpht.com',
    'ad.youtube.com', 'static.ads-twitter.com',
    'ads.twitter.com', 'ads.linkedin.com',
    'ads.facebook.com', 'an.facebook.com',
    'connect.facebook.net',  // FB pixel + ads SDK

    // Misc ad servers
    'an.yandex.ru',
    'yadro.ru', 'bs.yandex.ru',
    'mail.ru', 'top.mail.ru',
    'ads.vk.com', 'targetix.net',
    'hotlog.ru', 'begun.ru',
    'imrworldwide.com', 'secure-ds.imrworldwide.com',
    'adsymptotic.com', 'syndicatedsearch.goog',
    'adnz.co', 'adspirit.de',
    'specificclick.net', 'adsafeprotected.com',
    'adback.co', 'betweendigital.com',
    'appier.com',
    'union.baidu.com', 'cpro.baidu.com',
    'yboss.yahooapis.com',
  };

  // ══════════════════════════════════════════════════════════════════
  // TRACKERS & ANALYTICS — 80+ domains
  // ══════════════════════════════════════════════════════════════════
  static const Set<String> defaultTrackerDomains = {
    // Google tracking
    'google-analytics.com', 'googletagmanager.com', 'googletagservices.com',
    'ssl.google-analytics.com', 'www.google-analytics.com',
    'analytics.google.com', 'stats.g.doubleclick.net',

    // Web analytics
    'hotjar.com', 'static.hotjar.com', 'script.hotjar.com',
    'segment.io', 'segment.com', 'cdn.segment.com',
    'quantserve.com', 'chartbeat.com', 'beacon.chartbeat.com',
    'mixpanel.com', 'api.mixpanel.com', 'cdn.mxpnl.com',
    'amplitude.com', 'api.amplitude.com', 'cdn.amplitude.com',
    'fullstory.com', 'rs.fullstory.com', 'edge.fullstory.com',
    'mouseflow.com', 'a.mouseflow.com', 'cdn.mouseflow.com',
    'crazyegg.com', 'script.crazyegg.com', 'dnn506yrbagrg.cloudfront.net',
    'clicky.com', 'in.getclicky.com', 'static.getclicky.com',
    'statcounter.com', 'secure.statcounter.com',
    'newrelic.com', 'bam.nr-data.net', 'js-agent.newrelic.com',
    'nr-data.net', 'beacon.nr-data.net',
    'inspectlet.com', 'luckyorange.com', 'heapanalytics.com',
    'pingdom.net', 'rum-collector.pingdom.net',
    'loggly.com', 'logs.loggly.com',

    // A/B testing
    'optimizely.com', 'cdn.optimizely.com', 'api.optimizely.com',
    'conductrics.com', 'vwo.com', 'dev.visualwebsiteoptimizer.com',
    'abtasty.com', 'cdn.abtasty.com',
    'convert.com', 'cdn.convert.com',

    // Mobile attribution / tracking
    'branch.io', 'api2.branch.io', 'cdn.branch.io',
    'appsflyer.com', 't.appsflyer.com', 'impression.appsflyer.com',
    'adjust.com', 'app.adjust.com', 'view.adjust.com',
    'kochava.com', 'control.kochava.com',
    'singular.net', 'sdk.singular.net',
    'tune.com', 'tlnk.io',
    'mparticle.com', 'nativex.com',
    'tenjin.io', 'api.tenjin.io',
    'firebase.com', 'app-measurement.com', 'firebaseapp.com',

    // Heatmap / session recording
    'clarity.ms', 'clarity.microsoft.com',
    'bat.bing.com', 'c.clarity.ms',

    // Social trackers
    'facebook.com', 'connect.facebook.net', 'tr.snapchat.com',
    'sc-static.net', 'static.ads-twitter.com', 'analytics.twitter.com',
    'tiktok.com', 'analytics.tiktok.com', 'business.tiktok.com',
    'linkedin.com', 'snap.com', 'pinterest.com',
    'ct.pinterest.com', 'trk.pinterest.com',

    // Misc
    'yandex.ru', 'mc.yandex.ru', 'metrika.yandex.ru',
    'mail.ru', 'top.mail.ru', 'counter.yadro.ru',
    'openstat.net', 'liveinternet.ru',
    'scorecardresearch.com', 'beacon.scorecardresearch.com',
    'comscore.com', 'sb.scorecardresearch.com',
    'iesnare.com', 'mpsnare.iesnare.com',
    'decibelinsight.net', 'rum.decibelinsight.net',
    'parsely.com', 'api.parsely.com', 'pixel.parsely.com',
    'chartbeat.net',
    'datadoghq.com', 'browser-intake-datadoghq.com',
    'sentry.io', 'browser.sentry-cdn.com',
    'bugsnag.com', 'notify.bugsnag.com',
    'raygun.io', 'api.raygun.io',
  };

  // ══════════════════════════════════════════════════════════════════
  // YOUTUBE AD ENDPOINTS
  // ══════════════════════════════════════════════════════════════════
  static const List<String> defaultYouTubeAdPatterns = [
    'youtube.com/pagead/',
    'youtube.com/ptracking',
    'youtube.com/api/stats/ads',
    'youtube.com/api/stats/atr',
    'youtube.com/get_midroll_info',
    'youtube.com/youtubei/v1/player/ad_break',
    'youtube.com/api/stats/playback?*ad*',
    'googlevideo.com/videoplayback?*adformat*',
    'googlevideo.com/videoplayback?*ctier=A*',
    'googlevideo.com/videoplayback?*oad*',
    'imasdk.googleapis.com/js/sdkloader/ima3*',
    'imasdk.googleapis.com/js/sdkloader/ima3_dai*',
    'static.doubleclick.net/instream/ad_status.js',
    'googleads.g.doubleclick.net/*',
    'ad.youtube.com/*',
    'youtube.com/api/stats/delayplay*ad*',
  ];

  // ══════════════════════════════════════════════════════════════════
  // AD URL PATH PATTERNS
  // ══════════════════════════════════════════════════════════════════
  static const List<String> defaultAdUrlPatterns = [
    '/pagead/',
    '/adservice/',
    '/ads/banners/',
    '/adclick.',
    '/adserver.',
    '/wp-content/ads/',
    '/adsystem/',
    '/ad-unit/',
    '/adzone/',
    '/adsense/',
    '/adframe/',
    '/adscript/',
    '/adloader/',
    '/adtech/',
    '/native-ad/',
    '/sponsored/',
    '/promo-banner/',
    '/ad_iframe/',
    '/track.php?',
    '/click.php?',
    '/banner.php?',
    '/adtrk.',
    '/imp.php?',
    '/pixel.gif',
    '/pixel.png',
    '/beacon.gif',
    '/imp?s=',
    '/ad.php?',
  ];

  // ══════════════════════════════════════════════════════════════════
  // TRACKER URL PATH PATTERNS
  // ══════════════════════════════════════════════════════════════════
  static const List<String> defaultTrackerUrlPatterns = [
    '/analytics.js',
    '/analytics.min.js',
    '/gtm.js',
    '/gtag.js',
    '/fbevents.js',
    '/pixel.gif',
    '/telemetry/',
    '/beacon.js',
    '/hotjar-',
    '/segment.min.js',
    '/amplitude.js',
    '/mxpanel.js',
    '/fullstory.js',
    '/clarity.js',
    '/ping?',
    '/collect?',
    '/event?',
    '/track?',
    '/log?type=',
    '/stats?',
  ];

  // ══════════════════════════════════════════════════════════════════
  // POPUP / ANNOYANCE DOMAINS
  // ══════════════════════════════════════════════════════════════════
  static const Set<String> defaultPopupDomains = {
    'onclickads.net', 'adclick.g.doubleclick.net',
    'syndication.exoclick.com', 'serve.popads.net',
    'directrev.com', 'popunder.net', 'adspirit.de',
    'clkmon.com', 'clkrevenue.com', 'ero-advertising.com',
    'cpax.com', 'clickaine.com', 'go2jump.org',
    'adwebmaster.net', 'adsafeprotected.com',
    'traffic-media.co', 'adsupply.com', 'exdynsrv.com',
    'clksite.com', 'newbidder.com', 'adxpansion.com',
    'clicksor.net', 'clicksor.com', 'tsyndicate.com',
  };

  /// Safely checks if [host] matches or is a subdomain of any target in [domains]
  static bool matchesDomain(String host, Iterable<String> domains) {
    if (host.isEmpty) return false;
    final lowerHost = host.toLowerCase();
    for (final domain in domains) {
      final lowerDomain = domain.toLowerCase();
      if (lowerHost == lowerDomain || lowerHost.endsWith('.$lowerDomain')) {
        return true;
      }
    }
    return false;
  }

  /// Converts a wildcard string into a RegExp (unanchored substring match)
  static RegExp wildcardToRegex(String pattern) {
    final escaped = RegExp.escape(pattern).replaceAll(r'\*', '.*');
    return RegExp(escaped, caseSensitive: false);
  }
}
